# Architecture

## Startup Flow

1. Docker starts the container with `ENTRYPOINT ["/usr/bin/tini", "-g", "--", "/entrypoint.sh"]`.
2. `entrypoint.sh` validates `HTTP_PORT` and `HTTPS_PORT`.
3. The engine starts via `/opt/acestream/start-engine` with configured ports and flags.
4. Docker `HEALTHCHECK` begins polling after a 40-second start period.

## Why tini?

The engine ignores SIGTERM when it runs as PID 1, so `docker stop` would always wait for the full timeout and then SIGKILL it. tini runs as PID 1 and, with `-g`, forwards the signal to the whole process group (`start-engine` is a `sh` wrapper that does not `exec`, so the engine is a grandchild).

## Player URLs

`player.html` is served by the engine itself and requests streams with a same-origin path (`/ace/manifest.m3u8?...`). It works for any host, IP or port without runtime patching.

## Cache Profiles

| Profile | Storage | Platform | Command |
|---------|---------|----------|---------|
| default | Disk | All | `docker compose up -d` |
| ram | tmpfs (8GB) | Linux/WSL2 | `docker compose --profile ram up -d acestream-ram` |
| memory | RAM (auto) | All | `docker compose --profile memory up -d acestream-memory` |

**Note on port conflict:** The commands above name the specific service (e.g., `acestream-memory`) so only that service starts. If you run `docker compose --profile memory up -d` without naming the service, Docker Compose starts both the base and the profile service; they race for port 6878 and one fails with "port already allocated".

## Why `HTTPS_PORT` is not `EXPOSE`d

`--https-port ${HTTPS_PORT}` is passed to `start-engine` (and `HTTPS_PORT` is validated in `entrypoint.sh`), but the Dockerfile only `EXPOSE`s `6878`, and `docker-compose.yml` only publishes `HTTP_PORT` (default `6878`). This is intentional, not an oversight:

The engine's own `--help` (`acestreamengine --client-console --help`) shows that HTTPS is gated behind `--ssl-certificate` / `--ssl-certificate-key`:

```
--https-port HTTPS_PORT
                      https port
...
--ssl-certificate SSL_CERTIFICATE
                      Path to SSL certificate in PEM format
--ssl-certificate-key SSL_CERTIFICATE_KEY
                      Path to SSL private key in PEM format
```

Neither flag is set in `config/acestream.conf` (there is no certificate bundled or mounted), and verified empirically: with the current config, only port 6878 is ever bound (confirmed in the startup log — `acestream.httpserver|start: bound on ('0.0.0.0', 6878)` — nothing similar for 6879), and a direct connect to `127.0.0.1:6879` inside the container returns `ECONNREFUSED`. `--https-port` without a certificate is effectively inert on this build: there is nothing listening to publish. `HTTPS_PORT` stays wired through `entrypoint.sh` and `start-engine` so that supplying a certificate in the future (mounting a cert/key and setting the two SSL flags) doesn't require touching the entrypoint — only the compose file and `acestream.conf` would need to add the certificate paths and the `EXPOSE`/port mapping.

## Log verbosity and rotation

`config/acestream.conf` uses `--log-stdout` with an explicit `--log-stdout-level info` (see inline comments in that file for the measurement backing this choice). A previous `--log-debug 355` setting was removed: it is not a flag the 3.2.11 engine recognizes, and it had no measurable effect (the startup log always reports `set debug level: 0` regardless of its value) — dead configuration, not a working verbosity knob.

Log rotation is deliberately **not** configured at the engine level (no `--log-file`, `--log-max-size`, `--log-backup-count`): logging to stdout lets Docker's own logging driver (`json-file` by default, with its own `max-size`/`max-file` limits configurable at the daemon or container level) own rotation. Configuring both would just be two rotation policies fighting each other.

## OCI image labels

The runtime stage carries standard `org.opencontainers.image.*` labels (`source`, `title`, `description`, `licenses`, `version`) alongside the pre-existing `maintainer` label. `maintainer` is kept unchanged because `SetupAcestream.bat` matches on it to prune obsolete local images — removing or renaming it would break that cleanup path. See `docs/BUILD.md` for the full label list and the version-pinning/LFS/architecture rationale.

## CI/CD

- `.github/workflows/ci.yml` builds and smoke-tests every push/PR to `main` (lint → build → health → version/player assertions → graceful-stop assertion).
- `.github/workflows/release.yml` publishes to Docker Hub and attaches `SetupAcestream.bat` to the GitHub Release on `v*` tags.
- `.github/dependabot.yml` keeps `requirements.txt`, the `Dockerfile` base images, and the GitHub Actions themselves on a weekly update cadence.

See `docs/BUILD.md` for the detailed rationale behind each of these.
