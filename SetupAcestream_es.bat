@echo off
SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Extraccion y validacion del ID de Stream desde el parametro proporcionado.
set "STREAM_ID=%~1"
set "PREFIX=acestream://"

:: Obtencion de IP interna para tratar en contenedor
set "INTERNAL_IP=127.0.0.1"
:: Buscar la primera Direccion IPv4 y asignarla a INTERNAL_IP, solo si es diferente de 127.0.0.1
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /C:"IPv4"') do (
    set "IP_TEMP=%%a"
    :: Eliminar espacios iniciales
    set "IP_TEMP=!IP_TEMP: =!"
    if "!IP_TEMP!" NEQ "127.0.0.1" (
        set "INTERNAL_IP=!IP_TEMP!"
        goto FoundIP
    )
)

:FoundIP
:: Verifica si se paso un argumento al script y procede a verificar si es un enlace Acestream.
:: Si no se proporciona ningun argumento, el script redirige al usuario al menu principal.
if "%STREAM_ID%"=="" (
    goto menu
)
:: Verifica si el enlace proporcionado contiene el prefijo 'acestream://' y lo elimina para obtener solo el ID del stream.
if "%STREAM_ID:~0,12%"=="%PREFIX%" (
    set "STREAM_ID=%STREAM_ID:~12%"
)
:: Verifica si el ID del stream tiene la longitud correcta de 40 caracteres.
if "%STREAM_ID:~39,1%" NEQ "" if "%STREAM_ID:~40,1%"=="" (
    goto installAcestream
) else (
    goto menu
)


:menu
set "OPTION="
cls
echo =======================================================================
echo                            Acestream x Docker
echo                       Asistente de Configuracion v2.2.0
echo =======================================================================
echo.
echo [Menu de Opciones]
echo -------------------------------------------------------------------------------
echo [1] Configurar protocolo Acestream en Windows (OPCIONAL)
echo    - Crea los registros necesarios en el Registro de Windows para abrir los enlaces 'acestream://' directamente.
echo [2] Instalar y ejecutar Acestream en Docker
echo    - Proceso de instalacion de Acestream en Docker (Docker debe estar en ejecucion).
echo [3] Ejecutar navegador con URL para Acestream
echo    - Abre el navegador con el enlace Acestream (requiere contenedor Docker corriendo y activo).
echo [0] Salir
echo -------------------------------------------------------------------------------
echo.
echo Selecciona una opcion y presiona ENTER. Para salir, introduce '0'.
:: Solicita al usuario que introduzca el numero de la opcion que desea realizar.
set /p OPTION="Opcion seleccionada: "

:: Evalua la opcion introducida y redirige al bloque de codigo correspondiente.
if "%OPTION%"=="0" goto end
if "%OPTION%"=="1" goto configProtocol
if "%OPTION%"=="2" goto installAcestream
if "%OPTION%"=="3" (
    set "STREAM_ID="
    goto startAcestream
)
:: Si se introduce una opcion no valida, informa al usuario y regresa al menu.
echo Opcion no valida, por favor intenta nuevamente.
pause
goto menu


:configProtocol
echo.
echo [Configuracion del Protocolo Acestream]
echo ----------------------------------------
echo Verificando permisos de administrador para configurar el protocolo Acestream en el sistema...

:: Intenta agregar una clave de registro para verificar si el script tiene privilegios de administrador.
reg add "HKLM\SOFTWARE\AcestreamSetupCheck" /f >nul 2>&1

if %errorlevel% == 0 (
    :: Elimina la clave temporalmente creada, ya que solo se necesita para la comprobacion.
    reg delete "HKLM\SOFTWARE\AcestreamSetupCheck" /f >nul 2>&1
    echo Permisos de administrador verificados. Procediendo con la configuracion...
) else (
    echo ERROR: Se requieren permisos de administrador para continuar.
    echo Por favor, cierra esta ventana y ejecuta el script nuevamente como administrador.
    pause
    goto menu
)

echo Configurando entradas en el registro para el protocolo Acestream...
:: Agrega las entradas necesarias al registro de Windows.
reg add "HKEY_CLASSES_ROOT\acestream" /ve /t REG_SZ /d "URL:acestream Protocol" /f
reg add "HKEY_CLASSES_ROOT\acestream" /v "URL Protocol" /t REG_SZ /d "" /f
:: Asociacion del protocolo Acestream con este archivo SetupAcestream.bat
reg add "HKEY_CLASSES_ROOT\acestream\shell\open\command" /ve /t REG_SZ /d "\"%~f0\" \"%%1\"" /f

