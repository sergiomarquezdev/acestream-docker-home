@echo off
REM ===============================================
REM Script de Testing para Acestream Docker
REM Prueba todas las nuevas funcionalidades
REM ===============================================

echo ================================================
echo   ACESTREAM DOCKER - PLAN DE TESTING
echo ================================================
echo.

REM === TEST 1: Verificar imagen construida ===
echo [TEST 1] Verificando imagen local construida...
docker images acestream-test:latest
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Imagen acestream-test:latest no encontrada
    echo Por favor ejecuta: docker build -t acestream-test:latest .
    pause
    exit /b 1
)
echo OK - Imagen encontrada
echo.

REM === TEST 2: Profile DEFAULT (Disco) - Retrocompatibilidad ===
echo [TEST 2] Probando Profile DEFAULT (cache en disco)...
echo Iniciando contenedor con docker-compose up -d...
docker-compose up -d

echo Esperando 50 segundos para que Acestream inicie y healthcheck se ejecute...
timeout /t 50 /nobreak

echo Verificando estado del contenedor...
docker ps -a --filter "name=acestream" --format "table {{.Names}}\t{{.Status}}"

echo.
echo Verificando healthcheck (debe mostrar 'healthy' o 'health: starting')...
docker inspect acestream --format "{{.State.Health.Status}}"

echo.
echo Verificando logs para ver si hay errores...
docker logs acestream --tail 30

echo.
echo Probando endpoint de API...
curl -s "http://127.0.0.1:6878/webui/api/service?method=get_version"

echo.
echo.
echo TEST 2 completado. Presiona cualquier tecla para detener y continuar...
pause

docker-compose down
timeout /t 5 /nobreak
echo.

REM === TEST 3: Profile RAM (tmpfs) ===
echo [TEST 3] Probando Profile RAM (tmpfs 8GB)...
echo NOTA: Este test requiere WSL2 o Linux
echo Iniciando contenedor con --profile ram...
docker-compose --profile ram up -d

echo Esperando 50 segundos...
timeout /t 50 /nobreak

echo Verificando estado...
docker ps -a --filter "name=acestream-ram" --format "table {{.Names}}\t{{.Status}}"

echo.
echo Verificando healthcheck...
docker inspect acestream-ram --format "{{.State.Health.Status}}"

echo.
echo Verificando que tmpfs este montado...
docker exec acestream-ram df -h | findstr "ACEStream"

echo.
echo TEST 3 completado. Presiona cualquier tecla para detener y continuar...
pause

docker-compose down
timeout /t 5 /nobreak
echo.

REM === TEST 4: Profile MEMORY (flag nativo cross-platform) ===
echo [TEST 4] Probando Profile MEMORY (flag nativo --live-cache-type memory)...
echo Iniciando contenedor con --profile memory...
docker-compose --profile memory up -d

echo Esperando 50 segundos...
timeout /t 50 /nobreak

echo Verificando estado...
docker ps -a --filter "name=acestream-memory" --format "table {{.Names}}\t{{.Status}}"

echo.
echo Verificando healthcheck...
docker inspect acestream-memory --format "{{.State.Health.Status}}"

echo.
echo Verificando logs para confirmar flag --live-cache-type memory...
docker logs acestream-memory | findstr "live-cache-type memory"
docker logs acestream-memory | findstr "Extra Flags"

echo.
echo TEST 4 completado. Presiona cualquier tecla para detener...
pause

docker-compose down
echo.

REM === RESUMEN ===
echo ================================================
echo   TESTING COMPLETADO
echo ================================================
echo.
echo Revisa los resultados anteriores:
echo.
echo [TEST 1] Imagen local: OK
echo [TEST 2] Profile default (disco): Revisar estado/healthcheck
echo [TEST 3] Profile ram (tmpfs): Revisar si tmpfs esta montado
echo [TEST 4] Profile memory (flag): Revisar si aparece flag en logs
echo.
echo ================================================
pause
