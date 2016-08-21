@echo off
echo %0
for %%F in (%0) do set cwd=%%~dpF

set PATH=%cwd%\bin;%PATH%
REM C:\ptune\win\bin\
set PATH=%cwd%\..\win\bin;%PATH%

echo %cwd%\..\win\bin

cd %cwd%\test
.\gpf_test.exe -s gpf_admin -t 10
REM perl test_getperfsoap2.pl
cd %cwd%

:QUIT
