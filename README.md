# Dockerized Acestream

[Leer documentación en Español](README_es.md)

This project facilitates the deployment of Acestream within a Docker container, using Ubuntu 18.04 (Bionic Beaver) to
ensure compatibility with the version of Acestream used.

Acestream is a popular platform for live streaming that allows users to share and view video content through
peer-to-peer networks. Using Acestream in a Docker container offers an efficient and isolated way to run Acestream,
making its installation and setup easier.

## Prerequisites

Before you begin, you will need to have Docker installed and running on your machine. This guide assumes you have a
basic understanding of Docker containers and the Docker ecosystem.

To install Docker, follow the instructions on the [official Docker documentation](https://docs.docker.com/get-docker/) or visit the [Docker products page](https://www.docker.com/products/docker-desktop) to download the appropriate version for your operating system.

To ensure that Docker is installed correctly and ready to use, execute:

```bash
docker --version
```

## Automatic Installation and Execution with `SetupAcestream.bat` (Windows)

We have provided a `.bat` script named `SetupAcestream.bat` to simplify the entire process of installing, configuring, and running Acestream in Docker containers for Windows users. The script automates several steps, including:

1. Verification and installation of Docker if necessary.
2. Downloading the latest Docker image of `smarquezp/docker-acestream-ubuntu-home` from Docker Hub.
3. Running the container, exposing port 6878, which allows access to the Acestream service from any device within your
   local network.

### How to Use the `SetupAcestream.bat` Script

Simply download the [SetupAcestream.bat](https://github.com/marquezpsergio/acestream-docker/releases) file and run it as
Administrator. This script prepares everything needed to run Acestream in Docker and automatically opens the web
interface where you can directly load Acestream links.

> **Note:** This process ensures that you are always using the latest version of the Docker image for Acestream and
> allows you to efficiently manage the container.

## Building the Image

This project uses the **ubuntu:bionic** base image and is compatible with the Acestream version *
*acestream_3.1.74_ubuntu_18.04_x86_64.tar.gz**.

To build your own Docker image from this Dockerfile, execute the following command in the terminal, ensuring you are in the same directory as the Dockerfile:

```bash
docker build --no-cache -t docker-acestream-ubuntu-home .
```

If you need to use a different version of Acestream and its SHA256 hash, you can specify them when building the image with the following arguments:

```bash
docker build --no-cache --build-arg ACESTREAM_VERSION=your_acestream_version --build-arg ACESTREAM_SHA256=your_sha256_hash -t docker-acestream-ubuntu-home .
```

## Running the Container

With the Docker image built, you can start a container to run Acestream as follows:

```bash
docker run --name acestream -d -p 6878:6878 -e INTERNAL_IP=127.0.0.1 --restart unless-stopped docker-acestream-ubuntu-home
```

## Running the Container with Docker Compose

Download or copy the contents of the `docker-compose.yml` file.

From the same directory where the file is located, execute:

```bash
docker-compose up -d
```

### Updating with Docker Compose

To ensure you are using the latest version of the image, execute:

```bash
docker-compose pull && docker-compose up -d
```

## Accessing the Web Interface

Once the container is running and there are no errors in the logs, you can access the Acestream web interface using a
web browser and going to `http://localhost:6878/webui/player/`. Here you can directly load Acestream links in the field
located in the top left corner of the screen. Additionally, you can hide or show this field using the icon that appears
to its left.

## Verifying Container Health

You can check the health status of the container with the following command:

```bash
docker inspect --format='{{json .State.Health}}' acestream
```

The health status can also be verified through the web interface itself, via the
link: `http://localhost:6878/webui/api/service?method=get_version`.

## Contributions

Your participation in the project is highly appreciated. If you have suggestions for improvements or corrections and
wish to contribute, follow the standard GitHub steps to fork, make changes, and submit a pull request for review.

## License

This project is distributed under the MIT License, which means you can modify, distribute, or use it as you wish under
the terms of this license. For more information, see the [LICENSE](LICENSE) file included in this repository.
