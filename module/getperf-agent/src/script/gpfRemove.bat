@echo off
echo %0
for %%F in (%0) do set cwd=%%~dpF

set HOME=%cwd%..

echo "Windowsサービスアンインストール(getperfctl.exe remove)を実行します"

%HOME%\bin\getperfctl.exe remove

pause

