@echo off
SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: =============================================================
:: Acestream x Docker - Unified setup script (English + Spanish)
:: Usage:
::   SetupAcestream.bat                     interactive, prompts for language
::   SetupAcestream.bat --lang=en           force English, skip prompt
::   SetupAcestream.bat --lang=es           force Spanish, skip prompt
::   SetupAcestream.bat --auto-clean        auto-remove obsolete images
:: =============================================================

:: -------------------------
:: Configuration constants
:: -------------------------
set "IMAGE_NAME=smarquezp/docker-acestream-ubuntu-home:latest"
set "INTERNAL_IP=127.0.0.1"
set "PORT_BASE=6878"
set "SERVICE_NAME_BASE=acestream-engine_"
set "DOCKER_COMPOSE_FILE=docker-compose.yml"
set "PREFIX=acestream://"
set "HTTP_PORT_BASE=6878"
set "HTTPS_PORT_BASE=6879"
set "MAX_PORT=6920"

:: -------------------------
:: Parse command line flags
:: -------------------------
set "AUTO_CLEAN=false"
set "LANG_CHOICE="
for %%A in (%*) do (
    if /I "%%A"=="--auto-clean" set "AUTO_CLEAN=true"
    if /I "%%A"=="--lang=en" set "LANG_CHOICE=en"
    if /I "%%A"=="--lang=es" set "LANG_CHOICE=es"
)

:: -------------------------
:: Interactive language prompt (skipped if --lang=... provided)
:: -------------------------
if "!LANG_CHOICE!"=="" (
    echo.
    echo ==============================================
    echo  Select language / Elige idioma
    echo ==============================================
    echo   [1] English  (default)
    echo   [2] Espanol
    echo.
    choice /C 12 /T 5 /D 1 /N /M "Press 1 or 2 (default 1 in 5s): "
    if !errorlevel! == 2 (
        set "LANG_CHOICE=es"
    ) else (
        set "LANG_CHOICE=en"
    )
)

