# Testing

## Smoke Tests

Run from the repo root with Docker Desktop already running:

```bash
cmd.exe /c tests\test-features.bat
```

### What it tests

1. **Default profile:** starts the container, waits for healthy (max 75s), verifies API returns version `3.2.11`.
2. **Memory profile:** starts `acestream-memory`, verifies logs contain `--live-cache-type memory`.
3. **RAM profile:** starts `acestream-ram`, verifies `df -h` output contains `ACEStream`. Skipped if WSL2 is not detected.

### Exit Codes

- `0` — all passed (or skipped due to missing WSL2)
- `1` — at least one test failed
- `2` — environment not ready (Docker down or image unavailable)

### Compatibility Notes

The script uses `ping -n 3 127.0.0.1` as a sleep primitive instead of `timeout.exe` so it works correctly when invoked from Git Bash / MSYS with redirected stdin.
