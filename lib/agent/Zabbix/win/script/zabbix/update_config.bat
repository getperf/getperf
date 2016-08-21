@echo off
setlocal ENABLEDELAYEDEXPANSION

rem Register the ip address in the zabbix agent configuration file

SET SCRIPT_DIR=%~dp0
SET PTUNE_HOME=%SCRIPT_DIR%\..\..

SET HOSTNAME=%COMPUTERNAME%
CALL :LoCase HOSTNAME

set ZABBIX_INI_FILE=%PTUNE_HOME%\network\zabbix.ini
CALL :GetIniParameter "ZABBIX_HOST" ZABBIX_HOST %ZABBIX_INI_FILE%

echo ZABBIX_HOST

set ZABBIX_AGENTD_CONF_SRC=%PTUNE_HOME%\script\zabbix\zabbix_agentd_src.conf
set ZABBIX_AGENTD_CONF_OUT=%PTUNE_HOME%\zabbix_agentd.conf
type nul >%ZABBIX_AGENTD_CONF_OUT%
for /f "delims=" %%A in (%ZABBIX_AGENTD_CONF_SRC%) do (
    set line=%%A
	set line=!line:__ZABBIX_HOST__=%ZABBIX_HOST%!
    echo !line:__HOSTNAME__=%HOSTNAME%!>>%ZABBIX_AGENTD_CONF_OUT%
)

endlocal

goto EOF

:LoCase
:: Subroutine to convert a variable VALUE to all lower case.
:: The argument for this subroutine is the variable NAME.
FOR %%i IN ("A=a" "B=b" "C=c" "D=d" "E=e" "F=f" "G=g" "H=h" "I=i" "J=j" "K=k" "L=l" "M=m" "N=n" "O=o" "P=p" "Q=q" "R=r" "S=s" "T=t" "U=u" "V=v" "W=w" "X=x" "Y=y" "Z=z") DO CALL SET "%1=%%%1:%%~i%%"

exit /b

:GetIniParameter
:: Get parameter of key from ini file
:: Usage: @GetIniParameter %KEY %PARAM %INI_FILE
set TempStr=
set SN=
for /f "usebackq eol=; delims== tokens=1,2" %%a in (%3) do (
   set V=%%a&set P=!V:~0,1!!V:~-1,1!
   if "!V!"=="%~1" (
      set TempStr=%%b
      goto GET_INI_EXIT
   )
)
set TempStr=ERR

:GET_INI_EXIT
set %2=%TempStr%

exit /b

:EOF
