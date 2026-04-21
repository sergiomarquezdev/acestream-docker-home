# Build Guide

## Base Image

`ubuntu:22.04` with Python 3.10.

## Single-stage Build

The Dockerfile uses a single heavy RUN layer that:
1. Installs runtime dependencies plus the build toolchain
2. Compiles native Python modules (`lxml`, `apsw`, etc.)
3. Purges the build toolchain
4. Reinstalls runtime-only libraries (`libxml2`, `libxslt1.1`, `libsqlite3-0`)

This was a conscious choice: Ubuntu + apt-get make multi-stage builds complex because runtime libraries must be reinstalled in the final stage anyway.

## SHA256 Integrity Check

The bundled `resources/acestream.tar.gz` is verified at build time:

```dockerfile
ARG ACESTREAM_SHA256=9b6bbd76a55e5a434641afae3b9cf8e6154ce1cf392152ec3aed5ac265432b2e
RUN echo "${ACESTREAM_SHA256}  /tmp/acestream.tar.gz" | sha256sum --check
```

To update Acestream: replace the tarball, compute the new SHA256, and pass it as a build argument:

```bash
docker build --build-arg ACESTREAM_SHA256=<new-hash> -t acestream-engine .
```

## Offline Builds

The Acestream tarball (`resources/acestream.tar.gz`) is bundled in the repository. If you have already built the base image or have the Ubuntu packages cached, the build does not need to download the engine binary from the internet.

## Image Size

~729 MB (down from 1.19 GB after purging the build toolchain).
