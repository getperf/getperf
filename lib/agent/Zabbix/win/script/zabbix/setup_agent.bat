@echo off
setlocal ENABLEDELAYEDEXPANSION

set YESNO=y
set /P YESNO="Press 'y' if you want to setup the zabbix agent [y]: "
if not "%YESNO%"=="y" (
	exit /b
)

set SCRIPT_DIR=%~dp0
call %SCRIPT_DIR%update_config.bat
if not "%ERRORLEVEL%"  == "0" (
    echo [FATAL] update_config.bat failed
    exit /b
)

echo %SCRIPT_DIR%agent_control.bat --install
call %SCRIPT_DIR%agent_control.bat --install
if not "%ERRORLEVEL%"  == "0" (
    echo [WARN] agent_control.bat --install failed
)

echo %SCRIPT_DIR%agent_control.bat --start
call %SCRIPT_DIR%agent_control.bat --start
if not "%ERRORLEVEL%"  == "0" (
    echo [FATAL] agent_control.bat --start failed
)
