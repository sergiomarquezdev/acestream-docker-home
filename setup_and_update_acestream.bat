@echo off

REM Eliminar el contenedor existente si ya existe
docker ps -aq --filter "name=acestream-container" | docker rm -f acestream-container > nul 2>&1

REM Construir la imagen Docker
docker build --no-cache -t docker-acestream-linux .

REM Ejecutar el contenedor Docker
docker run -d -p 6878:6878 --name acestream-container docker-acestream-linux

echo "Contenedor ejecutándose en http://127.0.0.1:6878/webui/player/"
