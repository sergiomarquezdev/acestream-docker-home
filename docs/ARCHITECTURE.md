# Architecture

## Startup Flow

1. Docker starts the container with `ENTRYPOINT ["/entrypoint.sh"]`.
2. `entrypoint.sh` validates `INTERNAL_IP`, `HTTP_PORT`, `HTTPS_PORT`.
3. If present, `player.html` is patched via `sed` to point to `${INTERNAL_IP}:${HTTP_PORT}`.
4. The engine starts via `/opt/acestream/start-engine` with configured ports and flags.
5. Docker `HEALTHCHECK` begins polling after a 40-second start period.

## Why sed on player.html?

The internal IP is not known at build time; it is only known at container startup. The entrypoint injects it dynamically.

## Cache Profiles

| Profile | Storage | Platform | Command |
|---------|---------|----------|---------|
| default | Disk | All | `docker-compose up -d` |
| ram | tmpfs (8GB) | Linux/WSL2 | `docker-compose --profile ram up -d acestream-ram` |
| memory | RAM (auto) | All | `docker-compose --profile memory up -d acestream-memory` |

**Note on port conflict:** When using `--profile`, Docker Compose starts both the base service and the profile service. Both compete for port 6878; the base fails (expected) and only the profile container remains active.
