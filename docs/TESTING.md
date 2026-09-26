# Testing

## Smoke Tests

Run from the repo root with Docker Desktop already running.

`cmd.exe`:

```bat
tests\test-features.bat
```

PowerShell:

```powershell
.\tests\test-features.bat
```

To test a local build instead of the published Docker Hub image, set `ACESTREAM_IMAGE`
before running (the script also skips `pull` for a locally-present override):

```bat
docker build -t acestream-engine:latest .
set ACESTREAM_IMAGE=acestream-engine:latest
tests\test-features.bat
```

```powershell
docker build -t acestream-engine:latest .
$env:ACESTREAM_IMAGE = "acestream-engine:latest"
.\tests\test-features.bat
```

CI (`.github/workflows/ci.yml`) runs the Linux-side equivalent on every push and pull request: shellcheck, hadolint, actionlint, build, health, version, player and graceful-stop checks.

### What it tests

1. **Default profile:** starts the container, waits for healthy (max 75s), verifies API returns version `3.2.11`.
2. **Memory profile:** starts `acestream-memory`, verifies logs contain `--live-cache-type memory`.
3. **RAM profile:** starts `acestream-ram`, verifies `df -h` output contains `ACEStream`. Skipped if WSL2 is not detected.
4. **Graceful stop:** starts the default profile, waits for healthy, then runs `docker stop` and asserts it completes in under 10s with the container exit code being `143` (SIGTERM) or `0`. Verifies tini (PID 1) forwards the stop signal correctly.
5. **Same-origin player:** fetches `/webui/player/`, asserts the HTML references `/ace/manifest.m3u8` (same-origin) and does **not** contain a baked-in `127.0.0.1:6878` absolute URL.
6. **SetupAcestream.bat end-to-end:** runs `SetupAcestream.bat --unattended --lang=en` twice in a row (honouring `ACESTREAM_IMAGE`) and asserts there is exactly one `acestream-engine_*` container afterwards, proving the "reuse existing container" logic prevents port/container duplication on re-run.

### Exit Codes

- `0` — all passed (or skipped due to missing WSL2)
- `1` — at least one test failed
- `2` — environment not ready (Docker down or image unavailable)

### Compatibility Notes

The script uses `ping -n 3 127.0.0.1` as a sleep primitive instead of `timeout.exe` so it works correctly when invoked from Git Bash / MSYS with redirected stdin. `SetupAcestream.bat` follows the same convention for its own delays (e.g. before opening the browser).

Test 6 exercises `SetupAcestream.bat` itself with `--unattended`, which skips all prompts, pauses and the browser launch — see the script's header comment for the full flag list.
