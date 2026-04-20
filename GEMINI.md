# Project Context: Acestream Docker Home

## Project Summary

This repository contains a project to package the Acestream service in a Docker container, facilitating its deployment and management. It uses an Ubuntu 22.04 base image and is designed to be robust, flexible, and easy to use, especially for Windows users through automated configuration scripts.

The project has been carefully organized to follow semantic versioning, with a well-defined history of tags and releases on GitHub.

### Technologies and Architecture

- **Containerization:** Docker and Docker Compose.
- **Base Image:** Ubuntu 22.04 with Python 3.10.
- **Main Service:** Acestream Engine (currently v3.2.11).
- **Configuration Script:** A single Windows Batch (`SetupAcestream.bat`) for guided setup with a language selection prompt (English / Spanish) and `--lang=en|es` flag for scripted runs.
- **Entrypoint:** A robust shell script (`entrypoint.sh`) that validates the configuration and prepares the execution environment.
- **Web Interface:** A custom and modern web player (`player.html`) to interact with the Acestream engine.

### Key Features

- **Automated Installation:** Scripts (`.bat`) for Windows that manage Docker checks, IP configuration, dynamic port assignment, and service startup.
- **Multi-instance Support:** Dynamic port assignment allows running multiple Acestream containers simultaneously without conflicts.
- **Flexible Cache Modes:** Support for disk cache (default), RAM cache (`tmpfs` for Linux/WSL2), and memory cache (native to Acestream), configurable via Docker Compose profiles.
- **Health Monitoring:** An integrated `HEALTHCHECK` in Docker to ensure the Acestream engine is functioning correctly, allowing automatic restarts.
- **Offline Builds:** The Acestream binary is included in the repository (`resources/`), which means image building does not depend on external downloads.
- **Internationalization (i18n):** Configuration scripts and a web interface with support for English and Spanish.

## Building and Running

### Image Building

To build the Docker image from the source code, use the following command from the repository root. The project must be cloned first.

```bash
docker build --no-cache -t docker-acestream .
```

### Execution (Methods)

#### 1. Using Configuration Scripts (Windows - Recommended)

This is the easiest method for Windows users.

1.  **Download:** Get `SetupAcestream.bat` from the [GitHub releases assets](https://github.com/sergiomarquezdev/acestream-docker-home/releases).
2.  **Run as Administrator:** The script prompts for language (or accepts `--lang=en|es`) and guides the user through IP and port configuration before starting the container.

#### 2. Using Docker Compose (Cross-platform)

This method is ideal for Linux, macOS, or advanced Windows users.

- **Standard Mode (Disk Cache):**
  ```bash
  docker-compose up -d
  ```

- **RAM Cache Mode (Linux/WSL2):**
  ```bash
  docker-compose --profile ram up -d
  ```

- **Memory Cache Mode (Native Acestream):**
  ```bash
  docker-compose --profile memory up -d
  ```

#### 3. Using Docker CLI

It is possible to run the container directly, although the advantages of Docker Compose management are lost.

```bash
docker run --name docker-acestream -d -p 6878:6878 -e INTERNAL_IP=127.0.0.1 docker-acestream
```

### Testing

The repository includes a feature testing script in `tests/test-features.bat` to validate the different execution profiles (`default`, `ram`, `memory`).

## Development Conventions

- **Versioning:** Strict **Semantic Versioning (SemVer)** is followed. Changes are reflected in Git tags, and each tag has a corresponding **GitHub Release** with a detailed changelog.
- **Dependency Management:** Python dependencies are managed via `pip`, although they are integrated into the `Dockerfile`. The Acestream binary is versioned within the `resources` folder.
- **Commits:** Commit messages follow a convention (e.g., `feat:`, `fix:`, `docs:`) to clarify the nature of each change.
- **Documentation:** `README.md` (English) and `README_es.md` (Spanish) are kept synchronized and must accurately reflect the current state of the project.
- **Robustness:** Scripts prioritize explicit validations, error handling, and detailed logging (as seen in `entrypoint.sh`).