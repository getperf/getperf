@echo off
echo %0
for %%F in (%0) do set cwd=%%~dpF

set HOME=%cwd%..

echo "セットアップ(getperfctl.exe setup)を実行します"

%HOME%\bin\getperfctl.exe setup

IF ERRORLEVEL 1 (echo "セットアップ(getperfctl.exe setup)に失敗しました"
goto QUIT
)
IF ERRORLEVEL 0 GOTO SETUP_OK

echo "セットアップ(getperfctl.exe setup)に失敗しました"
goto QUIT

:SETUP_OK
echo "セットアップが完了しました"
pause

echo "続けてWindowsサービスのインストール(getperfctl.exe install)を実行します"

%HOME%\bin\getperfctl.exe install

IF ERRORLEVEL 1 (echo "セットアップ(getperfctl.exe install)に失敗しました"
goto QUIT
)
IF ERRORLEVEL 0 GOTO OK_INSTALL

echo "セットアップ(getperfctl.exe install)に失敗しました"
goto QUIT

:OK_INSTALL
echo "Windowsサービスのインストールが完了しました"

:QUIT
pause

