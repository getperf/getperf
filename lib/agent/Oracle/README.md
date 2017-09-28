Oracle monitoring template
==========================

Oracle monitoring
-----------------

Monitoring of the Oracle performance statistics, Oracle table space utilization, and the Oracle alert log.

* Supports Oracle R11, R12.
* At the time of data collection to perform the service IP of the check, and the data collected for the operation system of the HA configuration.
* Multiple server, in the case of a multi-instance DB, you collected the data of multiple DB via SQL*Net from a single agent.
* Oracle performance survey for the package Statspack or, use the AWR (Note 1).
    - In Statspack level 5 or higher, to display the SQL rankings chart.
    - In Statspack level of 7 or more, to display the object access ranking graph.
* Use the Zabbix, and the threshold monitoring of table space usage of Oracle (Note 2).
* And Zabbix, using Zabbix agent, and the Oracle alert log monitoring (Note 2).

**Note**

1. Statspack must be pre-installed. When you use the AWR will require a specific license. Please refer to the [Oracle Corporation website](http://www.oracle.com/technetwork/jp/articles/index-349908-ja.html) for more information.
2. Enable the Zabbix monitoring option, you will need Zabbix server environment. The Oracle alert log monitoring, in addition to the Zabbix server, will be monitored to require the installation of Zabbix agent.

Configuration
-------------

File configuration of the template is as follows.

|            Directory             |         Filename         |            Application             |
|----------------------------------|--------------------------|------------------------------------|
| lib/agent/Oracle/conf/           | ini file                 | Agent command list file            |
| lib/agent/Oracle/script/         | Script                   | Agent Collecion script             |
| lib/Getperf/Command/Site/Oracle/ | Perl                     | Data Aggrigation script            |
| lib/graph/Oracle/                | json file                | Cacti graph template rule          |
| lib/zabbix/Oracle.json           | json file                | Zabbix template rule               |
| lib/cacti/template/0.8.8g/       | xml file                 | Cacti template export file         |
| script/                          | create_graph_template.sh | Graph template registration script |

Metric
------

Monitoring item definitions such as Oracle performance statistics graph is as follows.

| Key | Description |
| --- | ----------- |
| **Performance Statistics** | **Oracle performance statistics with Statspack report** |
| Events | **Oracle Event wait time**<br> CPU time / db file scattered read / db file sequential read / SQL\*Net message from dblink / log file sync / ...|
| Loads | **Oracle Load profile** <br> Logical reads / Block changes / Physical reads |
| Efficiency | **Oracle Cache hit%** <br> Buffer Nowait % / Redo NoWait % / Buffer Hit % / Library Hit % / Latch Hit % ... |
| Redo | **Oracle Redo size** <br> 1秒あたりのOracle Redo log transfer size |
| Transactions | **Oracle transactions**<br> transactions/sec |
| Executes | **Oracle SQL execitions**<br> sql executions/sec |
| **Table space usage**| **Oracle Table space** |
| Segment size | **Oracle Segment size**<br> Table / Index / Etc |
| Table　space size | **Oracle Tablespace usage**<br> Tablespace limit check in Zabbix |
| **SQL Ranking** | **SQL Ranking with Statspack report** |
| SQL | **Oracle SQL Ranking**<br>SQL CPU Time Ranking / SQL Buffer Get Ranking / SQL Disk Read Ranking |
| Object access | **Oracle Object Access Ranking**<br>Object Logical Read Ranking / Object Physical Read Ranking / Object Physical Write Ranking |
| **Log monitor**| **Event log** |
| Alert log | **Oracle Alert log monitor**<br> Oracle Alert log monitoring with Zabbix |

Install
=======

Build the template
--------------------

Clone the project from Git Hub.

```
git clone https://github.com/getperf/t_Oracle
```

Go to the project directory, initialize the site with the --template options.

```
cd t_Oracle
initsite --template .
```

Run the Cacti graph templates creation script.

```
./script/create_graph_template__Oracle.sh
```

Export the Cacti graph templates.

```
cacti-cli --export Oracle
```

Archive the aggregate script, graph registration rules, export file and Cacti graph templates.

```
mkdir -p $GETPERF_HOME/var/template/archive/
sumup --export=Oracle --archive=$GETPERF_HOME/var/template/archive/config-Oracle.tar.gz
```

Import Template
------------------------

Unzip the archive file that you created in the previous to the monitoring site.

```
cd {Monitoring site home}
tar xvf $GETPERF_HOME/var/template/archive/config-Oracle.tar.gz
```

Import the Cacti graph templates.

```
cacti-cli --import Oracle
```

To reflect the imported aggregate script, Restart the counting daemon.

```
sumup restart
```

Agent Setup
========================

Deploy the scripts
--------------------

Deploy the Oracle data collection library to the Oracle instance to be monitored.
Copy the file the following directory of the monitoring site to the monitored agent home directory.

```
ls lib/agent/Oracle/
conf  script
scp lib/agent/Oracle/* {OS User}@{Oracle instance}:~/ptune/
```

Configuring the agent OS user environment
-----------------------------------------

Work from here is done on the server where the agent to be monitored is running.
So that you can Oracle command is run, such as sqlplus to the agent running OS user, set the Oracle environment variables.
Copy the following Oracle home environment variable settings file.

```
sudo ls -la ~oracle/.profile_orcl
-rwxrwxr-x 1 oracle oinstall 2091  5月 20 06:20 2016 /home/oracle/.profile_orcl
```

Copy the environment variable settings file in the following path under the Agent's home directory, and give the reference authority.

```
sudo cp ~oracle/.profile_orcl ~/ptune/script/ora12c/oracle_env
sudo chmod a+r ~/ptune/script/ora12c/oracle_env
```

Reads the copy environment variable settings file, and make sure that it works with a connection sqlplus the agent running OS user.

```
source ~/ptune/script/ora12c/oracle_env
sqlplus perfstat/perfstat
```

Once you connect, and then quit sqlplus in 'quit.

Set in the case of the HA configuration
---------------------------------------

For servers in HA configuration,
it is necessary to set to perform a pre-check so as to run only in the data collecting operation system of the server. 
Edit the check script hastat.pl.

```
vi ~/ptune/script/hastat.pl
```

Set the string pickled Oracle instance and service IP to be monitored in the following example.

```
my %services = (
        '192.168.0.1' => 'orcl',
);
```

Setting of Statspack / AWR
--------------------------

Under the agent home directory, edit the conf/Oracle.ini configuration file, Statspack or, to set the execution options of data collection script of AWR.

**Notes**

The default configuration file Oracle.ini is enabled Statspack, setting of AWR has commented out.
If you want to use the AWR will be described later, comment out the setting of Statspack, please enable the setting of the AWR.

**Statspack Case**

Edit the following line in the Oracle.ini file.

```
; Performance report for Statspack
STAT_CMD.Oracle = '_script_/sprep.sh ...
```

Edit Statspack data collection options in the row sprep.sh script. Its execution options are as follows.

```
sprep.sh [-s] [-n purgecnt] [-u user/pass[@tns]] [-i sid]
           [-l dir] [-r instance_num] [-d ora12c]\n
           [-v snaplevel] [-e err] [-x]
```

* -s

    Run the Statspack snapshot.

* -n {purgecnt}

    In the number of generations specified number and delete Statspack snapshot data. The default value is 0, it does not delete.

* -u {user}/{pass}[@tns]

    Set the Statspack connection information.

* -i {sid}

    Specify the Oracle instance name.

* -l {dir}

    Specify the save directory of Statspack report. Typically, the setting in Oracle.ini specifies the '\_odir\_' macro.

* -r {instance_num}

    In the case of an Oracle RAC configuration, you specify the instance number.

* -d {dir}

    In {エージェントホーム}/ptune/script directory, Specify the SQL directory of each Oracle version. The default is ora12c.

* -v {snaplevel}

    Run the snapshot at the snapshot level of the specified number.

* -e {errorfile}

    Specify the output file of the error log.

* -x

    If you specify, it does not perform the server checks the operating system of the HA configuration. Specify if you want to remote collected over the network.

**AWR Case**

Edit the following line in the Oracle.ini file.

```
; Performance report for AWR
;STAT_CMD.Oracle = '_script_/awrrep.sh -l _odir_ -d ora12c -v 1'
;STAT_CMD.Oracle = '_script_/chcsv.sh  -l _odir_ -d ora12c -f ora_sql_topa'
;STAT_CMD.Oracle = '_script_/chcsv.sh  -l _odir_ -d ora12c -f ora_obj_topa'
```

Edit the AWR reports collected options in the row awrrep.sh script.
awrrep.sh run option becomes less, the definition of the value is the same as sprep.sh.

```
awrrep.sh [-u user/pass[@tns]] [-i sid]
          [-l dir] [-d ora12c] [-v snaplevel] [-e err] [-x]
```

AWR Unlike Statspack, AWR run the schedule the snapshot and deletion in the AWR side.
AWR more information about setting up and operation of the Please refer to the [Oracle Corporation website](https://blogs.oracle.com/oracle4engineer/entry/column_howtouse_awr).

Grant of reference Oracle alert log
-----------------------------------

**Notice**

For the Oracle alert log monitoring by the Zabbix agent, Add privileged to refer the log file. This function is optional, if you do not want to use the log monitoring the following configuration is required.

Change the reference authority to the Oracle alert log can be accessed by the agent run OS user. Check the access rights of the alert log.
Or less and the database name in the ORACLE_BASE environment variable is "/u01/app/oracle" in the example, if your SID is "orcl", the output destination of the alert log, will be the following.

```
sudo ls -l /u01/app/oracle/diag/rdbms/orcl/orcl/trace/alert_orcl.log
-rw------- 1 oracle oinstall 207816  6月 26 09:05 2016 /u01/app/oracle/diag/rdbms/orcl/orcl/trace/alert_orcl.log
```

Because that is the access authority of the oracle owner only, so that the agent running OS users can access, and privileged to see.

```
sudo chmod a+r /u01/app/oracle/diag/rdbms/orcl/orcl/trace/alert_orcl.log
```

Make sure you can access the agent running OS user.

```
tail /u01/app/oracle/diag/rdbms/orcl/orcl/trace/alert_orcl.log
```

Start the agent
------------------

To reflect the setting, and then restart the agent.

```
~/ptune/bin/getperfctl stop
~/ptune/bin/getperfctl start
```

Cacti graph registration
========================

After the agent setup, and data aggregation is performed, site node definition file under the node of the home directory will be output.
Specify the output node defined directory and run the cacti-cli.

```
cd {site home}
cacti-cli node/Oracle/{Oracle instance}/
```

Zabbix registration
===================

Regist IP to the .hosts file
----------------------------

Without DNS, if your monitoring server host name can not see the IP address, you can set the IP address to the .hosts file.

```
cd {site home}
vi .hosts
```

Please register the IP address in the format of "IP hostname".

Monitoring settings of Zabbix
------------------------------

Run zabbix-cli command, after the confirmation of the settings in the --info option, register with the --add option.

**Setting the Table space threshold monitoring**

```
# Check the registration
zabbix-cli --info node/Oracle/{Oracle instance}/
# Regist the registration
zabbix-cli --add node/Oracle/{Oracle instance}/
```

**Monitoring settings of the Oracle alert log**

```
# Check the registration
zabbix-cli --info node/Linux/{Linux server}/
# Regist the registration
zabbix-cli --add node/Linux/{Linux server}/
```

Others
======

**Notes of Statspack install**

In Statspack operation, you must do a periodic maintenance of Statspack data area.
If you don't maintenance, there is a case of unexpected failure occurs in such as load effect at the time of Statspack run.
Mind the following points, the planned please so as to introduce a Statspack.

1. ensure Statspack only tablespace resources
2. regular collection of Statspack snapshot for statistical information
4. Periodic adjustment of Statspack snapshot threshold

It offers the following script under the ptune / script for Statspack maintenance.

|          Script         |                  Contents                 |
|-------------------------|-------------------------------------------|
| ora_sp_run_stat.sh      | Collect the statistics of snapshot table  |
| ora_sp_tuning_param.sql | Report the Statspack threshold adjustment |

AUTHOR
-----------

Minoru Furusawa <minoru.furusawa@toshiba.co.jp>

COPYRIGHT
-----------

Copyright 2014-2016, Minoru Furusawa, Toshiba corporation.

LICENSE
-----------

This program is released under [GNU General Public License, version 2](http://www.gnu.org/licenses/gpl-2.0.html).
