@echo off

set JSTATM_HOME=%~dp0
set JAVA_HOME=C:\j2sdk1.4.2_06
set PATH=%JAVA_HOME%\bin;%PATH%
set CLASSPATH=%CLASSPATH%;%JSTATM_HOME%\lib\JStatm.jar;%JSTATM_HOME%\lib\basic.jar;%JSTATM_HOME%\lib\configurepolicy.jar;%JSTATM_HOME%\lib\jvmps.jar;%JSTATM_HOME%\lib\jvmsnap.jar;%JSTATM_HOME%\lib\jvmstat.jar;%JSTATM_HOME%\lib\jvmstat_graph.jar;%JSTATM_HOME%\lib\jvmstat_util.jar;%JSTATM_HOME%\lib\perf.jar;%JSTATM_HOME%\lib\perfagent.jar;%JSTATM_HOME%\lib\perfagentstubs.jar;%JSTATM_HOME%\lib\perfdata.jar;%JSTATM_HOME%\lib\visualgc.jar

java JStatm %1 %2 %3 %4 %5
