@echo off
REM ===============================================
REM Testing Script for Acestream Docker
REM Tests all new features
REM ===============================================

echo ================================================
echo   ACESTREAM DOCKER - TESTING PLAN
echo ================================================
echo.

REM === TEST 1: Verify built image ===
echo [TEST 1] Verifying local built image...
docker images acestream-engine:latest
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Image acestream-engine:latest not found
    echo Please run: docker build -t acestream-engine:latest .
    pause
    exit /b 1
)
echo OK - Image found
echo.

REM === TEST 2: DEFAULT Profile (Disk) - Backward Compatibility ===
echo [TEST 2] Testing DEFAULT Profile (disk cache)...
echo Starting container with docker-compose up -d...
docker-compose up -d

echo Waiting 50 seconds for Acestream to start and healthcheck to run...
timeout /t 50 /nobreak

echo Verifying container status...
docker ps -a --filter "name=acestream-engine" --format "table {{.Names}}\t{{.Status}}"

echo.
echo Verifying healthcheck (should show 'healthy' or 'health: starting')...
docker inspect acestream-engine --format "{{.State.Health.Status}}"

echo.
echo Verifying logs for errors...
docker logs acestream-engine --tail 30

echo.
echo Testing API endpoint...
curl -s "http://127.0.0.1:6878/webui/api/service?method=get_version"

echo.
echo.
echo TEST 2 completed. Press any key to stop and continue...
pause

docker-compose down
timeout /t 5 /nobreak
echo.

REM === TEST 3: RAM Profile (tmpfs) ===
echo [TEST 3] Testing RAM Profile (tmpfs 8GB)...
echo NOTE: This test requires WSL2 or Linux
echo Starting container with --profile ram...
docker-compose --profile ram up -d

echo Waiting 50 seconds...
timeout /t 50 /nobreak

echo Verifying status...
docker ps -a --filter "name=acestream-engine-ram" --format "table {{.Names}}\t{{.Status}}"

echo.
echo Verifying healthcheck...
docker inspect acestream-engine-ram --format "{{.State.Health.Status}}"

echo.
echo Verifying that tmpfs is mounted...
docker exec acestream-engine-ram df -h | findstr "ACEStream"

echo.
echo TEST 3 completed. Press any key to stop and continue...
pause

docker-compose down
timeout /t 5 /nobreak
echo.

REM === TEST 4: MEMORY Profile (native cross-platform flag) ===
echo [TEST 4] Testing MEMORY Profile (native flag --live-cache-type memory)...
echo Starting container with --profile memory...
docker-compose --profile memory up -d

echo Waiting 50 seconds...
timeout /t 50 /nobreak

echo Verifying status...
docker ps -a --filter "name=acestream-engine-memory" --format "table {{.Names}}\t{{.Status}}"

echo.
echo Verifying healthcheck...
docker inspect acestream-engine-memory --format "{{.State.Health.Status}}"

echo.
echo Verifying logs to confirm --live-cache-type memory flag...
docker logs acestream-engine-memory | findstr "live-cache-type memory"
docker logs acestream-engine-memory | findstr "Extra Flags"

echo.
echo TEST 4 completed. Press any key to stop...
pause

docker-compose down
echo.

REM === SUMMARY ===
echo ================================================
echo   TESTING COMPLETED
echo ================================================
echo.
echo Review the results above:
echo.
echo [TEST 1] Local image: OK
echo [TEST 2] Default profile (disk): Review status/healthcheck
echo [TEST 3] RAM profile (tmpfs): Review if tmpfs is mounted
echo [TEST 4] Memory profile (flag): Review if flag appears in logs
echo.
echo ================================================
pause
