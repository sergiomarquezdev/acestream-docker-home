@echo off

set IMAGE_NAME=smarquezp/docker-acestream-ubuntu:latest
set CONTAINER_NAME=acestream-container
set PORT=6878
set STREAM_ID=%1

REM Verifica que Docker esté instalado
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Docker no está instalado. Por favor, instala Docker y vuelve a intentarlo.
    exit /b
)

REM Detiene y elimina el contenedor existente, si lo hay
docker stop %CONTAINER_NAME% >nul 2>&1
docker rm %CONTAINER_NAME% >nul 2>&1

REM Descarga la última imagen desde el repositorio de Docker
docker pull %IMAGE_NAME%

REM Ejecuta el contenedor de Docker
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
