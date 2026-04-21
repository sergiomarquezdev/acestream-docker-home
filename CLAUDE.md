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

# Full smoke test (non-interactive; WSL2 is auto-detected for the ram profile)
#   exit 0 = all pass   1 = at least one failed   2 = env not ready
cmd.exe /c tests\test-features.bat
```

### Run

```bash
# Default profile — disk cache
docker-compose up -d

# Cross-platform RAM cache via Acestream's native flag
docker-compose --profile memory up -d acestream-memory

# tmpfs RAM cache (Linux / WSL2 only)
docker-compose --profile ram up -d acestream-ram

# Inspect
docker inspect --format='{{.State.Health.Status}}' acestream-engine
curl -s "http://127.0.0.1:6878/webui/api/service?method=get_version"
```

**Critical**: when starting a profile service, always name the service explicitly (`up -d acestream-memory` / `acestream-ram`). Plain `docker-compose --profile X up -d` brings the *base* service up as well, and both race for port 6878; whichever wins, the other fails with "port already allocated".

### Docker Hub publish (manual — no CI yet)

```bash
docker tag acestream-engine:latest smarquezp/docker-acestream-ubuntu-home:vX.Y.Z
docker tag acestream-engine:latest smarquezp/docker-acestream-ubuntu-home:latest
docker push smarquezp/docker-acestream-ubuntu-home:vX.Y.Z
docker push smarquezp/docker-acestream-ubuntu-home:latest
```

## Architecture

### Dockerfile

Single heavy RUN layer:

1. `apt-get install` the full runtime **plus** the build toolchain (`build-essential`, `python3-dev`, `lib{sqlite3,xml2,xslt1}-dev`).
2. `pip install` the native modules (`lxml`, `apsw`, `PyNaCl`, `pycryptodome`, `requests`, `isodate`).
3. `apt-get purge --auto-remove` the whole toolchain.
4. **Reinstall** `libxml2`, `libxslt1.1`, `libsqlite3-0` explicitly — these are the runtime-only flavors the C extensions dlopen at import time; `--auto-remove` will otherwise drop them as orphaned dev deps.
5. `rm -rf /var/lib/apt/lists/*`.

Result: **729 MB** image. Multi-stage was considered and rejected (Ubuntu+apt forces you to reinstall runtime deps in the final stage anyway, so the complexity buys little).

The Acestream tarball is copied and extracted in its own RUN, guarded by a SHA256 check:

```dockerfile
ARG ACESTREAM_SHA256=9b6bbd76a55e5a434641afae3b9cf8e6154ce1cf392152ec3aed5ac265432b2e
RUN echo "${ACESTREAM_SHA256}  /tmp/acestream.tar.gz" | sha256sum --check && tar --extract ...
```

A mismatched archive fails the build immediately.

### Startup flow

1. `ENTRYPOINT ["/entrypoint.sh"]` fires.
2. `config/entrypoint.sh` validates `INTERNAL_IP` / `HTTP_PORT` / `HTTPS_PORT`, patches `/opt/acestream/data/webui/html/player.html` with the real IP:port via `sed`, and `exec`s `/opt/acestream/start-engine` with `${ACESTREAM_EXTRA_FLAGS}` appended (this is how the `memory` profile injects `--live-cache-type memory`).
3. `HEALTHCHECK` polls the in-container API `get_version` every 30s (start period 40s, 3 retries).

### docker-compose.yml

One base service (`acestream-engine`) and two profile services that `extends:` it:

- `ram` → adds a tmpfs mount of `/root/.ACEStream/.acestream_cache` (Linux/WSL2 only).
- `memory` → duplicates the entire `environment:` block (Compose `extends` **replaces**, does not merge) and appends `ACESTREAM_EXTRA_FLAGS=--live-cache-type memory`.

No `version:` key; no duplicated `healthcheck:` in compose — the Dockerfile HEALTHCHECK is the single source of truth.

### SetupAcestream.bat (Windows)

Unified bilingual script. Flow:

1. Parses `--auto-clean` / `--lang=en|es` flags.
2. If no `--lang`, shows a bilingual prompt (`[1] Español (default)`, `[2] English`) with a 5 s timeout defaulting to **Spanish**. This is the flow non-technical users hit when they double-click.
3. Loads all user-visible strings into `MSG_*` vars according to the language; comments and logs stay English for consistency with the rest of the repo.
4. Detects a non-loopback IPv4, finds a free port pair starting at 6878/6879, and **writes a dynamic docker-compose.yml** with a service named `acestream-engine_<port>` (e.g. `acestream-engine_6880` when 6878 is taken). This generated file is a runtime artefact — when present, it overrides the committed `docker-compose.yml`.
5. Pulls the image, optionally cleans obsolete image IDs, runs `docker-compose up -d`, and opens the browser.

### web/player.html

Custom player UI with English/Spanish toggle, copied over the stock one during build. The entrypoint patches absolute URLs to use the runtime IP/port.

## Conventions specific to this repo

- **Line endings**: `.gitattributes` pins `*.sh eol=lf` and `*.bat eol=crlf`. **Never** reintroduce `dos2unix` in the Dockerfile — clones already land with LF shell scripts on every platform. If a COPY step ships a CRLF script, fix `.gitattributes`, not the build.
- **Commits**: Conventional Commits in English. No AI attribution / `Co-Authored-By`.
- **Versioning**: SemVer via git tags. Each tag ships a GitHub Release with `SetupAcestream.bat` as an asset; Docker Hub tags are kept aligned (`:latest`, `:vX.Y.Z` can share a digest for patch releases that only touch the `.bat`).
- **README sync**: `README.md` (EN) and `README_es.md` (ES) must stay structurally in sync. Both carry the "What's new" block for the current release.
- **No build-time backward-compatibility shims**: when something is removed (e.g. `ACESTREAM_VERSION` env, `SetupAcestream_es.bat`, `version: '3.8'` in compose), it goes cleanly — no "deprecated, keep around" vestiges.

## Tests

`tests/test-features.bat` is the regression gate. There is no unit-test framework.

- Non-interactive; exits with 0/1/2.
- Forces `%SystemRoot%\System32` first on `PATH` and uses `ping -n N 127.0.0.1 >nul` as the sleep primitive. This is so the script runs cleanly from `cmd.exe` **and** from Git Bash / MSYS, where coreutils can shadow `timeout`/`findstr` and stdin-redirected `timeout.exe` fails outright.
- `waitHealthy` subroutine polls `docker inspect .State.Health.Status` with a 75 s budget.
- Profile tests start the specific profile service by name to dodge the base-service port race documented above.

## Releasing

1. Commit all changes to `main` (push happens with explicit user confirmation — the user has a global "no auto-push" rule).
2. `git tag -a vX.Y.Z -m "..."` and `git push origin vX.Y.Z`.
3. `gh release create vX.Y.Z SetupAcestream.bat --title "..." --notes "..."`.
4. Retag and push the Docker image to Hub.

Patch releases that only touch the setup script or docs can reuse the previous image digest — just retag `smarquezp/docker-acestream-ubuntu-home:vX.Y.Z` from the existing `:latest` and push.

## Related docs

- `README.md` / `README_es.md`: user-facing. Keep the two in sync.
- `AGENTS.md`: symlink to this file (for agents that look for that name by convention).
