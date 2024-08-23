@echo off
SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: -------------------------
:: Definition of constants for the script configuration.
:: -------------------------
set "IMAGE_NAME=smarquezp/docker-acestream-ubuntu-home:latest"
set "INTERNAL_IP=127.0.0.1"
set "PORT_BASE=6878"
set "SERVICE_NAME_BASE=acestream_"
set "DOCKER_COMPOSE_FILE=docker-compose.yml"
set "PREFIX=acestream://"
set "HTTP_PORT_BASE=6878"
set "HTTPS_PORT_BASE=6879"

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
    echo networks:
    echo   default:
    echo     driver: bridge
)
echo.
echo docker-compose.yml file created or updated successfully.

:: Pull the latest image before starting the service
echo Pulling the latest Docker image...
docker-compose -f !DOCKER_COMPOSE_FILE! pull !SERVICE_NAME!

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
echo @marquezpsergio
echo -------------------------------------------------------------
echo Finalizing the script and restoring the environment...
pause
ENDLOCAL
exit /b
