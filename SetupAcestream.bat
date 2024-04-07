@echo off
SETLOCAL ENABLEEXTENSIONS
SETLOCAL ENABLEDELAYEDEXPANSION

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
    :: Verificacion para el usuario, donde podra cambiar la IP interna.
    echo Su IP interna asignada es %INTERNAL_IP%
    echo.
    echo Puedes revisar si es la IP correcta y sobreescribirla en el caso de que no lo fuese a continuacion.
    echo Te dejo un enlace de interes donde puedes ver como obtenerla: https://www.avast.com/es-es/c-how-to-find-ip-address
    pause
    echo.
    echo Si la IP es correcta ^(%INTERNAL_IP%^), presiona ENTER directamente. De lo contrario, escribe la IP correcta y luego presiona ENTER.
    set /p USER_IP=Introduce aqui la IP o pulsa ENTER: 
    if not "%USER_IP%"=="" set "INTERNAL_IP=%USER_IP%"

    echo.
    echo La IP a utilizar sera: %INTERNAL_IP%
    pause
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
echo ==============================================================
echo Bienvenido al asistente de configuracion de Acestream x Docker
echo ==============================================================
echo.
echo Opciones disponibles:
echo 1. Realizar instalacion de Docker (PRIMORDIAL)
echo    Abre la web de Docker para que puedas realizar la instalacion.
echo 2. Configurar el protocolo acestream en Windows (OPCIONAL)
echo    Crea los registros necesarios en el Registro de Windows para que todos los enlaces 'acestream://xxx' se abran directamente con este script.
echo 3. Instalar y ejecutar Acestream en Docker
echo    Proceso de instalacion de Acestream en Docker (recuerda tener instalada y ejecutada la aplicacion Docker)
echo 4. Ejecutar URL Acestream
echo    Si solamente quieres ejecutar un enlace Acestream (Si ya tienes corriendo el contenedor, si no, ejecuta el paso 3)
echo 5. Salir
echo.
echo Introduce la opcion deseada y presiona ENTER. Para salir, introduce '5'.
:: Solicita al usuario que introduzca el numero de la opcion que desea realizar.
set /p OPTION="Opcion: "

:: Evalua la opcion introducida y redirige al bloque de codigo correspondiente.
if "%OPTION%"=="1" goto installDocker
if "%OPTION%"=="2" goto configProtocol
if "%OPTION%"=="3" goto installAcestream
if "%OPTION%"=="4" (
    set "STREAM_ID="
    goto setAcestreamUrl
)
if "%OPTION%"=="5" goto end
:: Si se introduce una opcion no valida, informa al usuario y regresa al menu.
echo Opcion no valida. Por favor, intenta de nuevo.
pause
goto menu


:installDocker
echo.
echo Abriendo la pagina oficial de Docker para instalar el software necesario...
start https://www.docker.com/get-started/
echo Sigue las instrucciones en el sitio web para instalar Docker. Vuelve aqui cuando hayas terminado.
pause
goto menu


:configProtocol
echo.
echo Configurando el protocolo Acestream en el sistema...
:: Este paso intenta agregar una clave de registro para verificar si el script tiene privilegios de administrador.
reg add "HKLM\SOFTWARE\AcestreamSetupCheck" /f >nul 2>&1

:: Si la clave se agrega con exito, el script se esta ejecutando con privilegios de administrador y puede continuar.
if %errorlevel% == 0 (
    reg delete "HKLM\SOFTWARE\AcestreamSetupCheck" /f >nul 2>&1
    echo.
    echo Estas ejecutando este script como administrador. Continuando...
) else (
    echo.
    echo ERROR: Este proceso requiere permisos de administrador. Por favor, ejecutalo de nuevo como administrador.
    pause
    goto menu
)

echo.
:: Agrega entradas al registro de Windows para el protocolo acestream.
reg add "HKEY_CLASSES_ROOT\acestream" /ve /t REG_SZ /d "URL:acestream Protocol" /f
reg add "HKEY_CLASSES_ROOT\acestream" /v "URL Protocol" /t REG_SZ /d "" /f
:: Asociacion del protocolo acestream con start_acestream.bat
reg add "HKEY_CLASSES_ROOT\acestream\shell\open\command" /ve /t REG_SZ /d "\"%~f0\" \"%%1\"" /f
echo Registros para el protocolo acestream añadidos satisfactoriamente.

