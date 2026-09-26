# Build Guide

## Base Image

`ubuntu:22.04` with Python 3.10. This is a hard constraint: the engine tarball bundles `cp310`-only wheels and links `libpython3.10`. Moving to a newer Ubuntu (with Python 3.11/3.12 as the default `python3`) would require Acestream to ship a matching wheel set, which is outside this repo's control — the tarball is upstream's binary, not something we rebuild.

## Architecture: x86_64 only

The bundled `resources/acestream.tar.gz` is upstream's **Linux x86_64** build; there is no arm64 (or any other architecture) release of Acestream Engine 3.2.11. Verified directly against the extracted tarball:

```bash
$ file acestreamengine
acestreamengine: ELF 64-bit LSB pie executable, x86-64, version 1 (SYSV), dynamically linked, ...
```

The `.whl` files bundled in `lib/` (e.g. `aiohttp-3.9.5-cp310-cp310-manylinux_2_17_x86_64...`) confirm the same: every compiled wheel targets `x86_64`. Because the constraint is in upstream's closed-source binary, this image cannot be built for arm64/Apple Silicon — there's no arm64 wheel or binary to link against, and the maintainer does not build one.

## Build Strategy

The Dockerfile uses a multi-stage build:

1. **Builder stage** (`ubuntu:22.04 AS builder`): installs the build toolchain and compiles native Python modules into `/install`, pinned in [`requirements.txt`](../requirements.txt) and installed via `pip install -r requirements.txt`.
2. **Runtime stage** (`ubuntu:22.04`): copies only the compiled packages and installs runtime-only packages (`python3`, `libxml2`, `libxslt1.1`, `libsqlite3-0`, `tini`, ...). `pip`, `setuptools`, `wheel` and `wget` are not installed: the engine does not use them at runtime.

The build toolchain never reaches the final image history, reducing the attack surface.

## Native Python dependencies (`requirements.txt`)

`requirements.txt` pins the exact versions of the native/compiled modules the engine needs (`apsw`, `lxml`, `PyNaCl`, `requests`, `pycryptodome`, `isodate`). Current pins, and what changed in the latest bump:

| Package | Before | Now | Notes |
|---|---|---|---|
| `apsw` | 3.46.0.0 | 3.53.4.0 | ships a `manylinux_2_28_x86_64` cp310 wheel; glibc 2.35 (Ubuntu 22.04) satisfies `manylinux_2_28` |
| `lxml` | 5.2.2 | 6.1.3 | `manylinux_2_28`/`manylinux2014` cp310 wheel |
| `pycryptodome` | 3.20.0 | 3.23.0 | `cp37-abi3` wheel (stable ABI, works unmodified on cp310) |
| `isodate` | 0.6.1 | 0.7.2 | pure-Python, `py3-none-any` |
| `PyNaCl` | 1.6.2 | 1.6.2 (unchanged — already latest at bump time) | `cp38-abi3` wheel |
| `requests` | 2.34.2 | 2.34.2 (unchanged — already latest at bump time) | pure-Python, `py3-none-any` |

All six were verified compatible with cp310 / glibc 2.35 (Ubuntu 22.04) by checking each release's PyPI file list before bumping, and confirmed end-to-end after the bump: image builds, `import apsw, lxml, nacl, requests, Crypto, isodate` succeeds inside the container with the expected `__version__`s, the container reaches `healthy`, and a full `getstream` → `stat` (poll until `status=dl` with `downloaded>0`) → `manifest.m3u8` → `.ts` segment (first byte `0x47`, the MPEG-TS sync byte) round trip succeeds against a live stream.

To bump a pin: update `requirements.txt`, rebuild, and re-run the same import + stream checks before merging. If a bump breaks any of those checks, pin back to the last working version in `requirements.txt` and note why in the commit message — do not silently downgrade without a paper trail.

## Why apt packages are not version-pinned

The Dockerfile intentionally does **not** pin versions in `apt-get install` (flagged by `hadolint` as `DL3008`; both offending lines carry an inline `# hadolint ignore=DL3008` with this rationale next to them). Two reasons, both load-bearing:

1. **Ubuntu's archive only keeps the latest point release of each package.** A pin like `libssl3=3.0.2-0ubuntu1.10` breaks the very next time that package gets a security update, because the old `.deb` is gone from the mirror — not "eventually", but on whatever cadence Canonical ships patches. Pinning here would turn routine `apt-get update` runs into build failures on an unpredictable schedule.
2. **We want the security patches.** `libssl`, `libc6`, etc. get backported CVE fixes on the `22.04` track without a major version bump. Floating versions mean the image picks these up automatically on every rebuild; pinning would require a human to manually bump every apt pin on every rebuild, which does not scale and tends to just not happen.

The trade-off is accepted: a build today and a build next month may pull slightly different point releases of the same packages. This is normal for Ubuntu-based images and is mitigated by the CI build running on every push/PR (see `.github/workflows/ci.yml`) — if a package update breaks something, CI catches it before it reaches `main`.

