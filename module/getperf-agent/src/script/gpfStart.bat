@echo off
echo %0
for %%F in (%0) do set cwd=%%~dpF

set HOME=%cwd%..

echo "Windowsサービスの起動(getperfctl.exe start)を実行します"

%HOME%\bin\getperfctl.exe start

pause

