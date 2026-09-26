@echo off
SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

REM ===============================================
REM Automated smoke test for Acestream Docker.
REM Non-interactive: no user prompts, safe for CI-style runs.
REM Run from the repo root with Docker Desktop already running.
REM
REM Honours ACESTREAM_IMAGE to test a local build, e.g.:
REM   set ACESTREAM_IMAGE=acestream-engine:latest
REM   tests\test-features.bat
REM Defaults to the published Docker Hub image when unset.
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

REM Fixed Compose project name so the network name does not depend on the
REM folder the repo was cloned into (cleanup below removes it by name).
set "COMPOSE_PROJECT_NAME=acestream-smoke"

if defined ACESTREAM_IMAGE (
    set "IMAGE=%ACESTREAM_IMAGE%"
) else (
    set "IMAGE=smarquezp/docker-acestream-ubuntu-home:latest"
)
set "WAIT_HEALTHY=75"
set "PASS=0"
set "FAIL=0"
set "SKIP=0"

echo ================================================
echo   ACESTREAM DOCKER - SMOKE TEST
echo   Image under test: !IMAGE!
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
for /f "usebackq delims=" %%N in (`docker ps -a --format "{{.Names}}" 2^>nul ^| findstr /B /I "acestream-engine_"`) do (
    docker stop %%N >nul 2>&1
    docker rm %%N -f >nul 2>&1
)
del /f /q "%~dp0..\acestream-compose.yml" >nul 2>&1

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
REM TEST 4 - graceful stop (tini as PID 1 forwards SIGTERM)
REM ===============================================
echo [TEST 4] graceful stop ^(docker stop ^< 10s, exit code 143 or 0^)
docker-compose up -d
if !errorlevel! neq 0 goto :t4_fail

call :waitHealthy acestream-engine
if !errorlevel! neq 0 goto :t4_fail

set "STOP_SECONDS="
for /f "usebackq delims=" %%R in (`powershell -NoProfile -Command "$sw=[Diagnostics.Stopwatch]::StartNew(); docker stop acestream-engine | Out-Null; $sw.Stop(); [int][Math]::Ceiling($sw.Elapsed.TotalSeconds)" 2^>nul`) do set "STOP_SECONDS=%%R"
if not defined STOP_SECONDS goto :t4_fail
if !STOP_SECONDS! geq 10 goto :t4_fail

set "STOP_EXITCODE="
for /f "usebackq delims=" %%R in (`docker inspect acestream-engine --format "{{.State.ExitCode}}" 2^>nul`) do set "STOP_EXITCODE=%%R"
if "!STOP_EXITCODE!"=="143" goto :t4_pass
if "!STOP_EXITCODE!"=="0" goto :t4_pass
goto :t4_fail

:t4_pass
echo    [PASS] stopped in !STOP_SECONDS!s with exit code !STOP_EXITCODE!
set /a PASS+=1
goto :t4_end
:t4_fail
echo    [FAIL] stop took too long or exited with an unexpected code (STOP_SECONDS=!STOP_SECONDS! STOP_EXITCODE=!STOP_EXITCODE!)
set /a FAIL+=1
:t4_end
docker-compose down >nul 2>&1
echo.

REM ===============================================
REM TEST 5 - player served same-origin (no baked-in 127.0.0.1:6878)
REM ===============================================
echo [TEST 5] player served at /webui/player/ is same-origin
docker-compose up -d
if !errorlevel! neq 0 goto :t5_fail

call :waitHealthy acestream-engine
if !errorlevel! neq 0 goto :t5_fail

REM The page must load its script and video.js locally (no CDN), and the
REM script must request the stream with a same-origin path.
curl -s "http://127.0.0.1:6878/webui/player/" > "%TEMP%\acestream_player_test.html" 2>nul
curl -s "http://127.0.0.1:6878/webui/html/player.js" > "%TEMP%\acestream_player_test.js" 2>nul
findstr /C:"/webui/html/player.js" "%TEMP%\acestream_player_test.html" >nul
if !errorlevel! neq 0 goto :t5_fail_cleanup
findstr /C:"/webui/vendor/videojs/video.min.js" "%TEMP%\acestream_player_test.html" >nul
if !errorlevel! neq 0 goto :t5_fail_cleanup
findstr /C:"cdn.jsdelivr.net" "%TEMP%\acestream_player_test.html" >nul
if !errorlevel! == 0 goto :t5_fail_cleanup
findstr /C:"/ace/manifest.m3u8" "%TEMP%\acestream_player_test.js" >nul
if !errorlevel! neq 0 goto :t5_fail_cleanup
findstr /C:"127.0.0.1:6878" "%TEMP%\acestream_player_test.html" "%TEMP%\acestream_player_test.js" >nul
if !errorlevel! == 0 goto :t5_fail_cleanup

