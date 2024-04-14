# Set the base image.
FROM ubuntu:bionic

# Define arguments for the Acestream version and its SHA256 hash.
ARG ACESTREAM_VERSION=3.1.74_ubuntu_18.04_x86_64
ARG ACESTREAM_SHA256=87db34c1aedc55649a8f8f5f4b6794581510701fc7ffbd47aaec0e9a2de2b219

ENV INTERNAL_IP=127.0.0.1

# Copy the requirements.txt file into the build context.
# Make sure you have a valid requirements.txt in your build context.
COPY requirements.txt /requirements.txt

# Install system packages and clean up in a single layer to keep the size to a minimum.
RUN set -ex && \
    apt-get update && \
    apt-get install -yq --no-install-recommends \
        ca-certificates \
        python2.7 \
        libpython2.7 \
        net-tools \
        python-setuptools \
        python-m2crypto \
        python-apsw \
        python-lxml \
        wget \
        python-pip \
        build-essential && \
    pip install --no-cache-dir -r /requirements.txt && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/* /tmp/* /var/tmp/* && \
    rm /requirements.txt

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
