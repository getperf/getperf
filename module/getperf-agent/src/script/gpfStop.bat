@1echo off
echo %0
for %%F in (%0) do set cwd=%%~dpF

set HOME=%cwd%..

echo "Windowsサービスの停止(getperfctl.exe stop)を実行します"

%HOME%\bin\getperfctl.exe stop

pause

