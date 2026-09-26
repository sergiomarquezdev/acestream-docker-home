# Dockerized Acestream

[![CI](https://github.com/sergiomarquezdev/acestream-docker-home/actions/workflows/ci.yml/badge.svg)](https://github.com/sergiomarquezdev/acestream-docker-home/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/sergiomarquezdev/acestream-docker-home)](https://github.com/sergiomarquezdev/acestream-docker-home/releases/latest)
[![Docker Pulls](https://img.shields.io/docker/pulls/smarquezp/docker-acestream-ubuntu-home)](https://hub.docker.com/r/smarquezp/docker-acestream-ubuntu-home)

[Leer documentación en Español](README_es.md)

Run the Acestream Engine 3.2.11 inside Docker and watch streams from your browser. On Windows, one script does everything: it starts Docker, pulls the image, runs the engine and opens the web player.

## What's new in v8.3.1

- **Setup script keeps port 6878**: it no longer moves to 6880 right after the player was used (recent client connections were mistaken for a busy port); only a real listener counts. The farewell message shows its "!" again.

### v8.3.0

- **Clean, fast shutdown**: `tini` now runs as PID 1. The engine ignores SIGTERM when it is PID 1 itself, so every `docker stop` used to wait for the timeout and kill it (v8.2.0's `exec` change did not fix this). It now stops in about a second.
- **25% smaller image**: 730 MB → 541 MB (no pip/setuptools/wheel/wget at runtime, and the engine tarball no longer lands in an image layer).
- **Player works offline and on any IP/port**: video.js 8.24.1 is bundled in the image (no CDN), stream URLs are same-origin, a strict Content-Security-Policy is set, and nothing is requested from third parties.
- **Better player UX**: remembers your language (and detects it from the browser), Spanish video controls, shareable links (`/webui/player/?id=<content id>`), a clear "press play" hint when the browser blocks autoplay, and messages for empty or invalid input.
- **Setup script fixes**: picks your real LAN IP (skips VirtualBox/Hyper-V/WSL/VPN adapters), reuses the existing container instead of creating a second one, starts Docker Desktop if needed, `--lang` works again, `--unattended` mode, correct Spanish accents, and it no longer overwrites the repo's `docker-compose.yml`.
- **Updated dependencies**: apsw 3.53.4, lxml 6.1.3, pycryptodome 3.23.0, isodate 0.7.2.
- **CI**: every push is linted, built and smoke-tested on GitHub Actions; Dependabot keeps dependencies current.

## Requirements

- **Docker Desktop** (Windows/macOS) or Docker Engine (Linux): <https://www.docker.com/products/docker-desktop/>
- An **x86_64 (amd64)** machine. The upstream engine has no ARM build, so Raspberry Pi and other ARM boards are not supported.

## Quick start on Windows (recommended)

1. Download [**SetupAcestream.bat**](https://github.com/sergiomarquezdev/acestream-docker-home/releases/latest/download/SetupAcestream.bat) (always the latest release).
2. Double-click it. No administrator rights needed.
3. Pick your language (`1` Spanish, `2` English; Spanish is used after 5 s).
4. Confirm the detected IP (press ENTER).
5. The script starts Docker Desktop if it is not running, pulls the image, starts the engine and opens <http://localhost:6878/webui/player/>.

Running it again updates to the latest image and reuses the same container and port. If port 6878 is taken by something else, it picks the next free one (6880, 6882, ...).

### Flags

| Flag | Effect |
|------|--------|
| `--lang=en` / `--lang=es` | Skip the language prompt |
| `--auto-clean` | Remove obsolete Acestream images without asking |
| `--unattended` | No prompts, no pauses, no browser (accepts the detected defaults; implies `--auto-clean`) |

Set the environment variable `ACESTREAM_IMAGE` to deploy a different image (for example a local build).

## Watching a stream

Paste an `acestream://...` link or the bare 40-character content ID into the player and press **Play**. It can take 10-30 seconds to connect to peers.

Links can be shared or bookmarked: `http://localhost:6878/webui/player/?id=<content id>`.

### From other devices (TV, phone, tablet)

The engine listens on your local network. Open `http://<your-PC-IP>:6878/webui/player/` on another device; the setup script prints this URL. The first time, Windows Firewall may ask you to allow Docker. The player has no authentication, so anyone on your network can use it. **Do not expose the port to the internet.**

## Manual run (Linux / macOS / advanced)

```bash
docker run -d --name acestream-engine -p 6878:6878 --restart unless-stopped \
  smarquezp/docker-acestream-ubuntu-home:latest
```

Or with Docker Compose from a clone of this repo:

```bash
docker compose up -d
```

Copy [`.env.example`](.env.example) to `.env` to change the image, ports or extra engine flags.

## Cache modes

| Mode | Command |
|------|---------|
| Disk (default) | `docker compose up -d` |
| RAM (tmpfs, Linux/WSL2) | `docker compose --profile ram up -d acestream-ram` |
| Memory (cross-platform) | `docker compose --profile memory up -d acestream-memory` |

Always name the profile service: without it, the base service starts too and both fight for port 6878.

## Updating and uninstalling

- **Windows**: run `SetupAcestream.bat` again to update. To remove it: `docker compose -f acestream-compose.yml down` in the folder where the script lives (or `docker rm -f acestream-engine_6878`).
- **Compose**: `docker compose pull && docker compose up -d` to update, `docker compose down` to remove.

## Troubleshooting

| Problem | What to do |
|---------|------------|
| "No peers found" | The stream is probably offline. Try another link. |
| "Ready. Press the play button to start watching." | Your browser blocked autoplay: press the play button. |
| Docker is not running | The script tries to start Docker Desktop and waits up to 2 minutes. Start it manually if it keeps failing. |
| Port already in use | The script picks the next free port automatically; with Compose, set `HTTP_PORT`/`HTTPS_PORT` in `.env`. |

Check the container health:

```bash
docker inspect --format='{{json .State.Health}}' acestream-engine
```

Or open `http://<HOST>:<PORT>/webui/api/service?method=get_version`.

## Documentation

- [docs/BUILD.md](docs/BUILD.md): how the image is built, dependencies and design constraints
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md): startup flow and design decisions
- [docs/TESTING.md](docs/TESTING.md): smoke tests and CI

## License

MIT. See [LICENSE](LICENSE).
