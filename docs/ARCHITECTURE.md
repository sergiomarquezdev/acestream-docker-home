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
| default | Disk | All | `docker-compose up -d` |
| ram | tmpfs (8GB) | Linux/WSL2 | `docker-compose --profile ram up -d acestream-ram` |
| memory | RAM (auto) | All | `docker-compose --profile memory up -d acestream-memory` |

**Note on port conflict:** The commands above name the specific service (e.g., `acestream-memory`) so only that service starts. If you run `docker-compose --profile memory up -d` without naming the service, Docker Compose starts both the base and the profile service; they race for port 6878 and one fails with "port already allocated".
