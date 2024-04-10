# Establecer la sintaxis experimental de Docker
# Esto es necesario para usar características experimentales
FROM ubuntu:bionic

# Definir argumentos para la versión de Acestream y su hash SHA256
ARG ACESTREAM_VERSION=3.1.74_ubuntu_18.04_x86_64
ARG ACESTREAM_SHA256=87db34c1aedc55649a8f8f5f4b6794581510701fc7ffbd47aaec0e9a2de2b219
ENV INTERNAL_IP=127.0.0.1

# Copiar el archivo requirements.txt al contexto de construcción
COPY requirements.txt /requirements.txt

# Instalar paquetes del sistema
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
    pip install -r /requirements.txt && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /var/cache/* /requirements.txt 

# Instalar Acestream
# https://docs.acestream.net/products/
RUN mkdir -p /opt/acestream && \
    wget --no-verbose --output-document acestream.tgz "https://download.acestream.media/linux/acestream_${ACESTREAM_VERSION}.tar.gz" && \
    echo "${ACESTREAM_SHA256} acestream.tgz" | sha256sum --check && \
    tar --extract --gzip --directory /opt/acestream --file acestream.tgz && \
    rm -rf acestream.tgz && \
    /opt/acestream/start-engine --version

# Sobrescribir el reproductor web de Ace Stream disfuncional con un reproductor de videojs funcional,
# Acceso en 'http://${INTERNAL_IP}:6878/webui/player/<ID de Acestream>'.
# Se obtiene del enlace 'acestream://xxxxxxxxxx', donde <ID de Acestream> sería 'xxxxxxxxxx'.
COPY web/player.html /opt/acestream/data/webui/html/player.html

# Preparar directorio
RUN mkdir /acelink

# Copiar la configuración de Acestream
COPY config/acestream.conf /opt/acestream/acestream.conf

# Punto de entrada para el contenedor
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

# Exponer los puertos necesarios
EXPOSE 6878
EXPOSE 8621
