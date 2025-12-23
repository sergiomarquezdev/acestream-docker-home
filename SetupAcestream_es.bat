@echo off
SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: -------------------------
:: Definicion de constantes para la configuracion del script.
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
:: Analizar argumentos de linea de comandos para flags opcionales
:: -------------------------
set "AUTO_CLEAN=false"
for %%A in (%*) do (
    if /I "%%A"=="--auto-clean" set "AUTO_CLEAN=true"
)
:: -------------------------
:: Verificacion de la instalacion y estado de funcionamiento de Docker.
:: -------------------------
:dockerCheck
echo Verificando Docker...
docker --version >nul 2>&1 && docker info >nul 2>&1 || (
    echo ERROR: Docker no encontrado o inactivo. Instala o inicia Docker y vuelve a intentar.
    start https://www.docker.com/get-started/
    pause
    goto dockerCheck
)
echo Docker verificado con exito y listo para su uso.

:: -------------------------
:: Obtencion de una direccion IP interna no loopback.
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
:: Seccion de configuracion de Acestream y Docker.
:: -------------------------
:installAcestream
echo.
echo [Instalacion de Acestream en Docker]
echo ----------------------------------------
echo Configurando el entorno para Acestream...

:: Solicitar al usuario que valide o modifique la direccion IP detectada.
echo.
echo Verificacion de la direccion IP interna...
echo Tu direccion IP interna actual es: %INTERNAL_IP%
echo Si esta es correcta, presiona ENTER. Si no, ingresa la IP correcta y presiona ENTER.
echo.
set /p USER_IP=Introduce la IP o presiona ENTER si es correcta:
if not "%USER_IP%"=="" set "INTERNAL_IP=%USER_IP%"
echo Usando IP: %INTERNAL_IP%

:: -------------------------
:: Asignacion dinamica de puertos y nombre del servicio.
:: -------------------------
set "PORT=%PORT_BASE%"
set "SERVICE_NAME=%SERVICE_NAME_BASE%%PORT%"
set "HTTP_PORT=%HTTP_PORT_BASE%"
set "HTTPS_PORT=%HTTPS_PORT_BASE%"

:checkPort
rem Primero, verificar si el puerto deseado ya esta ocupado por otro proceso (p.ej. Acestream Player nativo)
netstat -ano | findstr /R /C:":!PORT!\>" >nul 2>&1
if !errorlevel! == 0 (
    echo El puerto !PORT! esta ocupado por otra aplicacion. Probando con el siguiente puerto...
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
    echo Usando el puerto !PORT!, puerto HTTP !HTTP_PORT!, puerto HTTPS !HTTPS_PORT!, y el nombre del servicio !SERVICE_NAME!.
) else (
    echo El puerto !PORT! ya esta en uso. Probando con el siguiente puerto...
    set /a "PORT+=2"
    set /a "HTTP_PORT+=2"
    set /a "HTTPS_PORT+=2"
    set "SERVICE_NAME=%SERVICE_NAME_BASE%!PORT!"
    echo DEBUG: Ahora usando el puerto !PORT!, puerto HTTP !HTTP_PORT!, puerto HTTPS !HTTPS_PORT!, y el nombre del servicio !SERVICE_NAME!.
    goto checkPort
)

:: -------------------------
:: Creacion o actualizacion del archivo docker-compose.yml.
:: -------------------------
:startDocker
docker stop !SERVICE_NAME! >NUL 2>&1
docker rm !SERVICE_NAME! -f >NUL 2>&1
echo.
echo Creando o actualizando el archivo docker-compose.yml...
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
    echo       test: ["CMD", "python3", "-c", "import urllib.request; urllib.request.urlopen('http://127.0.0.1:!HTTP_PORT!/webui/api/service?method=get_version', timeout=5^)"]
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
echo Archivo docker-compose.yml creado o actualizado exitosamente.

:: Descarga la imagen Docker mas actualizada antes de arrancar el servicio
echo Descargando la imagen Docker mas actualizada...
docker-compose -f !DOCKER_COMPOSE_FILE! pull !SERVICE_NAME!

:: === LIMPIEZA SEGURA DE IMAGENES OBSOLETAS DE ACESTREAM ===
echo Comprobando imagenes obsoletas de Acestream...
set "NEW_IMAGE_ID="
for /f "tokens=1" %%I in ('docker images %IMAGE_NAME% -q') do (
    if not defined NEW_IMAGE_ID (
        set "NEW_IMAGE_ID=%%I"
    ) else (
        set "OLD_IMAGE_ID=%%I"
        if "!AUTO_CLEAN!"=="true" (
            echo Auto-clean activado: eliminando imagen obsoleta !OLD_IMAGE_ID! ...
            docker rmi -f !OLD_IMAGE_ID! >nul 2>&1
        ) else (
            choice /M "Eliminar imagen obsoleta !OLD_IMAGE_ID!? (S/N)" /C SN
            if !errorlevel! == 1 (
                echo Eliminando imagen !OLD_IMAGE_ID! ...
                docker rmi -f !OLD_IMAGE_ID!
            ) else (
                echo Imagen !OLD_IMAGE_ID! omitida.
            )
        )
    )
)
:: -------------------------

:: Intento de iniciar el servicio y manejo de errores en caso de fallo.
echo Iniciando el servicio de Acestream...
docker-compose -f !DOCKER_COMPOSE_FILE! up -d !SERVICE_NAME! || (
    echo ERROR: No se pudo iniciar el servicio Acestream. Asegurate de que el archivo 'docker-compose.yml' este configurado correctamente.
    pause
    goto startDocker
)
echo Servicio Acestream iniciado correctamente.

echo Contenedor de Acestream iniciado con exito en el puerto: !PORT! usando el puerto HTTP interno: !HTTP_PORT!.
echo.

:: -------------------------
:: Iniciar la reproduccion de contenido en el navegador.
:: -------------------------
echo [Reproduccion de Contenido Acestream]
echo ----------------------------------------
echo El navegador se abrira en 5 segundos para reproducir el contenido seleccionado.
timeout /t 5 /nobreak >nul
echo Preparando la reproduccion del stream Acestream...
start http://!INTERNAL_IP!:!PORT!/webui/player/

:: -------------------------
:: Mensaje de despedida y finalizacion del script.
:: -------------------------
echo.
echo [Despedida]
echo -------------------------------------------------------------
echo Gracias por utilizar el asistente de configuracion de Acestream x Docker.
echo Esperamos que disfrutes de una excelente experiencia de streaming!
echo @sergiomarquezdev
echo -------------------------------------------------------------
echo Finalizando el script y restaurando el entorno...
pause
ENDLOCAL
exit /b
