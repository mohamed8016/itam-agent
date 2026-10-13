@echo off
setlocal

rem Replace this with the UNC path to the MSI on a share readable by domain computers.
set "MSI_PATH=\\YOUR-FILE-SERVER\ITAM-Software\ITAM_Agent.msi"
set "DEPLOYMENT_VERSION=1.0.3"
set "MARKER=%ProgramData%\ITAM Agent\gpo-installed-%DEPLOYMENT_VERSION%.marker"
set "LOG_PATH=%windir%\Temp\ITAMAgent-GPO-install-%DEPLOYMENT_VERSION%.log"
set "SCRIPT_LOG=%windir%\Temp\ITAMAgent-GPO-bootstrap.log"

if exist "%MARKER%" exit /b 0

echo GPO installation started for version %DEPLOYMENT_VERSION%.>"%SCRIPT_LOG%"
if not exist "%MSI_PATH%" (
    echo ERROR: MSI not found at "%MSI_PATH%".>>"%SCRIPT_LOG%"
    exit /b 2
)

msiexec.exe /i "%MSI_PATH%" /qn /norestart /L*v "%LOG_PATH%"
set "INSTALL_RESULT=%ERRORLEVEL%"
echo msiexec exit code: %INSTALL_RESULT%.>>"%SCRIPT_LOG%"

if not "%INSTALL_RESULT%"=="0" if not "%INSTALL_RESULT%"=="3010" exit /b %INSTALL_RESULT%

if not exist "%ProgramData%\ITAM Agent" (
    mkdir "%ProgramData%\ITAM Agent"
    if errorlevel 1 (
        echo ERROR: Could not create the deployment marker directory.>>"%SCRIPT_LOG%"
        exit /b 3
    )
)

>"%MARKER%" echo Installed version %DEPLOYMENT_VERSION%
if errorlevel 1 (
    echo ERROR: Could not create the deployment marker.>>"%SCRIPT_LOG%"
    exit /b 4
)

echo GPO installation completed.>>"%SCRIPT_LOG%"
exit /b 0