:: -------------------------
:: Load localized messages
:: -------------------------
if /I "!LANG_CHOICE!"=="es" (
    set "MSG_CHECK_DOCKER=Verificando Docker..."
    set "MSG_DOCKER_ERROR=ERROR: Docker no encontrado o inactivo. Instala o inicia Docker y vuelve a intentar."
    set "MSG_DOCKER_OK=Docker verificado con exito y listo para su uso."
    set "MSG_INSTALL_HEADER=[Instalacion de Acestream en Docker]"
    set "MSG_INSTALL_CONFIG=Configurando el entorno para Acestream..."
    set "MSG_IP_HEADER=Verificacion de la direccion IP interna..."
    set "MSG_IP_CURRENT=Tu direccion IP interna actual es:"
    set "MSG_IP_INSTRUCTIONS=Si esta es correcta, presiona ENTER. Si no, ingresa la IP correcta y presiona ENTER."
    set "MSG_IP_PROMPT=Introduce la IP o presiona ENTER si es correcta:"
    set "MSG_IP_INVALID=ADVERTENCIA: Formato de IP invalido. Usando IP detectada:"
    set "MSG_IP_USING=Usando IP:"
    set "MSG_PORT_OCCUPIED_EXT=esta ocupado por otra aplicacion. Probando con el siguiente puerto..."
    set "MSG_PORT_NO_FREE=ERROR: No se encontraron puertos disponibles en el rango"
    set "MSG_PORT_FREE_ADVICE=Por favor, libera un puerto o verifica tu configuracion de red."
    set "MSG_PORT_USING=Usando el puerto"
    set "MSG_PORT_HTTP=, puerto HTTP"
    set "MSG_PORT_HTTPS=, puerto HTTPS"
    set "MSG_PORT_SERVICE=, y el nombre del servicio"
    set "MSG_COMPOSE_UPDATING=Creando o actualizando el archivo docker-compose.yml..."
    set "MSG_COMPOSE_OK=Archivo docker-compose.yml creado o actualizado exitosamente."
    set "MSG_PULL=Descargando la imagen Docker mas actualizada..."
    set "MSG_CLEAN_CHECK=Comprobando imagenes obsoletas de Acestream..."
    set "MSG_CLEAN_AUTO=Auto-clean activado: eliminando imagen obsoleta"
    set "MSG_CLEAN_PROMPT=Eliminar imagen obsoleta"
    set "MSG_CLEAN_PROMPT_SUFFIX=? (S/N)"
    set "MSG_CLEAN_REMOVING=Eliminando imagen"
    set "MSG_CLEAN_SKIPPED=Imagen omitida:"
    set "MSG_CLEAN_CHOICES=SN"
    set "MSG_START=Iniciando el servicio de Acestream..."
    set "MSG_START_ERROR=ERROR: No se pudo iniciar el servicio Acestream. Asegurate de que el archivo 'docker-compose.yml' este configurado correctamente."
    set "MSG_START_OK=Servicio Acestream iniciado correctamente."
    set "MSG_CONTAINER_LAUNCHED=Contenedor de Acestream iniciado con exito en el puerto:"
    set "MSG_CONTAINER_INTERNAL=usando el puerto HTTP interno:"
    set "MSG_PLAYBACK_HEADER=[Reproduccion de Contenido Acestream]"
    set "MSG_BROWSER_OPEN=El navegador se abrira en 5 segundos para reproducir el contenido seleccionado."
    set "MSG_BROWSER_PREP=Preparando la reproduccion del stream Acestream..."
    set "MSG_FAREWELL_HEADER=[Despedida]"
    set "MSG_FAREWELL_THANKS=Gracias por utilizar el asistente de configuracion de Acestream x Docker."
    set "MSG_FAREWELL_ENJOY=Esperamos que disfrutes de una excelente experiencia de streaming!"
    set "MSG_FAREWELL_FINAL=Finalizando el script y restaurando el entorno..."
) else (
    set "MSG_CHECK_DOCKER=Checking Docker..."
    set "MSG_DOCKER_ERROR=ERROR: Docker not found or not active. Please install and start Docker to continue."
    set "MSG_DOCKER_OK=Docker successfully verified and ready for use."
    set "MSG_INSTALL_HEADER=[Acestream Installation on Docker]"
    set "MSG_INSTALL_CONFIG=Configuring the environment for Acestream..."
    set "MSG_IP_HEADER=Internal IP address verification..."
    set "MSG_IP_CURRENT=Your current internal IP address is:"
    set "MSG_IP_INSTRUCTIONS=If this is correct, press ENTER. Otherwise, enter the correct IP and press ENTER."
    set "MSG_IP_PROMPT=Enter the IP or press ENTER if it is correct:"
    set "MSG_IP_INVALID=WARNING: Invalid IP format entered. Using detected IP:"
    set "MSG_IP_USING=Using IP:"
    set "MSG_PORT_OCCUPIED_EXT=is already occupied by another application. Trying the next port..."
    set "MSG_PORT_NO_FREE=ERROR: No available ports found in range"
    set "MSG_PORT_FREE_ADVICE=Please free up a port or check your network configuration."
    set "MSG_PORT_USING=Using port"
    set "MSG_PORT_HTTP=, HTTP port"
    set "MSG_PORT_HTTPS=, HTTPS port"
    set "MSG_PORT_SERVICE=, and service name"
    set "MSG_COMPOSE_UPDATING=Creating or updating the docker-compose.yml file..."
    set "MSG_COMPOSE_OK=docker-compose.yml file created or updated successfully."
    set "MSG_PULL=Pulling the latest Docker image..."
    set "MSG_CLEAN_CHECK=Checking for outdated Acestream images..."
    set "MSG_CLEAN_AUTO=Auto-clean: removing obsolete image"
    set "MSG_CLEAN_PROMPT=Remove outdated image"
    set "MSG_CLEAN_PROMPT_SUFFIX=? (Y/N)"
    set "MSG_CLEAN_REMOVING=Removing image"
    set "MSG_CLEAN_SKIPPED=Skipped image:"
    set "MSG_CLEAN_CHOICES=YN"
    set "MSG_START=Starting the Acestream service..."
    set "MSG_START_ERROR=ERROR: Could not start the Acestream service. Ensure the 'docker-compose.yml' file is correctly configured."
    set "MSG_START_OK=Acestream service started successfully."
    set "MSG_CONTAINER_LAUNCHED=Acestream container successfully launched on port:"
    set "MSG_CONTAINER_INTERNAL=using internal HTTP port:"
    set "MSG_PLAYBACK_HEADER=[Content Playback of Acestream]"
    set "MSG_BROWSER_OPEN=The browser will open in 5 seconds to start playing the content."
    set "MSG_BROWSER_PREP=Preparing the Acestream stream playback..."
    set "MSG_FAREWELL_HEADER=[Farewell]"
    set "MSG_FAREWELL_THANKS=Thank you for using the Acestream x Docker setup assistant."
    set "MSG_FAREWELL_ENJOY=We hope you enjoy an excellent streaming experience!"
    set "MSG_FAREWELL_FINAL=Finalizing the script and restoring the environment..."
)

:: -------------------------
:: Verify Docker installation and daemon
:: -------------------------
:dockerCheck
echo !MSG_CHECK_DOCKER!
docker --version >nul 2>&1 && docker info >nul 2>&1 || (
    echo !MSG_DOCKER_ERROR!
    start https://www.docker.com/get-started/
    pause
    goto dockerCheck
)
echo !MSG_DOCKER_OK!

:: -------------------------
:: Detect a non-loopback internal IPv4 address
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
:: Acestream and Docker configuration
:: -------------------------
:installAcestream
echo.
echo !MSG_INSTALL_HEADER!
echo ----------------------------------------
echo !MSG_INSTALL_CONFIG!

echo.
echo !MSG_IP_HEADER!
echo !MSG_IP_CURRENT! !INTERNAL_IP!
echo !MSG_IP_INSTRUCTIONS!
echo.
set /p USER_IP=!MSG_IP_PROMPT!
if not "!USER_IP!"=="" (
    rem Basic IP format validation (X.X.X.X)
    echo !USER_IP! | findstr /R "^[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$" >nul
    if !errorlevel! NEQ 0 (
        echo !MSG_IP_INVALID! !INTERNAL_IP!
    ) else (
        set "INTERNAL_IP=!USER_IP!"
    )
)
echo !MSG_IP_USING! !INTERNAL_IP!

