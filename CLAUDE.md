# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo does

Packages **Acestream Engine 3.2.11** in a Docker container (Ubuntu 22.04 + Python 3.10) and ships a one-click Windows setup script. The published image on Docker Hub is `smarquezp/docker-acestream-ubuntu-home` (tags `:latest`, `:vX.Y.Z`).

The bundled `resources/acestream.tar.gz` is the upstream Linux x86_64 binary; the repo does **not** re-package the engine, only the container around it.

## Common commands

### Build + verify

```bash
# Build (SHA256 of resources/acestream.tar.gz is verified automatically)
docker build --no-cache -t acestream-engine .

# Override the expected SHA256 when bumping the Acestream tarball
docker build --build-arg ACESTREAM_SHA256=<new-hash> -t acestream-engine .

# Full smoke test from cmd.exe / PowerShell (see docs/TESTING.md)
#   exit 0 = all pass   1 = at least one failed   2 = env not ready
#   ACESTREAM_IMAGE=acestream-engine:latest tests the local build instead of Docker Hub
tests\test-features.bat
```

From Git Bash, a bare `cmd.exe /c tests\test-features.bat` breaks (bash eats the backslash): call it from a small wrapper `.bat` or from cmd/PowerShell.

### Run

```bash
# Default profile — disk cache (.env can override ACESTREAM_IMAGE, HTTP_PORT, HTTPS_PORT, ACESTREAM_EXTRA_FLAGS)
docker compose up -d

# Cross-platform RAM cache via Acestream's native flag
docker compose --profile memory up -d acestream-memory

# tmpfs RAM cache (Linux / WSL2 only)
docker compose --profile ram up -d acestream-ram

# Inspect
docker inspect --format='{{.State.Health.Status}}' acestream-engine
curl -s "http://127.0.0.1:6878/webui/api/service?method=get_version"
```

**Critical**: when starting a profile service, always name the service explicitly (`up -d acestream-memory` / `acestream-ram`). Plain `docker compose --profile X up -d` brings the *base* service up as well, and both race for port 6878; whichever wins, the other fails with "port already allocated".

### CI / publishing

- `.github/workflows/ci.yml`: shellcheck + hadolint + actionlint + build + smoke (health, version, player, graceful stop) on every push/PR to `main`.
- `.github/workflows/release.yml`: on `v*` tags, pushes `:vX.Y.Z` and `:latest` to Docker Hub **only if** the `DOCKERHUB_USERNAME` / `DOCKERHUB_TOKEN` repo secrets exist (otherwise it skips with a notice), then uploads `SetupAcestream.bat` to the matching GitHub Release if it already exists.
- `.github/dependabot.yml`: weekly pip (`requirements.txt`), Docker base image and Actions updates.

Manual Docker Hub publish (when the secrets are not configured):

```bash
docker tag acestream-engine:latest smarquezp/docker-acestream-ubuntu-home:vX.Y.Z
docker tag acestream-engine:latest smarquezp/docker-acestream-ubuntu-home:latest
docker push smarquezp/docker-acestream-ubuntu-home:vX.Y.Z
docker push smarquezp/docker-acestream-ubuntu-home:latest
```

## Architecture

### Dockerfile

Multi-stage build:

1. **Builder** (`ubuntu:22.04 AS builder`): build toolchain + `pip install --prefix=/install -r requirements.txt` (exact pins of the native modules `apsw`, `lxml`, `PyNaCl`, `pycryptodome`, `requests`, `isodate`). Ubuntu's pip lays them out under `/install/local/lib/python3.10/dist-packages`.
2. **Runtime** (`ubuntu:22.04`): runtime-only apt packages (`python3`, `libpython3.10`, the `python3-{greenlet,gevent,psutil,simplejson}` debs, `libxml2`, `libxslt1.1`, `libsqlite3-0`, `procps`, `tini`) and a `COPY --from=builder` of the dist-packages. No `pip`/`setuptools`/`wheel`/`wget` at runtime: the engine never uses them. Labels: OCI `org.opencontainers.image.*` plus `maintainer="sergiomarquezdev"`, which **must stay**: `SetupAcestream.bat` prunes old images by that label.

