@echo off
echo %0
for %%F in (%0) do set cwd=%%~dpF

set HOME=%cwd%..

echo "Windows�T�[�r�X�C���X�g�[��(getperfctl.exe install)�����s���܂�"
pause

%HOME%\bin\getperfctl.exe install

pause

