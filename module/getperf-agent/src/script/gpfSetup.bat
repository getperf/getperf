@echo off
echo %0
for %%F in (%0) do set cwd=%%~dpF

set HOME=%cwd%..

echo "�Z�b�g�A�b�v(getperfctl.exe setup)�����s���܂�"

%HOME%\bin\getperfctl.exe setup

IF ERRORLEVEL 1 (echo "�Z�b�g�A�b�v(getperfctl.exe setup)�Ɏ��s���܂���"
goto QUIT
)
IF ERRORLEVEL 0 GOTO SETUP_OK

echo "�Z�b�g�A�b�v(getperfctl.exe setup)�Ɏ��s���܂���"
goto QUIT

:SETUP_OK
echo "�Z�b�g�A�b�v���������܂���"
pause

echo "������Windows�T�[�r�X�̃C���X�g�[��(getperfctl.exe install)�����s���܂�"

%HOME%\bin\getperfctl.exe install

IF ERRORLEVEL 1 (echo "�Z�b�g�A�b�v(getperfctl.exe install)�Ɏ��s���܂���"
goto QUIT
)
IF ERRORLEVEL 0 GOTO OK_INSTALL

echo "�Z�b�g�A�b�v(getperfctl.exe install)�Ɏ��s���܂���"
goto QUIT

:OK_INSTALL
echo "Windows�T�[�r�X�̃C���X�g�[�����������܂���"

:QUIT
pause