Result: **~541 MB** image. apt packages are deliberately unpinned and the tarball is deliberately not in Git LFS (rationale in `docs/BUILD.md`). The engine is x86_64-only upstream: no arm64 image is possible.

**Python 3.10 is a hard constraint**, not a style choice: the engine tarball bundles `cp310`-only wheels and its `.so` files link `libpython3.10`. Do not bump the base to `ubuntu:24.04` without a matching upstream engine.

The Acestream tarball is **bind-mounted** (not `COPY`'d) into the RUN that verifies and extracts it, so the 77 MB archive never lands in an image layer:

```dockerfile
ARG ACESTREAM_SHA256=9b6bbd76a55e5a434641afae3b9cf8e6154ce1cf392152ec3aed5ac265432b2e
RUN --mount=type=bind,source=resources/acestream.tar.gz,target=/tmp/acestream.tar.gz \
    echo "${ACESTREAM_SHA256}  /tmp/acestream.tar.gz" | sha256sum --check && tar --extract ...
```

A mismatched archive fails the build immediately. `RUN --mount` needs BuildKit (default in Docker Desktop / Engine 23+).

### Startup flow

1. `ENTRYPOINT ["/usr/bin/tini", "-g", "--", "/entrypoint.sh"]` fires. **tini is required**: the engine ignores SIGTERM when it is PID 1, so without it every `docker stop` waits the full timeout and ends in SIGKILL (exit 137). `-g` is needed because `/opt/acestream/start-engine` is a `sh` wrapper that does not `exec`, leaving the engine as a grandchild.
2. `config/entrypoint.sh` validates `HTTP_PORT` / `HTTPS_PORT` and `exec`s `/opt/acestream/start-engine` with `${ACESTREAM_EXTRA_FLAGS}` appended (this is how the `memory` profile injects `--live-cache-type memory`).
3. `HEALTHCHECK` polls the in-container API `get_version` every 30s (start period 40s, 3 retries).

The player needs no runtime patching: it is served by the engine itself and requests the stream with a same-origin path (`/ace/manifest.m3u8?...`), so it works for any host, IP or port. There is no `INTERNAL_IP` in the container contract.

### docker-compose.yml

One base service (`acestream-engine`) and two profile services that `extends:` it:

- `ram` → adds a tmpfs mount of `/root/.ACEStream/.acestream_cache` (Linux/WSL2 only).
- `memory` → overrides only `ACESTREAM_EXTRA_FLAGS=--live-cache-type memory` (`extends` merges `environment` by key; verify with `docker compose --profile memory config`).

The base service reads `ACESTREAM_IMAGE`, `HTTP_PORT`, `HTTPS_PORT` and `ACESTREAM_EXTRA_FLAGS` from the environment / `.env` (see `.env.example`), with `restart: unless-stopped` and json-file log rotation (10m × 3). No `version:` key; no duplicated `healthcheck:` in compose — the Dockerfile HEALTHCHECK is the single source of truth.

### SetupAcestream.bat (Windows)

Unified bilingual script. Flow:

1. `cd /d "%~dp0"` (an elevated/UAC launch starts in `System32`). Parses `--lang=en|es`, `--auto-clean`, `--unattended` (no prompts/pauses/browser). **cmd splits arguments on `=`**, so `--lang=es` arrives as two tokens; the parser rebuilds them. `ACESTREAM_IMAGE` overrides the image (pull skipped if it exists locally).
2. If no `--lang`, shows a bilingual prompt (`[1] Español (default)`, `[2] English`) with a 5 s timeout defaulting to **Spanish**. This is the flow non-technical users hit when they double-click.
3. Loads all user-visible strings into `MSG_*` vars according to the language; comments and logs stay English.
4. Ensures Docker is up (starts Docker Desktop and waits up to 120 s; clear message if not installed). Picks `docker compose` (v2) or falls back to `docker-compose`.
5. Detects the LAN IPv4 of the adapter with a default gateway (PowerShell `Get-NetIPConfiguration`), falling back to `ipconfig` minus virtual adapters (VirtualBox/Hyper-V/WSL/VMware/TAP/Tailscale). The IP is only printed as the LAN URL for other devices; the browser opens `http://localhost:<port>/webui/player/`.
6. Reuses an existing `acestream-engine_<port>` container's port if there is one (never two containers); otherwise finds a free port starting at 6878 (steps of 2). Writes **`acestream-compose.yml`** (git-ignored runtime artefact; never the committed `docker-compose.yml`) with `restart: unless-stopped` and log rotation.
7. Pulls, prunes dangling images with `label=maintainer=sergiomarquezdev`, runs `up -d` once (no retry loop), prints the URLs and opens the browser.

Sleeps use `ping -n N 127.0.0.1 >nul` (stdin-redirected `timeout.exe` fails). `echo !VAR!| findstr` must have **no space before the pipe** (the trailing space breaks `$` anchors).

### web/ (player)

`player.html` + `player.css` + `player.js` + `vendor/videojs/` (video.js 8.24.1 with the Spanish language pack, vendored: no CDN). The engine serves `/opt/acestream/data/webui/<dir>/<file>` at `/webui/<dir>/<file>`, but `/webui/player/*` always returns `html/player.html`, so assets are referenced with **absolute** `/webui/...` paths. Stream URL is the same-origin `/ace/manifest.m3u8?transcode_audio=1&content_id=`; nothing patches the files at runtime. A strict CSP `<meta>` forbids third-party requests. Language: `localStorage` > `navigator.language` > English. Deep links: `?id=<40 hex>` or `#acestream://...`.

## Conventions specific to this repo

- **Line endings**: `.gitattributes` pins `*.sh eol=lf` and `*.bat eol=crlf`. **Never** reintroduce `dos2unix` in the Dockerfile — clones already land with LF shell scripts on every platform. If a COPY step ships a CRLF script, fix `.gitattributes`, not the build.
- **Commits**: Conventional Commits in English. No AI attribution / `Co-Authored-By`.
- **Versioning**: SemVer via git tags. Each tag ships a GitHub Release with `SetupAcestream.bat` as an asset; Docker Hub tags are kept aligned (`:latest`, `:vX.Y.Z` can share a digest for patch releases that only touch the `.bat`).
- **README sync**: `README.md` (EN) and `README_es.md` (ES) must stay structurally in sync. Both carry the "What's new" block for the current release.
- **No build-time backward-compatibility shims**: when something is removed (e.g. `ACESTREAM_VERSION` env, `SetupAcestream_es.bat`, `version: '3.8'` in compose), it goes cleanly — no "deprecated, keep around" vestiges.

## Tests

`tests/test-features.bat` is the regression gate. There is no unit-test framework.

- Non-interactive; exits with 0/1/2. Honours `ACESTREAM_IMAGE` to test a local build.
- Six tests: default, memory and ram profiles; graceful stop (<10 s, exit 143/0); same-origin player; `SetupAcestream.bat --unattended` run twice leaves exactly one container.
- Forces `%SystemRoot%\System32` first on `PATH` and uses `ping -n N 127.0.0.1 >nul` as the sleep primitive. This is so the script runs cleanly from `cmd.exe` **and** from Git Bash / MSYS, where coreutils can shadow `timeout`/`findstr` and stdin-redirected `timeout.exe` fails outright.
- `waitHealthy` subroutine polls `docker inspect .State.Health.Status` with a 75 s budget.
- Profile tests start the specific profile service by name to dodge the base-service port race documented above.
- CI covers the Linux side on every push; the `.bat` tests only run locally on Windows.

## Releasing

1. Commit all changes to `main` and push (only with explicit user confirmation — global "no auto-push" rule). Wait for CI to go green.
2. Update the "What's new" block in both READMEs.
3. `git tag -a vX.Y.Z -m "..."` and `git push origin vX.Y.Z`.
4. `gh release create vX.Y.Z SetupAcestream.bat --title "..." --notes "..."`.
5. Push the Docker image (release workflow if the Docker Hub secrets exist, otherwise the manual commands above) and keep the Docker Hub overview current.

Patch releases that only touch the setup script or docs can reuse the previous image digest — just retag `smarquezp/docker-acestream-ubuntu-home:vX.Y.Z` from the existing `:latest` and push.

## Related docs

- `README.md` / `README_es.md`: user-facing. Keep the two in sync.
- `AGENTS.md`: symlink to this file (for agents that look for that name by convention).
