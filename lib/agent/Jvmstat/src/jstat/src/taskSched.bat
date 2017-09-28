set PERFSTAT=c:\ptune

SCHTASKS /Create /S %COMPUTERNAME% /RU "SYSTEM" /SC ONSTART /TN jvmps /TR "%PERFSTAT%\script\jstatm.bat"