:: Verifica que el registro se haya agregado correctamente.
if %errorlevel% neq 0 (
    echo.
    echo No se pudo configurar el protocolo acestream. Asegurate de tener permisos adecuados.
    pause
    goto menu
)

echo.
echo El protocolo acestream se ha configurado con exito. Reinicia tu navegador para que los cambios surtan efecto.
pause
goto menu


:installAcestream
echo.
echo Preparando la instalacion de Acestream en Docker...
set IMAGE_NAME=smarquezp/docker-acestream-ubuntu-home:latest
set CONTAINER_NAME=acestream-home-container
set PORT=6878

echo.
echo Verificando si Docker esta instalado y en ejecucion...
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: No se encontro Docker. Instala Docker para poder continuar.
    start https://www.docker.com/get-started/
    pause
    goto menu
)

docker info >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Docker no esta funcionando. Por favor, inicia Docker antes de proceder.
    pause
    goto menu
)
echo Docker esta listo y funcionando.

echo.
echo Descargando la imagen mas reciente para Acestream desde Docker Hub...
docker pull %IMAGE_NAME%

echo.
echo Comprobando si ya existe un contenedor con el nombre "%CONTAINER_NAME%"...
echo.
docker ps -a --filter "name=%CONTAINER_NAME%" --format "{{.Names}}" | findstr /c:"%CONTAINER_NAME%" >nul 2>&1
if %errorlevel% neq 0 (
    echo Creando un nuevo contenedor para Acestream...
) else (
    echo Un contenedor existente fue encontrado. Limpiando antes de la nueva instalacion...
    docker rm -f %CONTAINER_NAME% >nul 2>&1
)

echo.
echo Iniciando el contenedor de Acestream con Docker...
docker run -d -p %PORT%:%PORT% -e INTERNAL_IP=%INTERNAL_IP% --name %CONTAINER_NAME% %IMAGE_NAME%

echo.
echo El contenedor de Acestream ha sido iniciado con exito y esta escuchando en el puerto %PORT%.
echo.
set "STREAM_ID="
goto setAcestreamUrl


:setAcestreamUrl
:: Solicita al usuario el ID del stream de Acestream si no se ha proporcionado como parametro.
if "%STREAM_ID%"=="" (
    echo Por favor, introduce el ID del enlace de Acestream que deseas abrir:
    set /p STREAM_ID="ID del enlace Acestream: "
    echo.
)

echo El navegador se abrira en 5 segundos para reproducir el contenido.
timeout /t 5 /nobreak >nul

:: Verifica si el enlace proporcionado contiene el prefijo 'acestream://' y lo elimina para obtener solo el ID del stream.
if "%STREAM_ID:~0,12%"=="%PREFIX%" (
    set "STREAM_ID=%STREAM_ID:~12%"
)
:: Verifica si el ID del stream tiene la longitud correcta de 40 caracteres.
if "%STREAM_ID:~39,1%" NEQ "" if "%STREAM_ID:~40,1%"=="" (
    goto startAcestream
) else (
    echo El ID de stream especificado no es correcto. Intentelo de nuevo.
    pause
    goto menu
)

:startAcestream
:: Valida que se ha introducido un ID de stream y procede a abrirlo.
echo Preparando para abrir el stream con ID: %STREAM_ID%...
if not "%STREAM_ID%"=="" (
    echo Iniciando el stream Acestream...
    start http://%INTERNAL_IP%:%PORT%/webui/player/%STREAM_ID%
) else (
    echo No se ha proporcionado un ID de stream.
    echo Abriendo la interfaz web de Acestream para que puedas introducir el ID manualmente...
    start http://%INTERNAL_IP%:%PORT%/webui/player/
)
:exit

:end
echo.
echo ==============================================================
echo Gracias por utilizar mi asistente de configuracion de Acestream x Docker.
echo Hasta luego!
echo ==============================================================
echo.
pause

:exit
exit /b :: Sale del script de batch limpiamente, devolviendo el control al sistema operativo.
ENDLOCAL :: Finaliza la localizacion de cambios en el entorno, restaurando los valores originales.

