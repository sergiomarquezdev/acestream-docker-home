@echo off
SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: -------------------------
:: Definition of constants for the script configuration.
:: -------------------------
set "IMAGE_NAME=smarquezp/docker-acestream-ubuntu-home:latest"
set "INTERNAL_IP=127.0.0.1"
set "PORT_BASE=6878"
set "SERVICE_NAME_BASE=acestream-engine_"
set "DOCKER_COMPOSE_FILE=docker-compose.yml"
set "PREFIX=acestream://"
set "HTTP_PORT_BASE=6878"
set "HTTPS_PORT_BASE=6879"
:: -------------------------
:: Parse command line arguments for optional flags
:: -------------------------
set "AUTO_CLEAN=false"
for %%A in (%*) do (
    if /I "%%A"=="--auto-clean" set "AUTO_CLEAN=true"
)
:: -------------------------
:: Checking for Docker installation and operational status.
:: -------------------------
:dockerCheck
echo Checking Docker...
docker --version >nul 2>&1 && docker info >nul 2>&1 || (
    echo ERROR: Docker not found or not active. Please install and start Docker to continue.
    start https://www.docker.com/get-started/
    pause
    goto dockerCheck
)
echo Docker successfully verified and ready for use.

:: -------------------------
:: Obtaining a non-loopback internal IP address.
:: -------------------------
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /C:"IPv4"') do (
    set "IP_TEMP=%%a"
    set "IP_TEMP=!IP_TEMP: =!"
    if "!IP_TEMP!" NEQ "127.0.0.1" (
        set "INTERNAL_IP=!IP_TEMP!"
        goto installAcestream
    )
)

:: -------------------------
:: Acestream and Docker configuration section.
:: -------------------------
:installAcestream
echo.
echo [Acestream Installation on Docker]
echo ----------------------------------------
echo Configuring the environment for Acestream...

:: Requesting the user to validate or modify the detected IP address.
echo.
echo Internal IP address verification...
echo Your current internal IP address is: %INTERNAL_IP%
echo If this is correct, press ENTER. Otherwise, enter the correct IP and press ENTER.
echo.
set /p USER_IP=Enter the IP or press ENTER if it is correct:
if not "%USER_IP%"=="" set "INTERNAL_IP=%USER_IP%"
echo Using IP: %INTERNAL_IP%

:: -------------------------
:: Dynamic port and service name assignment
:: -------------------------
set "PORT=%PORT_BASE%"
set "SERVICE_NAME=%SERVICE_NAME_BASE%%PORT%"
set "HTTP_PORT=%HTTP_PORT_BASE%"
set "HTTPS_PORT=%HTTPS_PORT_BASE%"

:checkPort
rem First, ensure the desired port is not already taken by another process (e.g., native Acestream Player)
netstat -ano | findstr /R /C:":!PORT!\>" >nul 2>&1
if !errorlevel! == 0 (
    echo Port !PORT! is already occupied by another application. Trying the next port...
    set /a "PORT+=2"
    set /a "HTTP_PORT+=2"
    set /a "HTTPS_PORT+=2"
    set "SERVICE_NAME=%SERVICE_NAME_BASE%!PORT!"
    goto checkPort
)

set CONTAINER_ID=
for /f "tokens=*" %%i in ('docker ps -q --filter "name=!SERVICE_NAME!"') do set CONTAINER_ID=%%i

if not defined CONTAINER_ID (
    set /a "HTTPS_PORT+=1"
    echo Using port !PORT!, HTTP port !HTTP_PORT!, HTTPS port !HTTPS_PORT!, and service name !SERVICE_NAME!.
) else (
    echo Port !PORT! is already in use. Trying the next port...
    set /a "PORT+=2"
    set /a "HTTP_PORT+=2"
    set /a "HTTPS_PORT+=2"
    set "SERVICE_NAME=%SERVICE_NAME_BASE%!PORT!"
    echo DEBUG: Now using port !PORT!, HTTP port !HTTP_PORT!, HTTPS port !HTTPS_PORT!, and service name !SERVICE_NAME!.
    goto checkPort
)

