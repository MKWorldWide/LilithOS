@echo off
setlocal enabledelayedexpansion

echo Starting LilithKit...
set PYTHONPATH=%~dp0
py -3 -m core.divine_bus

if %ERRORLEVEL% NEQ 0 (
    echo Failed to start LilithKit. Check the logs for more information.
    pause
)

exit /b %ERRORLEVEL%
