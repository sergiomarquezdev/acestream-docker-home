@echo off

set IMAGE_NAME=smarquezp/docker-acestream-ubuntu:latest
set CONTAINER_NAME=acestream-container
set PORT=6878

REM Verifica y procesa el argumento pasado
if "%~1"=="" (
    echo Ejecutado sin argumento.
    set "STREAM_ID="
) else (
    set "STREAM_ID=%~1"
    REM Quita acestream:// del argumento pasado si está presente y lo setea en la variable
    set "STREAM_ID=%STREAM_ID:acestream://=%"
)
echo Abriendo stream ID: %STREAM_ID%

REM Verifica que Docker esté instalado
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Docker no está instalado. Por favor, instala Docker y vuelve a intentarlo.
    exit /b
)

REM Descarga la última imagen desde el repositorio de Docker
docker pull %IMAGE_NAME%

REM Verifica si el contenedor ya existe
docker ps -a --filter "name=%CONTAINER_NAME%" --format "{{.Names}}" | findstr /c:"%CONTAINER_NAME%" >nul 2>&1
if %errorlevel% neq 0 (
    echo Creando y ejecutando un nuevo contenedor...
) else (
    echo Contenedor existente detectado. Deteniendo y eliminando...
    docker rm -f %CONTAINER_NAME% >nul 2>&1
)
docker run -d -p %PORT%:%PORT% --name %CONTAINER_NAME% %IMAGE_NAME%

REM Espera 5 segundos antes de abrir el navegador
timeout /t 5 /nobreak > nul

REM Comprueba el STREAM_ID y abre el navegador en la URL específica
if not "%STREAM_ID%"=="" (
    start http://127.0.0.1:%PORT%/webui/player/%STREAM_ID%
) else (
    echo Advertencia: STREAM_ID no especificado. Abriendo el reproductor sin ID de stream.
    start http://127.0.0.1:%PORT%/webui/player/
)
