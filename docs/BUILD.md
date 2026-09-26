# Build Guide

## Base Image

`ubuntu:22.04` with Python 3.10. This is a hard constraint: the engine tarball bundles `cp310`-only wheels and links `libpython3.10`.

## Build Strategy

The Dockerfile uses a multi-stage build:

1. **Builder stage** (`ubuntu:22.04 AS builder`): installs the build toolchain and compiles native Python modules (`lxml`, `apsw`, etc.) to `/install`.
2. **Runtime stage** (`ubuntu:22.04`): copies only the compiled packages and installs runtime-only packages (`python3`, `libxml2`, `libxslt1.1`, `libsqlite3-0`, `tini`, ...). `pip`, `setuptools`, `wheel` and `wget` are not installed: the engine does not use them at runtime.

The build toolchain never reaches the final image history, reducing the attack surface.

## SHA256 Integrity Check

The bundled `resources/acestream.tar.gz` is bind-mounted into the build step (so it is not stored in any image layer) and verified before extraction:

```dockerfile
ARG ACESTREAM_SHA256=9b6bbd76a55e5a434641afae3b9cf8e6154ce1cf392152ec3aed5ac265432b2e
RUN --mount=type=bind,source=resources/acestream.tar.gz,target=/tmp/acestream.tar.gz \
    echo "${ACESTREAM_SHA256}  /tmp/acestream.tar.gz" | sha256sum --check && ...
```

`RUN --mount` requires BuildKit, the default builder in Docker Desktop and Docker Engine 23+.

To update Acestream: replace the tarball, compute the new SHA256, and pass it as a build argument:

```bash
docker build --build-arg ACESTREAM_SHA256=<new-hash> -t acestream-engine .
```

## Offline Builds

The Acestream tarball (`resources/acestream.tar.gz`) is bundled in the repository. If you have already built the base image or have the Ubuntu packages cached, the build does not need to download the engine binary from the internet.

## Image Size

~546 MB.
