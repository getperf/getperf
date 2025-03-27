jstatm
======

jvmstat �� API ���g�p���āA���[�J���z�X�g���� JavaVM �̃q�[�v����\�����܂��B
jstat -gc �R�}���h�ɗގ��������|�[�g���o�͂��܂��B

�C���X�g�[��
------------

JDK1.4���K�v�ł��BJDK1.5�ȏ�����g���̕��́A[jstatm] ���Q�Ƃ��Ă��������B

[jstatm]: https://github.com/frsw3nr/jstatm

    git clone git@github.com:frsw3nr/jstatm14.git
    cd jstatm
    ant

�g�p���@
--------

    cd dest
    ./jstatm.sh -h
    usage: java JStatm [-p [vm report file]] [interval] [count]

+   `-p �t�@�C��` :
    JavaVM��PID�A�R�}���h�A���s�I�v�V�����̃��X�g
 
+   `interval` :
    �̎�Ԋu[�b]

+   `count` :
    ���s��

### �g�p�� ###

    ./jstatm.sh -p jvmlist.txt 3 2
    Date       Time     VMID  EU        OU        PU        YGC    FGC    YGCT      FGCT      THREAD
    2013/01/05 06:44:27 24236   4390912         0   4918712      0      0         0         0      4
    Date       Time     VMID  EU        OU        PU        YGC    FGC    YGCT      FGCT      THREAD
    2013/01/05 06:44:30 24236         0         0   4919664      1      0     12604         0      4
    
    more jvmlist.txt
    
    - pid: 24236
      java.property.java.version: 1.6.0_22
      sun.rt.javaCommand: JStatm -p jvmlist.txt 3 2

�֘A���
--------

1. [Java�̃v���Z�X�����擾](http://blogs.wankuma.com/kacchan6/archive/2007/08/29/92501.aspx)
2. [MonitoredHost (Jvmstat)](http://openjdk.java.net/groups/serviceability/jvmstat/sun/jvmstat/monitor/MonitoredHost.html)

���C�Z���X
----------
Copyright &copy; 2012  Getperf Ltd.
Licensed under the [GPL license][GPL].
 
[GPL]: http://www.gnu.org/licenses/gpl.html
