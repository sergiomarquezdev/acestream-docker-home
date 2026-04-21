@echo off
SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

REM ===============================================
REM Automated smoke test for Acestream Docker.
REM Non-interactive: no user prompts, safe for CI-style runs.
REM Run from the repo root with Docker Desktop already running.
REM
REM Exit codes:
REM   0 - all tests passed (or skipped because of missing WSL2)
REM   1 - at least one test failed
REM   2 - environment is not ready (Docker down, image unavailable)
REM ===============================================

REM Prepend Windows System32 so we always get the Windows 'timeout' and
REM 'findstr' binaries, even when invoked from a POSIX shell (MSYS / Git
REM Bash) where coreutils may shadow them.
set "PATH=%SystemRoot%\System32;%SystemRoot%;%PATH%"

set "IMAGE=smarquezp/docker-acestream-ubuntu-home:latest"
set "WAIT_HEALTHY=75"
set "PASS=0"
set "FAIL=0"
set "SKIP=0"

echo ================================================
echo   ACESTREAM DOCKER - SMOKE TEST
echo ================================================
echo.

REM === PRE-FLIGHT: Docker daemon ===
docker info >nul 2>&1
if !errorlevel! neq 0 (
    echo [FATAL] Docker is not running. Start Docker Desktop and retry.
    exit /b 2
)

REM === PRE-FLIGHT: image available locally or pullable ===
echo [PRE ] Checking that image !IMAGE! is reachable...
docker image inspect !IMAGE! >nul 2>&1
if !errorlevel! neq 0 (
    echo [PRE ] Image not present locally, pulling...
    docker pull !IMAGE!
    if !errorlevel! neq 0 (
        echo [FATAL] Cannot pull !IMAGE!. Build it with 'docker build -t !IMAGE! .' first.
        exit /b 2
    )
)
echo [PRE ] Image OK.

REM === Detect WSL (needed for the tmpfs-based 'ram' profile) ===
wsl --status >nul 2>&1
if !errorlevel! == 0 (
    set "HAS_WSL=true"
) else (
    set "HAS_WSL=false"
)
echo [PRE ] WSL detected: !HAS_WSL!
echo.

REM === Ensure a clean slate ===
docker-compose --profile ram --profile memory down --remove-orphans >nul 2>&1

REM ===============================================
REM TEST 1 - default profile (disk cache)
REM ===============================================
echo [TEST 1] default profile (disk cache)
docker-compose up -d
if !errorlevel! neq 0 goto :t1_fail

call :waitHealthy acestream-engine
if !errorlevel! neq 0 goto :t1_fail

curl -s "http://127.0.0.1:6878/webui/api/service?method=get_version" | findstr /C:"3.2.11" >nul
if !errorlevel! neq 0 goto :t1_fail

echo    [PASS] container healthy and API reports 3.2.11
set /a PASS+=1
goto :t1_end
:t1_fail
echo    [FAIL] see 'docker logs acestream-engine'
set /a FAIL+=1
:t1_end
docker-compose down >nul 2>&1
echo.

REM ===============================================
REM TEST 2 - memory profile (native --live-cache-type memory)
REM ===============================================
echo [TEST 2] memory profile (native flag, cross-platform)
docker-compose --profile memory up -d acestream-memory
if !errorlevel! neq 0 goto :t2_fail

call :waitHealthy acestream-engine-memory
if !errorlevel! neq 0 goto :t2_fail

docker logs acestream-engine-memory 2>&1 | findstr /C:"--live-cache-type memory" >nul
if !errorlevel! neq 0 goto :t2_fail

echo    [PASS] container healthy and --live-cache-type memory present in logs
set /a PASS+=1
goto :t2_end
:t2_fail
echo    [FAIL] see 'docker logs acestream-engine-memory'
set /a FAIL+=1
:t2_end
docker-compose --profile memory down >nul 2>&1
echo.

REM ===============================================
REM TEST 3 - ram profile (tmpfs; needs Linux or WSL2)
REM ===============================================
echo [TEST 3] ram profile (tmpfs, Linux/WSL2 only)
if "!HAS_WSL!"=="false" (
    echo    [SKIP] WSL not detected; tmpfs requires Linux or WSL2
    set /a SKIP+=1
    goto :t3_end
)

docker-compose --profile ram up -d acestream-ram
if !errorlevel! neq 0 goto :t3_fail

call :waitHealthy acestream-engine-ram
if !errorlevel! neq 0 goto :t3_fail

docker exec acestream-engine-ram df -h | findstr "ACEStream" >nul
if !errorlevel! neq 0 goto :t3_fail

echo    [PASS] container healthy and tmpfs mounted at ACEStream cache
set /a PASS+=1
goto :t3_cleanup
:t3_fail
echo    [FAIL] see 'docker logs acestream-engine-ram'
set /a FAIL+=1
:t3_cleanup
docker-compose --profile ram down >nul 2>&1
:t3_end
echo.

REM ===============================================
REM SUMMARY
REM ===============================================
echo ================================================
echo   RESULT: !PASS! passed, !FAIL! failed, !SKIP! skipped
echo ================================================
if !FAIL! gtr 0 (
    endlocal
    exit /b 1
)
endlocal
exit /b 0

REM ===============================================
REM Subroutine: :waitHealthy <container-name>
REM Polls docker inspect until the container reports 'healthy'
REM or WAIT_HEALTHY seconds elapse.
REM ===============================================
:waitHealthy
set "CONTAINER=%~1"
set "ELAPSED=0"
:waitLoop
if !ELAPSED! geq !WAIT_HEALTHY! (
    echo    [health] !CONTAINER! did not become healthy within !WAIT_HEALTHY!s
    exit /b 1
)
for /f "usebackq" %%s in (`docker inspect !CONTAINER! --format "{{.State.Health.Status}}" 2^>nul`) do set "STATUS=%%s"
if /I "!STATUS!"=="healthy" exit /b 0
REM 'ping' is used as a sleep because 'timeout' refuses to run when stdin
REM is redirected (e.g. when the script is invoked from a POSIX shell).
ping -n 3 127.0.0.1 >nul 2>&1
set /a ELAPSED+=2
goto waitLoop
