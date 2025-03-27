rem
rem Windows 2003 Server で有効。（Windows 2000 Server では無効なので、「タスク」のGUIで設定する。）
rem
rem カスタマイズポイント：set PERFSTAT の内容を、インストールしたperfstatフォルダのパスに書き換える。
rem

set PERFSTAT=c:\ptune
set PREFIX=_V24_system

rem Param.ini で STATSEC.HW を 1800秒以上にした場合には、以下のように、getperf.exe を２つ設定する必要がある。
rem 60分周期のものを、30分ずらして2つ設定する。
rem (理由：前回のgetperfが同一の/TNの設定でgetperf動いていると、次回起動時に失敗するから。）
SCHTASKS /Create /S %COMPUTERNAME% /RU "SYSTEM" /SC ONSTART /TN jvmps /TR "C:\ptune\jstatm14\bat_jstatm.bat C:\ptune\jstatm14\tmp"

