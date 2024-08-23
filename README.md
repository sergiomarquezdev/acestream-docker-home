# Dockerized Acestream

[Leer documentación en Español](README_es.md)

This project deploys Acestream within a Docker container using Ubuntu 22.04 and Python 3.10 for compatibility.

Acestream is a platform for live streaming via peer-to-peer networks. Dockerizing Acestream simplifies its setup and provides isolated environments.

## Prerequisites

1. **Docker Installation**: Ensure Docker Desktop is installed on your system.
   - [Docker Products Page](https://www.docker.com/products/docker-desktop)
   - [Official Documentation](https://docs.docker.com/get-docker/)

## Automatic Installation and Execution with `SetupAcestream.bat` (Windows)

1. **Script Overview**: The `SetupAcestream.bat` script automates the following tasks:

   - Checking for Docker installation and operational status.
   - Downloading the latest Acestream Docker image.
   - Setting up the container with dynamic port assignment (to avoid conflicts).
   - Updating the `docker-compose.yml` file dynamically based on the available ports.
   - Starting the Acestream container and opening the web interface.

2. **Usage**: Download and run the `SetupAcestream.bat` script as Administrator.

> **Note:** The script ensures the latest Acestream Docker image is used and that the container management is handled
> efficiently.

## Building the Image

This project uses the **ubuntu:22.04** base image. You must clone the project first. Then, to build the image, use:

```bash
docker build --no-cache -t docker-acestream .
```

## Running the Container

To start a container and run Acestream with dynamic port assignment:

```bash
docker run --name docker-acestream -d -p 6878:6878 -e INTERNAL_IP=127.0.0.1 --restart unless-stopped docker-acestream
```

The `SetupAcestream.bat` script handles the dynamic assignment of ports to prevent conflicts when running multiple
instances.

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

Access Acestream via the web interface. The `SetupAcestream.bat` script automatically opens the correct URL based on the
assigned port:

```plaintext
http://<INTERNAL_IP>:<PORT>/webui/player/
```

You can load Acestream links directly in the provided input field.

## Verifying Container Health

Check the health status of the Acestream container:

```bash
docker inspect --format='{{json .State.Health}}' docker-acestream
```

Alternatively, use the web interface:

```plaintext
http://<INTERNAL_IP>:<PORT>/webui/api/service?method=get_version
```

## Customization

### Dynamic Port Assignment

The project includes dynamic port assignment for both HTTP and HTTPS ports to prevent conflicts when running multiple
instances. This is handled in the `SetupAcestream.bat` script.

### Web Interface Configuration

The `player.html` file is dynamically updated with the correct IP address and port during the container startup process.
This ensures that the web interface points to the correct Acestream engine instance.

## Contributions

We welcome contributions. Fork, make changes, and submit a pull request for review.

## License

This project is under the MIT License. See [LICENSE](LICENSE) for more details.
