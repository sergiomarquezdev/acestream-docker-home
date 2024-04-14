@echo off
SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: -------------------------
:: Definition of constants for the script configuration.
:: -------------------------
set "IMAGE_NAME=smarquezp/docker-acestream-ubuntu-home:latest"
set "INTERNAL_IP=127.0.0.1"
set "PORT=6878"
set "SERVICE_NAME=acestream"
set "DOCKER_COMPOSE_FILE=docker-compose.yml"
set "PREFIX=acestream://"

:: -------------------------
:: Checking for Docker installation and operational status.
:: -------------------------
:dockerCheck
echo Checking Docker...
docker --version >nul 2>&1 || (
    echo ERROR: Docker not found. Please install Docker to continue.
    start https://www.docker.com/get-started/
    pause
    goto dockerCheck
)
docker info >nul 2>&1 || (
    echo ERROR: Docker is not active. Please start Docker and try again.
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
:: Creation or update of the docker-compose.yml file.
:: -------------------------
:startDocker
echo.
echo Creating or updating the docker-compose.yml file...
>%DOCKER_COMPOSE_FILE% (
    echo version: '3.8'
    echo services:
    echo   acestream:
    echo     image: %IMAGE_NAME%
    echo     container_name: acestream
    echo     restart: unless-stopped
    echo     ports:
    echo       - %PORT%:%PORT%
    echo     environment:
    echo       - INTERNAL_IP=%INTERNAL_IP%
    echo networks:
    echo   default:
    echo     driver: bridge
)
echo.
echo docker-compose.yml file created or updated successfully.

:: Pull the latest image before starting the service
echo Pulling the latest Docker image...
docker-compose -f %DOCKER_COMPOSE_FILE% pull %SERVICE_NAME%

:: Attempt to start the service and handle errors in case of failure.
echo Starting the Acestream service...
docker-compose -f %DOCKER_COMPOSE_FILE% up -d %SERVICE_NAME% || (
    echo ERROR: Could not start the Acestream service. Ensure the 'docker-compose.yml' file is correctly configured.
    pause
    goto startDocker
)
echo Acestream service started successfully.

echo Acestream container successfully launched on port: %PORT%
echo.

:: -------------------------
:: Starting the content playback in the browser.
:: -------------------------
echo [Content Playback of Acestream]
echo ----------------------------------------
echo The browser will open in 5 seconds to start playing the content.
timeout /t 5 /nobreak >nul
echo Preparing the Acestream stream playback...
start http://%INTERNAL_IP%:%PORT%/webui/player/

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
