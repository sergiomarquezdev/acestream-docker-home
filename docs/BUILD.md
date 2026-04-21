# Build Guide

## Base Image

`ubuntu:22.04` with Python 3.10.

## Build Strategy

The Dockerfile uses a multi-stage build:

1. **Builder stage** (`ubuntu:22.04 AS builder`): installs the build toolchain and compiles native Python modules (`lxml`, `apsw`, etc.) to `/install`.
2. **Runtime stage** (`ubuntu:22.04`): copies only the compiled packages and installs runtime-only libraries (`libxml2`, `libxslt1.1`, `libsqlite3-0`).

Previously, a single-stage build with an in-layer purge was used. The multi-stage approach was adopted because it completely removes the build toolchain from the final image history (not just from the layer content), reducing the attack surface. Image size remains approximately the same (~729 MB) because Ubuntu runtime libraries must still be installed in the final stage.

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

~729 MB. The build toolchain is completely absent from the final image history thanks to the multi-stage build.
