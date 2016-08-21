@echo off
echo %0
for %%F in (%0) do set cwd=%%~dpF

set HOME=%cwd%..
set USAGE=%0 {archive file}.zip

set ARCHIVE=%HOME%\_wk\%1

echo "%ARCHIVE%"
if not exist "%ARCHIVE%" (echo "%ARCHIVE% ‚ªÝ‚è‚Ü‚¹‚ñ"
goto QUIT
)

cd "%HOME%"
"%HOME%\bin\unzip.exe" -o "%ARCHIVE%"

IF ERRORLEVEL 1 (echo "%ARCHIVE% ‚Ì‰ð“€‚ÉŽ¸”s‚µ‚Ü‚µ‚½"
goto QUIT
)
IF ERRORLEVEL 0 GOTO OK

:OK
echo "ƒfƒvƒƒC‚ªŠ®—¹‚µ‚Ü‚µ‚½!"

:QUIT
cd %cwd%
