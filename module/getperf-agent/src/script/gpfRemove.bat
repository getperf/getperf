@echo off
echo %0
for %%F in (%0) do set cwd=%%~dpF

set HOME=%cwd%..

echo "Windows�T�[�r�X�A���C���X�g�[��(getperfctl.exe remove)�����s���܂�"

%HOME%\bin\getperfctl.exe remove

pause

