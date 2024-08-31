# Set the base image.
FROM ubuntu:22.04

# Define arguments for the Acestream version and its SHA256 hash.
ARG ACESTREAM_VERSION=https://download.acestream.media/linux/acestream_3.2.3_ubuntu_22.04_x86_64_py3.10.tar.gz
ARG ACESTREAM_SHA256=ad11060410c64f04c8412d7dc99272322f7a24e45417d4ef2644b26c64ae97c9

ENV INTERNAL_IP=127.0.0.1
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# Copy the requirements.txt file into the build context.
COPY config/requirements.txt /requirements.txt

# Install system packages and clean up in a single layer to keep the size to a minimum.
RUN set -ex && \
    apt-get update && \
    apt-get install -yq --no-install-recommends \
        ca-certificates \
        python3.10 \
        python3.10-distutils \
        net-tools \
        libpython3.10 \
        wget \
        libsqlite3-dev \
        build-essential \
        libxml2-dev \
        libxslt1-dev && \
    wget https://bootstrap.pypa.io/get-pip.py && \
    python3.10 get-pip.py && \
    pip install --no-cache-dir -r /requirements.txt && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/* /tmp/* /var/tmp/* && \
    rm /requirements.txt get-pip.py

# Install Acestream from URL.
#RUN mkdir -p /opt/acestream && \
#    wget --no-verbose --output-document acestream.tgz "${ACESTREAM_VERSION}" && \
#    echo "${ACESTREAM_SHA256} acestream.tgz" | sha256sum --check && \
#    tar --extract --gzip --directory /opt/acestream --file acestream.tgz && \
#    rm acestream.tgz \

# Install Acestream from file. Actual (ACESTREAM_VERSION = acestream_3.2.3_ubuntu_22.04_x86_64_py3.10.tar.gz)
COPY resources/acestream.tar.gz /opt/acestream/
RUN tar --extract --gzip --directory /opt/acestream --file /opt/acestream/acestream.tar.gz && \
    rm /opt/acestream/acestream.tar.gz

# Overwrite the Ace Stream web player.
COPY web/player.html /opt/acestream/data/webui/html/player.html

# Copy Acestream configuration.
COPY config/acestream.conf /opt/acestream/acestream.conf

# Entry point for the container.
COPY config/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
