@echo off

REM Comprobar si Docker está instalado
docker --version > nul 2>&1

IF %ERRORLEVEL% NEQ 0 (
    echo Docker no está instalado.
    echo Por favor, instala Docker antes de ejecutar este script.
    start https://www.docker.com/products/docker-desktop
    exit /b
)

REM Eliminar el contenedor existente si ya existe
docker ps -aq --filter "name=acestream-container" | docker rm -f acestream-container > nul 2>&1

REM Construir la imagen Docker
docker build --no-cache -t docker-acestream-ubuntu .

REM Ejecutar el contenedor Docker
docker run -d -p 6878:6878 --name acestream-container docker-acestream-ubuntu

echo Contenedor ejecutándose en http://localhost:6878/webui/player/
start http://localhost:6878/webui/player/
