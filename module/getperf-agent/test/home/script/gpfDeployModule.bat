@echo off
echo %0
for %%F in (%0) do set cwd=%%~dpF

set HOME=%cwd%..
set USAGE=%0 {archive file}.zip

set ARCHIVE=%1

if not exist %ARCHIVE% (echo "%ARCHIVE% Ç™ç›ÇËÇ‹ÇπÇÒ"
goto QUIT
)

cd %HOME%
%HOME%\bin\unzip.exe -o %ARCHIVE%
cd %cwd%

:QUIT
