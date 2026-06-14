# Dockerized Acestream

[Leer documentación en Español](README_es.md)

Run Acestream inside a Docker container on Ubuntu 22.04 + Python 3.10. One script, one command, and you have a private streaming engine ready on your machine.

## What's new in v8.2.0

- **Redesigned web player** — clearer first-run guidance (what to paste and where to get a link), a loading indicator while the stream connects, and plain-language errors. English/Spanish.
- **Accessibility pass** — keyboard focus rings, labelled controls, WCAG AA contrast, and a mobile viewport.
- **Hardened frontend** — video.js 8.23.7 over jsDelivr with Subresource Integrity, and a self-contained inline favicon (no third-party requests).
- **Graceful shutdown** — the engine runs as PID 1 (`exec`), so `docker stop` ends it cleanly.
- **Dependency bumps** — `PyNaCl` and `requests` updated.

## Prerequisites

- **Docker Desktop** installed and running. <https://www.docker.com/products/docker-desktop>

## Quick start on Windows (recommended)

1. Download `SetupAcestream.bat` from the [Releases page](https://github.com/sergiomarquezdev/acestream-docker-home/releases).
2. Right-click → **Run as administrator**.
3. Pick your language (`1` Spanish, `2` English; wait 5s for Spanish default).
4. Confirm your internal IP (press ENTER to use auto-detected).
5. The script pulls the image, starts the container, and opens the web player.

### Flags

| Flag | Effect |
|------|--------|
| `--lang=en` | Force English UI |
| `--lang=es` | Force Spanish UI |
| `--auto-clean` | Remove obsolete images after pull |

## Manual run (Linux / macOS / advanced)

```bash
docker build --no-cache -t acestream-engine .
docker run --name acestream-engine -d -p 6878:6878 -e INTERNAL_IP=127.0.0.1 --restart unless-stopped acestream-engine
```

Or use Docker Compose:

```bash
docker-compose up -d
```

See [`.env.example`](.env.example) for all environment variables.

## Cache modes

| Mode | Command |
|------|---------|
| Disk (default) | `docker-compose up -d` |
| RAM (tmpfs, Linux/WSL2) | `docker-compose --profile ram up -d acestream-ram` |
| Memory (cross-platform) | `docker-compose --profile memory up -d acestream-memory` |

## Documentation

- [docs/BUILD.md](docs/BUILD.md) — How the image is built
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) — Startup flow and design decisions
- [docs/TESTING.md](docs/TESTING.md) — How to run smoke tests

## Verifying Container Health

```bash
docker inspect --format='{{json .State.Health}}' acestream-engine
```

Or via web: `http://<INTERNAL_IP>:<PORT>/webui/api/service?method=get_version`

## License

MIT. See [LICENSE](LICENSE).
