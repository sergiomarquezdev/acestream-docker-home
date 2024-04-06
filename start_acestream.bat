@echo off

set IMAGE_NAME=smarquezp/docker-acestream-ubuntu:latest
set CONTAINER_NAME=acestream-container
set PORT=6878

echo Verificando y procesando el argumento proporcionado...
if "%~1"=="" (
    echo Advertencia: No se proporcionó un ID de stream. Se abrirá la interfaz sin un stream predefinido.
    set "STREAM_ID="
) else (
    set "STREAM_ID=%~1"
    REM Elimina el prefijo acestream:// si está presente y establece el ID del stream
    set "STREAM_ID=%STREAM_ID:acestream://=%"
)
echo ID de stream a abrir: %STREAM_ID% (si está vacío, se omitirá el ID de stream)

echo Verificando la instalación de Docker...
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Docker no está instalado. Instálalo para continuar.
    start https://www.docker.com/get-started/
    exit /b
) else (
    echo Docker instalado correctamente.
)

echo Descargando la última imagen de Docker desde el repositorio...
docker pull %IMAGE_NAME%

echo Verificando la existencia del contenedor...
docker ps -a --filter "name=%CONTAINER_NAME%" --format "{{.Names}}" | findstr /c:"%CONTAINER_NAME%" >nul 2>&1
if %errorlevel% neq 0 (
    echo Creando y ejecutando un nuevo contenedor basado en la imagen %IMAGE_NAME%...
) else (
    echo Contenedor "%CONTAINER_NAME%" existente detectado. Deteniendo y eliminando para actualizar...
    docker rm -f %CONTAINER_NAME% >nul 2>&1
)
echo Ejecutando el contenedor "%CONTAINER_NAME%"...
docker run -d -p %PORT%:%PORT% --name %CONTAINER_NAME% %IMAGE_NAME%

echo Esperando 5 segundos antes de abrir el navegador...
timeout /t 5 /nobreak > nul

echo Abriendo la interfaz web de Acestream...
if not "%STREAM_ID%"=="" (
    echo Abriendo stream con ID: %STREAM_ID% en el navegador.
    start http://127.0.0.1:%PORT%/webui/player/%STREAM_ID%
) else (
    echo No se especificó un ID de stream. Abriendo la interfaz web de Acestream sin un stream predefinido.
    start http://127.0.0.1:%PORT%/webui/player/
)
