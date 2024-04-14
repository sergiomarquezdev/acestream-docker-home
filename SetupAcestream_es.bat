@echo off
SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: -------------------------
:: Definicion de constantes para la configuracion del script.
:: -------------------------
set "IMAGE_NAME=smarquezp/docker-acestream-ubuntu-home:latest"
set "INTERNAL_IP=127.0.0.1"
set "PORT=6878"
set "SERVICE_NAME=acestream"
set "DOCKER_COMPOSE_FILE=docker-compose.yml"
set "PREFIX=acestream://"

:: -------------------------
:: Verificacion de la instalacion y estado de funcionamiento de Docker.
:: -------------------------
:dockerCheck
echo Verificando Docker...
docker --version >nul 2>&1 || (
    echo ERROR: Docker no encontrado. Por favor, instala Docker para continuar.
    start https://www.docker.com/get-started/
    pause
    goto dockerCheck
)
docker info >nul 2>&1 || (
    echo ERROR: Docker no esta activo. Por favor, inicia Docker y vuelve a intentarlo.
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
:: Creacion o actualizacion del archivo docker-compose.yml.
:: -------------------------
:startDocker
echo.
echo Creando o actualizando el archivo docker-compose.yml...
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
echo Archivo docker-compose.yml creado o actualizado exitosamente.

:: Descarga la imagen Docker mas actualizada antes de arrancar el servicio
echo Descargando la imagen Docker mas actualizada...
docker-compose -f %DOCKER_COMPOSE_FILE% pull %SERVICE_NAME%

:: Intento de iniciar el servicio y manejo de errores en caso de fallo.
echo Iniciando el servicio de Acestream...
docker-compose -f %DOCKER_COMPOSE_FILE% up -d %SERVICE_NAME% || (
    echo ERROR: No se pudo iniciar el servicio Acestream. Asegurate de que el archivo 'docker-compose.yml' este configurado correctamente.
    pause
    goto startDocker
)
echo Servicio Acestream iniciado correctamente.

echo Contenedor de Acestream iniciado con exito en el puerto: %PORT%
echo.

:: -------------------------
:: Iniciar la reproduccion de contenido en el navegador.
:: -------------------------
echo [Reproduccion de Contenido Acestream]
echo ----------------------------------------
echo El navegador se abrira en 5 segundos para reproducir el contenido seleccionado.
timeout /t 5 /nobreak >nul
echo Preparando la reproduccion del stream Acestream...
start http://%INTERNAL_IP%:%PORT%/webui/player/

:: -------------------------
:: Mensaje de despedida y finalizacion del script.
:: -------------------------
echo.
echo [Despedida]
echo -------------------------------------------------------------
echo Gracias por utilizar el asistente de configuracion de Acestream x Docker.
echo Esperamos que disfrutes de una excelente experiencia de streaming!
echo @marquezpsergio
echo -------------------------------------------------------------
echo Finalizando el script y restaurando el entorno...
pause
ENDLOCAL
exit /b
