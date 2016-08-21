@echo off
echo %0
for %%F in (%0) do set cwd=%%~dpF

set HOME=%cwd%..

echo "Windowsサービスインストール(getperfctl.exe install)を実行します"
pause

%HOME%\bin\getperfctl.exe install

pause

