# Dockerized Acestream

[Leer documentación en Español](README_es.md)

Run Acestream inside a Docker container on Ubuntu 22.04 + Python 3.10. One script, one command, and you have a private streaming engine ready on your machine.

Acestream is a peer-to-peer live-streaming platform. Containerizing it makes setup repeatable and keeps it isolated from the rest of your system.

## What's new in v8.1.0

- **Smaller image** — ~40% slimmer (1.19 GB → 729 MB) by purging the build toolchain after compiling native Python modules.
- **SHA256 integrity check** — the bundled Acestream tarball is verified against a pinned hash during `docker build`; a tampered or corrupted archive aborts the build.
- **One unified setup script** — `SetupAcestream.bat` now asks your language at launch (or pass `--lang=en` / `--lang=es` to skip the prompt). The old `SetupAcestream_es.bat` is gone.
- Various quality-of-life fixes: deprecated `version:` field removed, single-source `HEALTHCHECK`, consistent LF line endings via `.gitattributes`.

## Prerequisites

You only need **Docker Desktop** installed and running.

- Download: <https://www.docker.com/products/docker-desktop>
- Help: <https://docs.docker.com/get-docker/>

## Quick start on Windows (recommended)

1. Download `SetupAcestream.bat` from the [Releases page](https://github.com/sergiomarquezdev/acestream-docker-home/releases).
2. Right-click the file and choose **Run as administrator**.
3. When asked, pick your language (press `1` for English, `2` for Spanish — default is English after 5 seconds).
4. Confirm your internal IP address (just press ENTER to use the auto-detected one).
5. The script pulls the latest image, starts the container, and opens the web player automatically.

### Command-line flags

| Flag | Effect |
|------|--------|
| `--lang=en` | Force English UI (skips the language prompt). |
| `--lang=es` | Force Spanish UI (skips the language prompt). |
| `--auto-clean` | Remove obsolete Acestream images automatically after pulling a newer one. |

### What the script does under the hood

- Checks that Docker is installed and running.
- Detects a non-loopback internal IPv4 address.
- Finds a free port pair (default `6878`/`6879`, falling back to the next free even port up to `6920`).
- Writes a `docker-compose.yml` tailored to your environment.
- Pulls the latest image, starts the container, and opens `http://<ip>:<port>/webui/player/`.

## Building the Image

This project uses the **ubuntu:22.04** base image. You must clone the project first. Then, to build the image, use:

```bash
docker build --no-cache -t acestream-engine .
```

## Running the Container

To start a container and run Acestream with dynamic port assignment:

```bash
docker run --name acestream-engine -d -p 6878:6878 -e INTERNAL_IP=127.0.0.1 --restart unless-stopped acestream-engine
```

The `SetupAcestream.bat` script handles the dynamic assignment of ports to prevent conflicts when running multiple
instances.

## Docker Compose

### Standard Mode (Disk Cache)

1. **Start the Container**: Use `docker-compose` to start the container:

   ```bash
   docker-compose up -d
    ```

2. **Update the Image**: To get the latest image version:

   ```bash
   docker-compose pull && docker-compose up -d
    ```

### RAM Cache Mode (Linux/WSL2 Only)

For improved performance and reduced disk wear, you can run Acestream with cache stored in RAM instead of disk.

**Requirements:**
- Linux host or WSL2 (does not work on Docker Desktop for Windows without WSL2)
- At least 8GB of available RAM

**Usage:**

1. **Stop any running containers first:**

   ```bash
   docker-compose down
   ```

2. **Start in RAM cache mode:**

   ```bash
   docker-compose --profile ram up -d
   ```

   > **Note:** Docker Compose will attempt to start both the base container (`acestream-engine`) and the RAM profile container (`acestream-engine-ram`). The base container will fail to start due to port conflict (this is expected behavior). Only `acestream-engine-ram` will run successfully on port 6878.

3. **Verify only the RAM container is running:**

   ```bash
   docker ps --filter "name=acestream-engine" --format "table {{.Names}}\t{{.Status}}"
   ```

   Expected output: Only `acestream-engine-ram` should be running and healthy.

4. **Switch back to standard mode:**

   ```bash
   docker-compose down
   docker-compose up -d
   ```

**Monitor RAM usage:**

```bash
# Check current RAM usage
docker exec acestream-engine-ram df -h | grep ACEStream

# Real-time monitoring
watch -n 1 "docker exec acestream-engine-ram df -h /root/.ACEStream/.acestream_cache"
```

**Important Notes:**
- Only one mode (standard or RAM) can run at a time due to port conflicts
- Cache data is lost when the container stops (this is expected behavior for RAM cache)
- RAM cache significantly reduces disk writes, extending SSD lifespan
- The RAM cache size is set to 8GB by default

### Memory Cache Mode (Cross-Platform)

For users who want RAM caching but need cross-platform compatibility, use the native Acestream memory flag:

**Usage:**

1. **Stop any running containers first:**

   ```bash
   docker-compose down
   ```

2. **Start in memory cache mode:**

   ```bash
   docker-compose --profile memory up -d
   ```

   > **Note:** Docker Compose will attempt to start both the base container (`acestream-engine`) and the memory profile container (`acestream-engine-memory`). The base container will fail to start due to port conflict (this is expected behavior). Only `acestream-engine-memory` will run successfully on port 6878.

3. **Verify the flag is active:**

   ```bash
   docker logs acestream-engine-memory | grep "Extra Flags"
   ```

   Expected output: `Extra Flags: --live-cache-type memory`

**Features:**
- Uses Acestream's native `--live-cache-type memory` flag
- Works on Windows, macOS, and Linux (unlike tmpfs which requires Linux/WSL2)
- Acestream manages memory allocation automatically
- Cache is lost when container stops (expected behavior)

**Comparison:**

| Mode | Storage | Platform | RAM Control | Command |
|------|---------|----------|-------------|---------|
| Default | Disk | All | N/A | `docker-compose up -d` |
| RAM (tmpfs) | RAM (8GB) | Linux/WSL2 | Docker | `docker-compose --profile ram up -d` |
| Memory (flag) | RAM (auto) | All | Acestream | `docker-compose --profile memory up -d` |

**Why does the base container fail when using profiles?**

When you run `docker-compose --profile <profile> up -d`, Docker Compose starts both the base service and the profile-specific service because the profile services use `extends` to inherit configuration. Since both try to bind to port 6878, the base container fails (expected), and only the profile container runs successfully. This is normal Docker Compose behavior and ensures backward compatibility when running `docker-compose up -d` without any profile.

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
docker inspect --format='{{json .State.Health}}' acestream-engine
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

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| INTERNAL_IP | IP address used by the player and engine to bind as the advertised endpoint. | 127.0.0.1 |
| HTTP_PORT | Port exposed for HTTP traffic inside the container. | 6878 |
| HTTPS_PORT | Port exposed for HTTPS traffic inside the container. | 6879 |

## Key Features

- One-click Windows setup scripts with automatic Docker image download and dynamic port assignment.
- Pre-configured `acestream.conf` with production-ready limits for concurrent peers and robust caching.
- Hardened startup script (`entrypoint.sh`) that validates environment variables and outputs detailed diagnostics.
- Automatic patch of `player.html` so the web UI always points to the correct IP and port.
- Multi-instance support: launch several containers simultaneously without port clashes.
- **Health monitoring**: Built-in healthcheck detects service failures and enables auto-restart.
- **Flexible cache modes**: Choose disk, RAM (tmpfs), or memory (native flag) based on your platform and needs.
- Offline builds thanks to the bundled `resources/acestream.tar.gz` archive (no external downloads required).
- Built-in **port conflict detection**: if the default port `6878` is already occupied (e.g. by the desktop Acestream Player), the Windows setup script automatically picks the next free even port.
- Optional `--auto-clean` flag: after pulling a newer image the script can safely delete outdated Acestream container images to keep your Docker host tidy.

## Troubleshooting & Tips

- Ensure the ports selected by the Windows script are **open in your firewall**.
- If you see "port already in use" errors, the script should automatically switch to the next free port — verify the final port printed in the console.
- For Linux/macOS usage set `INTERNAL_IP`, `HTTP_PORT`, and `HTTPS_PORT` accordingly when running `docker run` or `docker-compose`.
- Use `--auto-clean` with the setup script to automatically remove obsolete Acestream images after an update (or answer *Y* when prompted).
- View real-time logs with `docker logs -f <container_name>` to diagnose engine issues.
- The engine writes additional debug information when the `--log-debug` flag is enabled in `acestream.conf`.

## Legal Notice

This repository only distributes automation scripts. The Acestream binary blob is provided for **personal, educational or research purposes**.
You are solely responsible for ensuring that your usage complies with all applicable laws and regulations.

## Contributions

We welcome contributions. Fork, make changes, and submit a pull request for review.

## License

This project is under the MIT License. See [LICENSE](LICENSE) for more details.
