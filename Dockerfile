# ============================================================
# Stage 1: Builder — compiles native Python modules
# ============================================================
FROM ubuntu:22.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    python3-dev \
    libsqlite3-dev \
    libxml2-dev \
    libxslt1-dev \
    python3-pip \
    python3-wheel \
 && pip install --no-cache-dir --prefix=/install \
    apsw==3.46.0.0 \
    lxml==5.2.2 \
    PyNaCl==1.6.2 \
    requests==2.34.2 \
    pycryptodome==3.20.0 \
    isodate==0.6.1 \
 && rm -rf /var/lib/apt/lists/*

# ============================================================
# Stage 2: Runtime — minimal image with only runtime deps
# ============================================================
FROM ubuntu:22.04

LABEL maintainer="sergiomarquezdev" \
      description="Acestream Engine containerized for easy deployment" \
      version="3.2.11"

ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV HTTP_PORT="6878"
ENV HTTPS_PORT="6879"

# Install ONLY runtime packages.
# Python stays at 3.10 (ubuntu:22.04): the engine bundles cp310-only wheels.
# tini runs as PID 1: the engine ignores SIGTERM when it is PID 1 itself,
# so `docker stop` would otherwise always wait for the timeout and SIGKILL.
RUN apt-get update && apt-get install -y --no-install-recommends \
    procps tini \
    python3 libpython3.10 \
    python3-greenlet python3-gevent python3-psutil python3-simplejson \
    libxml2 libxslt1.1 libsqlite3-0 \
 && rm -rf /var/lib/apt/lists/*

# Copy compiled Python packages from builder stage
# Ubuntu's pip installs to /prefix/local/lib/python3.10/dist-packages
COPY --from=builder /install/local/lib/python3.10/dist-packages /usr/local/lib/python3.10/dist-packages

# Copy entrypoint (LF guaranteed by .gitattributes)
COPY config/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Verify and extract Acestream tarball.
# Bind-mounted instead of COPY'd so the archive never lands in an image layer.
ARG ACESTREAM_SHA256=9b6bbd76a55e5a434641afae3b9cf8e6154ce1cf392152ec3aed5ac265432b2e
RUN --mount=type=bind,source=resources/acestream.tar.gz,target=/tmp/acestream.tar.gz \
    echo "${ACESTREAM_SHA256}  /tmp/acestream.tar.gz" | sha256sum --check \
    && mkdir -p /opt/acestream \
    && tar --extract --gzip --directory /opt/acestream --file /tmp/acestream.tar.gz

# Overlay custom player and config
COPY web/player.html /opt/acestream/data/webui/html/player.html
COPY config/acestream.conf /opt/acestream/acestream.conf

EXPOSE 6878

HEALTHCHECK --interval=30s --timeout=10s --retries=3 --start-period=40s \
    CMD python3 -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:${HTTP_PORT}/webui/api/service?method=get_version', timeout=5)" || exit 1

# -g forwards signals to the whole process group: start-engine is a sh
# wrapper that does not exec, so the engine is a grandchild of tini.
ENTRYPOINT ["/usr/bin/tini", "-g", "--", "/entrypoint.sh"]
