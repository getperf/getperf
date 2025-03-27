@echo off
if "%OS%" == "Windows_NT" setlocal

set ODIR=%1%
set JSTATM_HOME=%~dp0
set CLASSPATH=C:\j2sdk1.4.2_06
set PATH=%CLASSPATH%\bin;%PATH%
%JSTATM_HOME%jstatm.bat -p %ODIR%\jvmlist.txt 3 3 > %ODIR%\jstat3.txt
