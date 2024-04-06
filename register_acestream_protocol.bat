@echo off
SETLOCAL ENABLEEXTENSIONS

REM %~dp0 incluye la ruta del directorio del script actual, añadiendo start_acestream.bat para completar la ruta
set "BAT_PATH=%~dp0start_acestream.bat"

REM Verificar si start_acestream.bat existe en el directorio actual
IF EXIST "%BAT_PATH%" (
    REM Agregar protocolo acestream
    reg add "HKEY_CLASSES_ROOT\acestream" /ve /t REG_SZ /d "URL:acestream Protocol" /f
    reg add "HKEY_CLASSES_ROOT\acestream" /v "URL Protocol" /t REG_SZ /d "" /f

    REM Asociar el script al protocolo
    reg add "HKEY_CLASSES_ROOT\acestream\shell\open\command" /ve /t REG_SZ /d "\"%BAT_PATH%\" \"%%1\"" /f

    echo Protocolo acestream configurado para ejecutar: %BAT_PATH%
) ELSE (
    echo No se encontró start_acestream.bat en el directorio: %~dp0
    echo Asegúrate de que start_acestream.bat se encuentra en el mismo directorio que register_acestream_protocol.bat.
)

ENDLOCAL
