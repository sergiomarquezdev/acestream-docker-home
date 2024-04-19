# Set the base image.
FROM ubuntu:bionic

# Define arguments for the Acestream version and its SHA256 hash.
ARG ACESTREAM_VERSION=3.1.75rc4_ubuntu_18.04_x86_64_py3.8
ARG ACESTREAM_SHA256=6D4947DFFAD58754A6DE725D49F8F9A574931C13C293EB4C9C3F324E93BA8356

ENV INTERNAL_IP=127.0.0.1
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# Copy the requirements.txt file into the build context.
# Make sure you have a valid requirements.txt in your build context.
COPY requirements.txt /requirements.txt

# Install system packages and clean up in a single layer to keep the size to a minimum.
RUN set -ex && \
    apt-get update && \
    apt-get install -yq --no-install-recommends \
        ca-certificates \
        python3.8 \
        python3.8-distutils \
        net-tools \
        libpython3.8 \
        wget \
        libsqlite3-dev \
        build-essential \
        libxml2-dev \
        libxslt1-dev && \
    wget https://bootstrap.pypa.io/get-pip.py && \
    python3.8 get-pip.py && \
    pip install --no-cache-dir -r /requirements.txt && \
    pip install lxml apsw PyNaCl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/* /tmp/* /var/tmp/* && \
    rm /requirements.txt get-pip.py

# Install Acestream.
RUN mkdir -p /opt/acestream && \
    wget --no-verbose --output-document acestream.tgz "https://download.acestream.media/linux/acestream_${ACESTREAM_VERSION}.tar.gz" && \
    echo "${ACESTREAM_SHA256} acestream.tgz" | sha256sum --check && \
    tar --extract --gzip --directory /opt/acestream --file acestream.tgz && \
    rm acestream.tgz && \
    /opt/acestream/start-engine --version

# Overwrite the Ace Stream web player.
COPY web/player.html /opt/acestream/data/webui/html/player.html

# Copy Acestream configuration.
COPY config/acestream.conf /opt/acestream/acestream.conf

# Entry point for the container.
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

# Expose necessary ports.
EXPOSE 6878
EXPOSE 8621
