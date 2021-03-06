@echo off
echo %0
for %%F in (%0) do set cwd=%%~dpF

set HOME=%cwd%..
set USAGE=%0 {archive file}.zip

set ARCHIVE=%HOME%\_wk\%1

echo "%ARCHIVE%"
if not exist "%ARCHIVE%" (echo "%ARCHIVE% が在りません"
goto QUIT
)

cd "%HOME%"
"%HOME%\bin\unzip.exe" -o "%ARCHIVE%"

IF ERRORLEVEL 1 (echo "%ARCHIVE% の解凍に失敗しました"
goto QUIT
)
IF ERRORLEVEL 0 GOTO OK

:OK
echo "デプロイが完了しました!"

:QUIT
cd %cwd%