echo Verificando la configuracion del protocolo...
:: Verifica que las entradas se hayan agregado correctamente al registro.
if %errorlevel% == 0 (
    echo Configuracion del protocolo Acestream completada satisfactoriamente.
) else (
    echo Fallo al configurar el protocolo Acestream. Asegurate de tener los permisos adecuados.
    pause
    goto menu
)

echo ----------------------------------------
pause
goto menu


:installAcestream
echo.
echo [Instalacion de Acestream en Docker]
echo ----------------------------------------
echo Configurando el entorno para Acestream...
set IMAGE_NAME=smarquezp/docker-acestream-ubuntu-home:latest
set CONTAINER_NAME=acestream
set PORT=6878

echo Verificando Docker...
:: Verifica si Docker esta instalado y en ejecucion.
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Docker no encontrado. Por favor, instala Docker para continuar.
    start https://www.docker.com/get-started/
    pause
    goto menu
)

docker info >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Docker no esta activo. Por favor, inicia Docker y vuelve a intentarlo.
    pause
    goto menu
)
echo Docker verificado con exito y listo para su uso.

echo Descargando la imagen de Acestream...
:: Descarga la ultima imagen de Acestream desde Docker Hub.
docker pull %IMAGE_NAME% >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Falla al descargar la imagen de Acestream. Por favor, verifica tu conexion e intentalo nuevamente.
    pause
    goto menu
)

echo Verificando contenedores existentes...
:: Verifica y elimina el contenedor existente si es necesario.
docker ps -a --filter "name=%CONTAINER_NAME%" --format "{{.Names}}" | findstr /c:"%CONTAINER_NAME%" >nul 2>&1
if %errorlevel% neq 0 (
    echo Creando un nuevo contenedor para Acestream...
) else (
    echo Contenedor existente detectado. Eliminando para una nueva instalacion...
    docker rm -f %CONTAINER_NAME% >nul 2>&1
)

echo.
echo Verificacion de la direccion IP interna...
:: Permite al usuario confirmar o cambiar la IP interna del contenedor.
echo Tu direccion IP interna actual es: %INTERNAL_IP%
echo Si esta es correcta, presiona ENTER. Si no, ingresa la IP correcta y presiona ENTER.
set /p USER_IP=Introduce la IP o presiona ENTER:
if not "%USER_IP%"=="" set "INTERNAL_IP=%USER_IP%"

echo Usando IP: %INTERNAL_IP%
pause

echo Iniciando el contenedor de Acestream...
:: Inicia el contenedor Docker con Acestream.
docker run -d -p %PORT%:%PORT% -e INTERNAL_IP=%INTERNAL_IP% --name %CONTAINER_NAME% %IMAGE_NAME% >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: No se pudo iniciar el contenedor. Verifica la configuracion e intentalo de nuevo.
    pause
    goto menu
)

echo Contenedor de Acestream iniciado con exito en el puerto: %PORT%
echo ----------------------------------------
goto startAcestream


:startAcestream
echo.
echo [Reproduccion de Contenido Acestream]
echo ----------------------------------------
echo El navegador se abrira en 5 segundos para reproducir el contenido seleccionado.
timeout /t 5 /nobreak >nul

echo Preparando la reproduccion del stream Acestream...
if not "%STREAM_ID%"=="" (
    echo Iniciando stream Acestream con ID: %STREAM_ID%...
    start http://%INTERNAL_IP%:%PORT%/webui/player/%STREAM_ID%
) else (
    echo Por favor, introduce el ID de stream en la interfaz web de Acestream.
    start http://%INTERNAL_IP%:%PORT%/webui/player/
)
pause
goto exit


:end
echo.
echo [Despedida]
echo -------------------------------------------------------------
echo Gracias por utilizar el asistente de configuracion de Acestream x Docker.
echo Esperamos que disfrutes de una excelente experiencia de streaming!
echo @marquezpsergio
echo -------------------------------------------------------------
pause


:exit
echo Finalizando el script y restaurando el entorno...
exit /b
ENDLOCAL
