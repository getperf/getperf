@1echo off
echo %0
for %%F in (%0) do set cwd=%%~dpF

set HOME=%cwd%..

echo "Windows�T�[�r�X�̒�~(getperfctl.exe stop)�����s���܂�"

%HOME%\bin\getperfctl.exe stop

pause