:: -------------------------
:: Dynamic port / service-name assignment
:: -------------------------
set "PORT=%PORT_BASE%"
set "SERVICE_NAME=%SERVICE_NAME_BASE%%PORT%"
set "HTTP_PORT=%HTTP_PORT_BASE%"
set "HTTPS_PORT=%HTTPS_PORT_BASE%"

:checkPort
if !PORT! GTR %MAX_PORT% (
    echo !MSG_PORT_NO_FREE! %PORT_BASE%-%MAX_PORT%
    echo !MSG_PORT_FREE_ADVICE!
    pause
    exit /b 1
)
netstat -ano | findstr /R /C:":!PORT!\>" >nul 2>&1
if !errorlevel! == 0 (
    echo Port !PORT! !MSG_PORT_OCCUPIED_EXT!
    set /a "PORT+=2"
    set /a "HTTP_PORT+=2"
    set /a "HTTPS_PORT+=2"
    set "SERVICE_NAME=%SERVICE_NAME_BASE%!PORT!"
    goto checkPort
)

set CONTAINER_ID=
for /f "tokens=*" %%i in ('docker ps -q --filter "name=!SERVICE_NAME!"') do set CONTAINER_ID=%%i

if not defined CONTAINER_ID (
    echo !MSG_PORT_USING! !PORT!!MSG_PORT_HTTP! !HTTP_PORT!!MSG_PORT_HTTPS! !HTTPS_PORT!!MSG_PORT_SERVICE! !SERVICE_NAME!.
) else (
    echo Port !PORT! !MSG_PORT_OCCUPIED_EXT!
    set /a "PORT+=2"
    set /a "HTTP_PORT+=2"
    set /a "HTTPS_PORT+=2"
    set "SERVICE_NAME=%SERVICE_NAME_BASE%!PORT!"
    goto checkPort
)

:: -------------------------
:: Create or update docker-compose.yml
:: Notes:
::   - 'version:' field intentionally omitted (Compose v2 ignores/warns on it)
::   - healthcheck intentionally omitted: Dockerfile is the single source of truth
:: -------------------------
:startDocker
docker stop !SERVICE_NAME! >NUL 2>&1
docker rm !SERVICE_NAME! -f >NUL 2>&1
echo.
echo !MSG_COMPOSE_UPDATING!
>%DOCKER_COMPOSE_FILE% (
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
)
echo.
echo !MSG_COMPOSE_OK!

echo !MSG_PULL!
docker-compose -f !DOCKER_COMPOSE_FILE! pull !SERVICE_NAME!

:: === Safe cleanup of outdated Acestream images ===
echo !MSG_CLEAN_CHECK!
set "NEW_IMAGE_ID="
for /f "tokens=1" %%I in ('docker images %IMAGE_NAME% -q') do (
    if not defined NEW_IMAGE_ID (
        set "NEW_IMAGE_ID=%%I"
    ) else (
        set "OLD_IMAGE_ID=%%I"
        if "!AUTO_CLEAN!"=="true" (
            echo !MSG_CLEAN_AUTO! !OLD_IMAGE_ID! ...
            docker rmi -f !OLD_IMAGE_ID! >nul 2>&1
        ) else (
            choice /M "!MSG_CLEAN_PROMPT! !OLD_IMAGE_ID!!MSG_CLEAN_PROMPT_SUFFIX!" /C !MSG_CLEAN_CHOICES!
            if !errorlevel! == 1 (
                echo !MSG_CLEAN_REMOVING! !OLD_IMAGE_ID! ...
                docker rmi -f !OLD_IMAGE_ID!
            ) else (
                echo !MSG_CLEAN_SKIPPED! !OLD_IMAGE_ID!.
            )
        )
    )
)

echo !MSG_START!
docker-compose -f !DOCKER_COMPOSE_FILE! up -d !SERVICE_NAME! || (
    echo !MSG_START_ERROR!
    pause
    goto startDocker
)
echo !MSG_START_OK!

echo !MSG_CONTAINER_LAUNCHED! !PORT! !MSG_CONTAINER_INTERNAL! !HTTP_PORT!.
echo.

:: -------------------------
:: Open the browser
:: -------------------------
echo !MSG_PLAYBACK_HEADER!
echo ----------------------------------------
echo !MSG_BROWSER_OPEN!
timeout /t 5 /nobreak >nul
echo !MSG_BROWSER_PREP!
start http://!INTERNAL_IP!:!PORT!/webui/player/

:: -------------------------
:: Farewell
:: -------------------------
echo.
echo !MSG_FAREWELL_HEADER!
echo -------------------------------------------------------------
echo !MSG_FAREWELL_THANKS!
echo !MSG_FAREWELL_ENJOY!
echo @sergiomarquezdev
echo -------------------------------------------------------------
echo !MSG_FAREWELL_FINAL!
pause
ENDLOCAL
exit /b