## Why `resources/acestream.tar.gz` is not in Git LFS

The tarball (~77 MB) is committed directly to the repository, not tracked via Git LFS. Deliberate:

- **It rarely changes.** Acestream Engine releases new versions infrequently (this repo tracks 3.2.11); the tarball is replaced maybe once or twice a year, not on every commit. LFS earns its complexity for files that churn — this one doesn't.
- **LFS bandwidth is a real constraint on a free/personal GitHub plan.** GitHub's free LFS bandwidth quota is small (1 GiB/month at the time of writing) and is consumed by every `git clone`/`git fetch` that touches the LFS pointer, including CI checkouts. A single CI run per push would burn through the quota in days, turning "clone the repo" into "clone the repo, except sometimes it 429s until next month." A regular blob has no such quota.
- **Migrating existing history into LFS is destructive.** `git lfs migrate` rewrites every commit that ever touched the tarball, forcing a force-push and invalidating every existing clone, fork, and open PR. That's a disproportionate one-time cost to pay for a file that doesn't churn and isn't hitting any real storage/clone-time problem today.

If the tarball's size or update frequency changes materially in the future, this trade-off should be revisited — but as of this writing, plain Git is the simpler and cheaper option.

## SHA256 Integrity Check

The bundled `resources/acestream.tar.gz` is bind-mounted into the build step (so it is not stored in any image layer) and verified before extraction:

```dockerfile
ARG ACESTREAM_SHA256=9b6bbd76a55e5a434641afae3b9cf8e6154ce1cf392152ec3aed5ac265432b2e
RUN --mount=type=bind,source=resources/acestream.tar.gz,target=/tmp/acestream.tar.gz \
    bash -o pipefail -c ' \
      echo "${ACESTREAM_SHA256}  /tmp/acestream.tar.gz" | sha256sum --check \
      && ... \
    '
```

The check runs under `bash -o pipefail` (rather than the default `/bin/sh`/dash) specifically so a failure in the `echo | sha256sum` pipe can't be masked by a downstream exit code (`hadolint` `DL4006`).

`RUN --mount` requires BuildKit, the default builder in Docker Desktop and Docker Engine 23+.

To update Acestream: replace the tarball, compute the new SHA256, and pass it as a build argument:

```bash
docker build --build-arg ACESTREAM_SHA256=<new-hash> -t acestream-engine .
```

## OCI image labels

The runtime stage sets both the pre-existing `maintainer` label (kept as-is — `SetupAcestream.bat` prunes obsolete local images by matching on it) and standard [OCI image labels](https://github.com/opencontainers/image-spec/blob/main/annotations.md):

- `org.opencontainers.image.source` → `https://github.com/sergiomarquezdev/acestream-docker-home`
- `org.opencontainers.image.title`, `.description`, `.licenses` (`MIT`, matching `LICENSE`)
- `org.opencontainers.image.version`, driven by the `IMAGE_VERSION` build arg (defaults to `3.2.11`, the bundled engine version)

## Offline Builds

The Acestream tarball (`resources/acestream.tar.gz`) is bundled in the repository. If you have already built the base image or have the Ubuntu packages cached, the build does not need to download the engine binary from the internet.

## CI/CD

- **`.github/workflows/ci.yml`** (push + PR to `main`): lints `config/entrypoint.sh` with `shellcheck` and the `Dockerfile` with `hadolint`, then builds the image with `docker buildx` (GHA layer cache), runs it, waits for `healthy` (≤90s), asserts `get_version` reports `3.2.11` and `/webui/player/` returns `200`, and asserts `docker stop` completes in under 10s with exit code `0` or `143`.
- **`.github/workflows/release.yml`** (tags `v*`): builds and pushes `smarquezp/docker-acestream-ubuntu-home:<tag>` and `:latest` to Docker Hub, but only when the `DOCKERHUB_USERNAME`/`DOCKERHUB_TOKEN` repo secrets are configured — otherwise it emits a `::notice::` and skips the publish step instead of failing. It then uploads `SetupAcestream.bat` to the matching GitHub Release for that tag, if one exists (`gh release upload --clobber`).
- **`.github/dependabot.yml`**: weekly update checks for `pip` (`requirements.txt`), `docker` (`Dockerfile` base images), and `github-actions`, each grouped so minor/patch bumps land as a single PR instead of one per package.

The CI `lint` job runs shellcheck (`config/entrypoint.sh`), hadolint (`Dockerfile`) and actionlint (`.github/workflows/*.yml`) on every push and pull request.

## Image Size

~541 MB, down from 730 MB in v8.2.0: no pip/setuptools/wheel/wget at runtime and the engine tarball bind-mounted instead of `COPY`'d (a `COPY` + `rm` still leaves the 77 MB archive in its own layer). The vendored video.js adds under 1 MB.
