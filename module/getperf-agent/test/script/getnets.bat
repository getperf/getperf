@echo off
pushd %~dp0

SET /A INTERVAL=%1
SET /A NTIMES=%2

SET /A LOOPCOUNT=1

:LOOP

netstat -s

if "%LOOPCOUNT%"=="%NTIMES%" (
   GOTO END
) else (
   CALL :GPF_SLEEP %INTERVAL%
)

SET /A LOOPCOUNT+=1

GOTO LOOP

::----------------------------------------
:GPF_SLEEP
set  INTERVAL=%1
ping localhost -n %INTERVAL% 1> nul 2>1&
goto :eof

::----------------------------------------
:END

popd
