rem
rem Windows 2003 Server �ŗL���B�iWindows 2000 Server �ł͖����Ȃ̂ŁA�u�^�X�N�v��GUI�Őݒ肷��B�j
rem
rem �J�X�^�}�C�Y�|�C���g�Fset PERFSTAT �̓��e���A�C���X�g�[������perfstat�t�H���_�̃p�X�ɏ���������B
rem

set PERFSTAT=c:\ptune
set PREFIX=_V24_system

rem Param.ini �� STATSEC.HW �� 1800�b�ȏ�ɂ����ꍇ�ɂ́A�ȉ��̂悤�ɁAgetperf.exe ���Q�ݒ肷��K�v������B
rem 60�������̂��̂��A30�����炵��2�ݒ肷��B
rem (���R�F�O���getperf�������/TN�̐ݒ��getperf�����Ă���ƁA����N�����Ɏ��s���邩��B�j
SCHTASKS /Create /S %COMPUTERNAME% /RU "SYSTEM" /SC ONSTART /TN jvmps /TR "C:\ptune\jstatm14\bat_jstatm.bat C:\ptune\jstatm14\tmp"