:: -------------------------
:: Creation or update of the docker-compose.yml file.
:: -------------------------
:startDocker
docker stop !SERVICE_NAME! >NUL 2>&1
docker rm !SERVICE_NAME! -f >NUL 2>&1
echo.
echo Creating or updating the docker-compose.yml file...
>%DOCKER_COMPOSE_FILE% (
    echo version: '3.8'
    echo services:
    echo   !SERVICE_NAME!:
    echo     image: !IMAGE_NAME!
    echo     container_name: !SERVICE_NAME!
    echo     restart: unless-stopped
    echo     ports:
    echo       - !PORT!:!PORT!
    echo     environment:
    echo       - INTERNAL_IP=!INTERNAL_IP!
    echo       - HTTP_PORT=!HTTP_PORT!
    echo       - HTTPS_PORT=!HTTPS_PORT!
    echo     healthcheck:
    echo       test: ["CMD", "sh", "-c", "python3 -c \"import urllib.request; urllib.request.urlopen('http://127.0.0.1:$$HTTP_PORT/webui/api/service?method=get_version', timeout=5^)\""]
    echo       interval: 30s
    echo       timeout: 10s
    echo       retries: 3
    echo       start_period: 40s
    echo.
    echo   !SERVICE_NAME!-ram:
    echo     extends:
    echo       service: !SERVICE_NAME!
    echo     container_name: !SERVICE_NAME!-ram
    echo     profiles: ["ram"]
    echo     ports:
    echo       - !PORT!:!PORT!
    echo     tmpfs:
    echo       - /root/.ACEStream/.acestream_cache:rw,noexec,nosuid,size=8g
    echo.
    echo   !SERVICE_NAME!-memory:
    echo     extends:
    echo       service: !SERVICE_NAME!
    echo     container_name: !SERVICE_NAME!-memory
    echo     profiles: ["memory"]
    echo     ports:
    echo       - !PORT!:!PORT!
    echo     environment:
    echo       - INTERNAL_IP=!INTERNAL_IP!
    echo       - HTTP_PORT=!HTTP_PORT!
    echo       - HTTPS_PORT=!HTTPS_PORT!
    echo       - ACESTREAM_EXTRA_FLAGS=--live-cache-type memory
    echo.
    echo networks:
    echo   default:
    echo     driver: bridge
)
echo.
echo docker-compose.yml file created or updated successfully.

:: Pull the latest image before starting the service
echo Pulling the latest Docker image...
docker-compose -f !DOCKER_COMPOSE_FILE! pull !SERVICE_NAME!

:: === SAFE CLEANUP OF OUTDATED ACESTREAM IMAGES ===
echo Checking for outdated Acestream images...
set "NEW_IMAGE_ID="
for /f "tokens=1" %%I in ('docker images %IMAGE_NAME% -q') do (
    if not defined NEW_IMAGE_ID (
        set "NEW_IMAGE_ID=%%I"
    ) else (
        set "OLD_IMAGE_ID=%%I"
        if "!AUTO_CLEAN!"=="true" (
            echo Auto-clean: removing obsolete image !OLD_IMAGE_ID! ...
            docker rmi -f !OLD_IMAGE_ID! >nul 2>&1
        ) else (
            choice /M "Remove outdated image !OLD_IMAGE_ID!? (Y/N)" /C YN
            if !errorlevel! == 1 (
                echo Removing image !OLD_IMAGE_ID! ...
                docker rmi -f !OLD_IMAGE_ID!
            ) else (
                echo Skipped image !OLD_IMAGE_ID!.
            )
        )
    )
)
:: -------------------------

:: Attempt to start the service and handle errors in case of failure.
echo Starting the Acestream service...
docker-compose -f !DOCKER_COMPOSE_FILE! up -d !SERVICE_NAME! || (
    echo ERROR: Could not start the Acestream service. Ensure the 'docker-compose.yml' file is correctly configured.
    pause
    goto startDocker
)
echo Acestream service started successfully.

echo Acestream container successfully launched on port: !PORT! using internal HTTP port: !HTTP_PORT!.
echo.

:: -------------------------
:: Starting the content playback in the browser.
:: -------------------------
echo [Content Playback of Acestream]
echo ----------------------------------------
echo The browser will open in 5 seconds to start playing the content.
timeout /t 5 /nobreak >nul
echo Preparing the Acestream stream playback...
start http://!INTERNAL_IP!:!PORT!/webui/player/

:: -------------------------
:: Farewell message and script termination.
:: -------------------------
echo.
echo [Farewell]
echo -------------------------------------------------------------
echo Thank you for using the Acestream x Docker setup assistant.
echo We hope you enjoy an excellent streaming experience!
echo @sergiomarquezdev
echo -------------------------------------------------------------
echo Finalizing the script and restoring the environment...
pause
ENDLOCAL
exit /b
