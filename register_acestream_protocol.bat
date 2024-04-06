@echo off
SETLOCAL ENABLEEXTENSIONS

:: Intenta crear una clave temporal en una ubicación del registro que requiere permisos de administrador
reg add "HKU\S-1-5-19\Software\temp" >nul 2>&1

:: Comprueba el resultado del comando anterior
if %errorlevel% == 0 (
    :: Si el comando tuvo éxito, elimina la clave temporal y continúa con el script
    reg delete "HKU\S-1-5-19\Software\temp" /f >nul 2>&1
    echo Ejecutando con permisos de administrador...
) else (
    echo ERROR: Este script necesita ser ejecutado con permisos de administrador.
    exit /b 1
)

:: Asignación de las rutas de los scripts y claves del registro a variables para fácil referencia
set "BAT_PATH=%~dp0start_acestream.bat"
set "REG_KEY_ACESTREAM=HKEY_CLASSES_ROOT\acestream"
set "REG_KEY_COMMAND=%REG_KEY_ACESTREAM%\shell\open\command"

:: Verificación de la existencia del script start_acestream.bat en el mismo directorio
IF EXIST "%BAT_PATH%" (
    :: Registro del protocolo acestream en el Registro de Windows
    reg add "%REG_KEY_ACESTREAM%" /ve /t REG_SZ /d "URL:acestream Protocol" /f
    reg add "%REG_KEY_ACESTREAM%" /v "URL Protocol" /t REG_SZ /d "" /f

    :: Asociación del protocolo acestream con start_acestream.bat
    reg add "%REG_KEY_COMMAND%" /ve /t REG_SZ /d "\"%BAT_PATH%\" \"%%1\"" /f

    :: Verificación del resultado del último comando reg add
    if %errorlevel% neq 0 (
        echo ERROR: No se pudo agregar el protocolo acestream al registro.
        exit /b 1
    )

    echo Protocolo acestream configurado correctamente para ejecutar: %BAT_PATH%
    echo Por favor, reinicia tu navegador para aplicar los cambios.
) ELSE (
    echo ERROR: No se encontró start_acestream.bat en el directorio: %~dp0
    echo Asegúrate de que start_acestream.bat y este script están en el mismo directorio.
)

ENDLOCAL
