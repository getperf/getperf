jstatm
======

jvmstat の API を使用して、ローカルホスト内の JavaVM のヒープ情報を表示します。
jstat -gc コマンドに類似したレポートを出力します。

インストール
------------

JDK1.4が必要です。JDK1.5以上をお使いの方は、[jstatm] を参照してください。

[jstatm]: https://github.com/frsw3nr/jstatm

    git clone git@github.com:frsw3nr/jstatm14.git
    cd jstatm
    ant

使用方法
--------

    cd dest
    ./jstatm.sh -h
    usage: java JStatm [-p [vm report file]] [interval] [count]

+   `-p ファイル` :
    JavaVMのPID、コマンド、実行オプションのリスト
 
+   `interval` :
    採取間隔[秒]

+   `count` :
    実行回数

### 使用例 ###

    ./jstatm.sh -p jvmlist.txt 3 2
    Date       Time     VMID  EU        OU        PU        YGC    FGC    YGCT      FGCT      THREAD
    2013/01/05 06:44:27 24236   4390912         0   4918712      0      0         0         0      4
    Date       Time     VMID  EU        OU        PU        YGC    FGC    YGCT      FGCT      THREAD
    2013/01/05 06:44:30 24236         0         0   4919664      1      0     12604         0      4
    
    more jvmlist.txt
    
    - pid: 24236
      java.property.java.version: 1.6.0_22
      sun.rt.javaCommand: JStatm -p jvmlist.txt 3 2

関連情報
--------

1. [Javaのプロセス情報を取得](http://blogs.wankuma.com/kacchan6/archive/2007/08/29/92501.aspx)
2. [MonitoredHost (Jvmstat)](http://openjdk.java.net/groups/serviceability/jvmstat/sun/jvmstat/monitor/MonitoredHost.html)

ライセンス
----------
Copyright &copy; 2012  Getperf Ltd.
Licensed under the [GPL license][GPL].
 
[GPL]: http://www.gnu.org/licenses/gpl.html
