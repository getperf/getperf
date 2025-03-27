jstatm
======

Using the API of jvmstat, to display the heap information of JavaVM in the local host. It outputs a similar report to jstat -gc command.
If you are monitoring more than one instance,
The information for all instances be collected in the one command.

Installation
------------

JDK1.5 or higher is required. If you use the JDK1.4, please refer to the [jstatm14].

[Jstatm14]: https://github.com/getperf/t_Jvmstat.git

    git clone https://github.com/getperf/t_Jvmstat.git
    cd jstatm
    ant

How to use
--------

    cd dest
    ./jstatm.sh -h
    usage: java JStatm [-p [vm report file]] [-o [output.txt]] [-d [debug.txt]] [interval] [count]

+ `-p File`:
    JavaVM of PID, command, list of execution options

+ `-o File`:
    Heap information output file of JavaVM
 
+ `-d File`:
    Debug log output options
 
+ `Interval`:
    Harvest interval [sec]

+ `Count`:
    Number of executions

### Example of use ###

    ./jstatm.sh -p jvmlist.txt -o report.txt 3 2

    more report.txt

    Date Time VMID EU OU PU YGC FGC YGCT FGCT THREAD
    2013/01/05 06:44:27 24236 4,390,912 0 4,918,712 0 0 0 0 4
    Date Time VMID EU OU PU YGC FGC YGCT FGCT THREAD
    2013/01/05 06:44:30 24236 0 0 4919664 1 0 12604 0 4
    
    more jvmlist.txt
    
    - Pid: 24236
      java.property.java.version: 1.6.0_22
      sun.rt.javaCommand: JStatm -p jvmlist.txt 3 2

Related information
--------

1. [Get process information of Java](http://blogs.wankuma.com/kacchan6/archive/2007/08/29/92501.aspx)
2. [MonitoredHost (Jvmstat)](http://openjdk.java.net/groups/serviceability/jvmstat/sun/jvmstat/monitor/MonitoredHost.html)

License
----------

Copyright & copy; 2014-2015, Minoru Furusawa , Toshiba corporation.

Licensed under the [GPL license] [GPL v2].
 
[GPL v2]: http://www.gnu.org/licenses/gpl.html
