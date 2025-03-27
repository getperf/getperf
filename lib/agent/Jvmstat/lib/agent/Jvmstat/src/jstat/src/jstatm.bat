@echo off

set JSTATM_HOME=%~dp0
set JAVA_HOME=C:\jdk1.7.0_79
set PATH=%JAVA_HOME%\bin;%PATH%
set CLASSPATH=%CLASSPATH%;%JSTATM_HOME%\lib\JStatm.jar;%JAVA_HOME%\lib\tools.jar

java JStatm %1 %2 %3 %4 %5
