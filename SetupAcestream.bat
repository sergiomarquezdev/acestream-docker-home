@echo off
SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION

:: Stream ID extraction and validation from the provided parameter.
set "STREAM_ID=%~1"
set "PREFIX=acestream://"

:: Internal IP retrieval for container handling
set "INTERNAL_IP=127.0.0.1"
:: Search for the first IPv4 Address and assign it to INTERNAL_IP, only if it is different from 127.0.0.1
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /C:"IPv4"') do (
    set "IP_TEMP=%%a"
    :: Remove leading spaces
    set "IP_TEMP=!IP_TEMP: =!"
    if "!IP_TEMP!" NEQ "127.0.0.1" (
        set "INTERNAL_IP=!IP_TEMP!"
        goto FoundIP
    )
)

:FoundIP
:: Checks if an argument was passed to the script and proceeds to verify if it is an Acestream link.
:: If no argument is provided, the script redirects the user to the main menu.
if "%STREAM_ID%"=="" (
    goto menu
)
:: Checks if the provided link contains the 'acestream://' prefix and removes it to obtain only the stream ID.
if "%STREAM_ID:~0,12%"=="%PREFIX%" (
    set "STREAM_ID=%STREAM_ID:~12%"
)
:: Verifies if the stream ID has the correct length of 40 characters.
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
echo                       Configuration Assistant v2.2.0
echo =======================================================================
echo.
echo [Options Menu]
echo -------------------------------------------------------------------------------
echo [1] Configure Acestream protocol in Windows (OPTIONAL)
echo    - Creates the necessary registry entries in Windows to directly open 'acestream://' links.
echo [2] Install and run Acestream in Docker
echo    - Acestream installation process in Docker (Docker must be running).
echo [3] Execute browser with Acestream URL
echo    - Opens the browser with the Acestream link (requires Docker container running and active).
echo [0] Exit
echo -------------------------------------------------------------------------------
echo.
echo Select an option and press ENTER. To exit, type '0'.
:: Prompts the user to enter the number of the option they wish to perform.
set /p OPTION="Selected option: "

:: Evaluates the entered option and redirects to the corresponding code block.
if "%OPTION%"=="0" goto end
if "%OPTION%"=="1" goto configProtocol
if "%OPTION%"=="2" goto installAcestream
if "%OPTION%"=="3" (
    set "STREAM_ID="
    goto startAcestream
)
:: If an invalid option is introduced, informs the user and returns to the menu.
echo Invalid option, please try again.
pause
goto menu


:configProtocol
echo.
echo [Acestream Protocol Configuration]
echo ----------------------------------------
echo Checking admin permissions to configure the Acestream protocol on the system...

:: Attempts to add a registry key to verify if the script is running with administrator privileges.
reg add "HKLM\SOFTWARE\AcestreamSetupCheck" /f >nul 2>&1

if %errorlevel% == 0 (
    :: Deletes the temporarily created key as it's only needed for verification.
    reg delete "HKLM\SOFTWARE\AcestreamSetupCheck" /f >nul 2>&1
    echo Admin permissions verified. Proceeding with the configuration...
) else (
    echo ERROR: Admin permissions are required to continue.
    echo Please close this window and run the script again as administrator.
    pause
    goto menu
)

echo Configuring registry entries for the Acestream protocol...
:: Adds the necessary entries to the Windows registry.
reg add "HKEY_CLASSES_ROOT\acestream" /ve /t REG_SZ /d "URL:Acestream Protocol" /f
reg add "HKEY_CLASSES_ROOT\acestream" /v "URL Protocol" /t REG_SZ /d "" /f
:: Associates the Acestream protocol with this SetupAcestream.bat file.
reg add "HKEY_CLASSES_ROOT\acestream\shell\open\command" /ve /t REG_SZ /d "\"%~f0\" \"%%1\"" /f

echo Verifying the protocol configuration...
:: Verifies that the entries have been correctly added to the registry.
if %errorlevel% == 0 (
    echo Acestream protocol configuration completed successfully.
) else (
    echo Failed to configure the Acestream protocol. Please ensure you have the appropriate permissions.
    pause
    goto menu
)

echo ----------------------------------------
pause
goto menu


:installAcestream
echo.
echo [Acestream Installation in Docker]
echo ----------------------------------------
echo Setting up the environment for Acestream...
set IMAGE_NAME=smarquezp/docker-acestream-ubuntu-home:latest
set CONTAINER_NAME=acestream
set PORT=6878

echo Checking Docker...
:: Checks if Docker is installed and running.
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Docker not found. Please install Docker to continue.
    start https://www.docker.com/get-started/
    pause
    goto menu
)

docker info >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Docker is not active. Please start Docker and try again.
    pause
    goto menu
)
echo Docker successfully verified and ready for use.

echo Downloading the Acestream image...
:: Downloads the latest Acestream image from Docker Hub.
docker pull %IMAGE_NAME% >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Failed to download the Acestream image. Please check your connection and try again.
    pause
    goto menu
)

echo Checking existing containers...
:: Checks and removes the existing container if necessary.
docker ps -a --filter "name=%CONTAINER_NAME%" --format "{{.Names}}" | findstr /c:"%CONTAINER_NAME%" >nul 2>&1
if %errorlevel% neq 0 (
    echo Creating a new container for Acestream...
) else (
    echo Existing container detected. Removing for a new installation...
    docker rm -f %CONTAINER_NAME% >nul 2>&1
)

echo.
echo Checking the internal IP address...
:: Allows the user to confirm or change the internal IP address of the container.
echo Your current internal IP address is: %INTERNAL_IP%
echo If it's correct, press ENTER. If not, enter the correct IP and press ENTER.
set /p USER_IP=Enter the IP or press ENTER:
if not "%USER_IP%"=="" set "INTERNAL_IP=%USER_IP%"

echo Using IP: %INTERNAL_IP%
pause

echo Starting the Acestream container...
:: Starts the Docker container with Acestream.
docker run -d -p %PORT%:%PORT% -e INTERNAL_IP=%INTERNAL_IP% --name %CONTAINER_NAME% --restart unless-stopped %IMAGE_NAME% >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Could not start the container. Check the configuration and try again.
    pause
    goto menu
)

echo Acestream container successfully started on port: %PORT%
echo ----------------------------------------
goto startAcestream


:startAcestream
echo.
echo [Acestream Content Playback]
echo ----------------------------------------
echo The browser will open in 5 seconds to play the selected content.
timeout /t 5 /nobreak >nul

echo Preparing the Acestream playback...
if not "%STREAM_ID%"=="" (
    echo Starting Acestream stream with ID: %STREAM_ID%...
    start http://%INTERNAL_IP%:%PORT%/webui/player/%STREAM_ID%
) else (
    echo Please enter the stream ID on the Acestream web interface.
    start http://%INTERNAL_IP%:%PORT%/webui/player/
)
pause
goto exit

:end
echo.
echo [Farewell]
echo -------------------------------------------------------------
echo Thank you for using the Acestream x Docker setup assistant.
echo We hope you enjoy an excellent streaming experience!
echo @marquezpsergio
echo -------------------------------------------------------------
pause

:exit
echo Finalizing the script and restoring the environment...
exit /b
ENDLOCAL

