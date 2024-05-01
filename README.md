# Dockerized Acestream

[Leer documentación en Español](README_es.md)

This project deploys Acestream within a Docker container using Ubuntu 22.04 and Python 3.10 for compatibility.

Acestream is a platform for live streaming via peer-to-peer networks. Dockerizing Acestream simplifies its setup and
provides isolated environments.

## Prerequisites

1. **Docker Installation**: Ensure Docker Desktop is installed on your system.
   - [Docker Products Page](https://www.docker.com/products/docker-desktop)
   - [Official Documentation](https://docs.docker.com/get-docker/)

## Automatic Installation and Execution with `SetupAcestream.bat` (Windows)

1. **Script Overview**: The `SetupAcestream.bat` script automates:
   - Docker installation (if needed)
   - Docker image download
   - Container setup (port 6878 exposed for network access)

2. **Usage**: Download and run the [SetupAcestream.bat](https://github.com/marquezpsergio/acestream-docker/releases)
   script as Administrator.

> **Note:** This ensures the latest Acestream Docker image and container management.

## Building the Image

This project uses the **ubuntu:22.04** base image. You must clone the project first.
Then, to build the image use:

```bash
docker build --no-cache -t docker-acestream .
```

## Running the Container

To start a container and run Acestream:

```bash
docker run --name docker-acestream -d -p 6878:6878 -e INTERNAL_IP=127.0.0.1 --restart unless-stopped docker-acestream
```

## Docker Compose

1. **Start the Container**: Use `docker-compose` to start the container:

   ```bash
   docker-compose up -d
   ```

2. **Update the Image**: To get the latest image version:

   ```bash
   docker-compose pull && docker-compose up -d
   ```

## Accessing the Web Interface

Access Acestream via the web interface at `http://localhost:6878/webui/player/`. Load Acestream links in the top left
field.

## Verifying Container Health

Check the health status:

```bash
docker inspect --format='{{json .State.Health}}' docker-acestream
```

Or via the web interface: `http://localhost:6878/webui/api/service?method=get_version`.

## Contributions

We welcome contributions. Fork, make changes, and submit a pull request for review.

## License

This project is under the MIT License. See [LICENSE](LICENSE) for more details.