echo    [PASS] player uses local assets and same-origin /ace/manifest.m3u8, no baked-in 127.0.0.1:6878
set /a PASS+=1
del /f /q "%TEMP%\acestream_player_test.html" "%TEMP%\acestream_player_test.js" >nul 2>&1
goto :t5_end
:t5_fail_cleanup
del /f /q "%TEMP%\acestream_player_test.html" "%TEMP%\acestream_player_test.js" >nul 2>&1
:t5_fail
echo    [FAIL] see '%TEMP%\acestream_player_test.html' (deleted) or 'docker logs acestream-engine'
set /a FAIL+=1
:t5_end
docker-compose down >nul 2>&1
echo.

REM ===============================================
REM TEST 6 - SetupAcestream.bat --unattended end-to-end (run twice)
REM ===============================================
echo [TEST 6] SetupAcestream.bat --unattended, run twice ^(single container^)
call "%~dp0..\SetupAcestream.bat" --unattended --lang=en
set "T6_ERR1=!errorlevel!"
if not "!T6_ERR1!"=="0" goto :t6_fail

set "T6_CONTAINER="
for /f "usebackq delims=" %%N in (`docker ps -a --format "{{.Names}}" 2^>nul ^| findstr /B /I "acestream-engine_"`) do (
    if not defined T6_CONTAINER set "T6_CONTAINER=%%N"
)
if not defined T6_CONTAINER goto :t6_fail

call :waitHealthy !T6_CONTAINER!
if !errorlevel! neq 0 goto :t6_fail

call "%~dp0..\SetupAcestream.bat" --unattended --lang=en
set "T6_ERR2=!errorlevel!"
if not "!T6_ERR2!"=="0" goto :t6_fail

set "T6_COUNT=0"
for /f "usebackq delims=" %%N in (`docker ps -a --format "{{.Names}}" 2^>nul ^| findstr /B /I "acestream-engine_"`) do set /a T6_COUNT+=1
if not "!T6_COUNT!"=="1" goto :t6_fail

echo    [PASS] exactly one acestream-engine_* container after two runs
set /a PASS+=1
goto :t6_end
:t6_fail
echo    [FAIL] see 'docker ps -a' ^(expected exactly one acestream-engine_* container^)
set /a FAIL+=1
:t6_end
for /f "usebackq delims=" %%N in (`docker ps -a --format "{{.Names}}" 2^>nul ^| findstr /B /I "acestream-engine_"`) do (
    docker stop %%N >nul 2>&1
    docker rm %%N -f >nul 2>&1
)
del /f /q "%~dp0..\acestream-compose.yml" >nul 2>&1
docker network rm %COMPOSE_PROJECT_NAME%_default >nul 2>&1
echo.

REM ===============================================
REM TEST 7 - SetupAcestream.bat skips a port that is really in use
REM ===============================================
REM A foreign listener on 6878 must push the script to 6880. (Client/TIME_WAIT
REM connections to 6878 left by earlier tests must NOT count as "in use".)
echo [TEST 7] SetupAcestream.bat picks the next port when 6878 is taken
docker run -d --name acestream-port-blocker -p 6878:6878 !IMAGE! >nul 2>&1
if !errorlevel! neq 0 goto :t7_fail

call "%~dp0..\SetupAcestream.bat" --unattended --lang=en
if !errorlevel! neq 0 goto :t7_fail

docker inspect acestream-engine_6880 >nul 2>&1
if !errorlevel! neq 0 goto :t7_fail
call :waitHealthy acestream-engine_6880
if !errorlevel! neq 0 goto :t7_fail

echo    [PASS] port 6878 busy, deployed acestream-engine_6880
set /a PASS+=1
goto :t7_end
:t7_fail
echo    [FAIL] see 'docker ps -a' ^(expected acestream-engine_6880 while 6878 is taken^)
set /a FAIL+=1
:t7_end
docker rm -f acestream-port-blocker >nul 2>&1
for /f "usebackq delims=" %%N in (`docker ps -a --format "{{.Names}}" 2^>nul ^| findstr /B /I "acestream-engine_"`) do (
    docker rm %%N -f >nul 2>&1
)
del /f /q "%~dp0..\acestream-compose.yml" >nul 2>&1
docker network rm %COMPOSE_PROJECT_NAME%_default >nul 2>&1
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
