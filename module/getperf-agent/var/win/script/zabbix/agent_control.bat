@echo off
rem Install service of the zabbix agent 
setlocal ENABLEDELAYEDEXPANSION

set ZABBIX_COMMAND=""
IF !%1==!--install   set ZABBIX_COMMAND=%1
IF !%1==!--uninstall set ZABBIX_COMMAND=%1
IF !%1==!--start     set ZABBIX_COMMAND=%1
IF !%1==!--stop      set ZABBIX_COMMAND=%1
IF !%1==!--help      set ZABBIX_COMMAND=%1
if "%ZABBIX_COMMAND%"=="""" (
	echo USAGE: agent_control.bat [--install^|--uninstall^|--start^|--stop^|--help]
	exit /b 1
)

NET SESSION > NUL 2>&1
IF NOT %ERRORLEVEL% == 0 (
    echo Not running as an administrator. Please run in administrator mode. >&2
    exit /B 1
)

set SCRIPT_DIR=%~dp0
set PTUNE_HOME=%SCRIPT_DIR%\..\..

set ARCH=win64
if %PROCESSOR_ARCHITECTURE%==x86 set ARCH=win32

set ZABBIX_AGENTD_BIN=%PTUNE_HOME%\bin\%ARCH%\zabbix_agentd.exe
set ZABBIX_AGENTD_OPT=--config %PTUNE_HOME%\zabbix_agentd.conf

%ZABBIX_AGENTD_BIN% %ZABBIX_AGENTD_OPT% %ZABBIX_COMMAND%
