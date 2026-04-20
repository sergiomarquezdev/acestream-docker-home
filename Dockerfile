# Use the official Ubuntu 22.04 LTS (Jammy Jellyfish) base image
FROM ubuntu:22.04

# Image metadata
LABEL maintainer="sergiomarquezdev" \
      description="Acestream Engine containerized for easy deployment" \
      version="3.2.11"

# Define environment variables for encoding and app configuration
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV INTERNAL_IP="127.0.0.1"
ENV HTTP_PORT="6878"
ENV HTTPS_PORT="6879"

# Install runtime dependencies, compile native Python modules, then purge the
# build toolchain in the same layer so it never ships in the final image.
# libxml2 / libxslt1.1 / libsqlite3-0 are reinstalled explicitly because
# apt-get purge --auto-remove would otherwise drop them as unused dev-deps.
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Basic runtime tools
    wget procps \
    # Python environment
    python3 libpython3.10 python3-pip python3-setuptools python3-wheel \
    python3-greenlet python3-gevent python3-psutil python3-simplejson \
    # Build toolchain (removed after pip install)
    build-essential python3-dev libsqlite3-dev libxml2-dev libxslt1-dev \
 && pip install --no-cache-dir \
    # Python modules required by Acestream (pinned for reproducible builds)
    apsw==3.46.0.0 \
    lxml==5.2.2 \
    PyNaCl==1.5.0 \
    requests==2.32.3 \
    pycryptodome==3.20.0 \
    isodate==0.6.1 \
 && apt-get purge -y --auto-remove \
    build-essential python3-dev libsqlite3-dev libxml2-dev libxslt1-dev \
 && apt-get install -y --no-install-recommends \
    libxml2 libxslt1.1 libsqlite3-0 \
 && rm -rf /var/lib/apt/lists/*

# Copy the entrypoint script and grant execute permissions.
# LF line endings are guaranteed by .gitattributes (*.sh eol=lf).
COPY config/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Copy Acestream archive, verify SHA256 integrity, then extract in one layer.
# Override at build time with --build-arg ACESTREAM_SHA256=<hash> if the tarball is updated.
ARG ACESTREAM_SHA256=9b6bbd76a55e5a434641afae3b9cf8e6154ce1cf392152ec3aed5ac265432b2e
COPY resources/acestream.tar.gz /tmp/acestream.tar.gz
RUN echo "${ACESTREAM_SHA256}  /tmp/acestream.tar.gz" | sha256sum --check \
    && mkdir -p /opt/acestream \
    && tar --extract --gzip --directory /opt/acestream --file /tmp/acestream.tar.gz \
    && rm /tmp/acestream.tar.gz

# Overwrite the default web player with the custom version
COPY web/player.html /opt/acestream/data/webui/html/player.html

# Copy the Acestream configuration file
COPY config/acestream.conf /opt/acestream/acestream.conf

# Expose the default Acestream port
EXPOSE 6878

# Health check: Verify Acestream engine is responding
# Checks every 30s with 3 retries before marking as unhealthy
# Allows 40s startup time before first check
HEALTHCHECK --interval=30s --timeout=10s --retries=3 --start-period=40s \
    CMD python3 -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:${HTTP_PORT}/webui/api/service?method=get_version', timeout=5)" || exit 1

# Entrypoint for the container
ENTRYPOINT ["/entrypoint.sh"]
