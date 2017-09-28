Java VM statistics (Jvmstat) monitoring template
======================================

Jvmstat monitoring
-----------------

* Heap utilization of JavaVM instance on the Linux or Windows server, and then collect the GC statistics.
* Support the Java 1.5 or higher
* Collect the Java Virtual Machine (JVM) statistical information using [jstat API](https://docs.oracle.com/javase/jp/6/technotes/tools/share/jstat.html).

File organization
-------

Necessary configuration files to the template is as follows.

|             Directory             |        file name         |             Applications            |
|-----------------------------------|--------------------------|-------------------------------------|
| lib/agent/Jvmstat/conf/           | ini file                 | agent collecting configuration file |
| lib/agent/Jvmstat/script/         | jstatm module            | agent collected script              |
| lib/Getperf/Command/Site/Jvmstat/ | pm file                  | data aggregation script             |
| lib/graph/Jvmstat/                | json file                | graph template registration rules   |
| lib/cacti/template/0.8.8g/        | xml file                 | Cacti template export file          |
| Script /                          | create_graph_template.sh | graph template registration script  |

Install
=====

Build Jvmstat template
-------------------

Clone the project from Git Hub

```
(Git clone to project replication)
```

Go to the project directory, - and the initialization of the site with the template option

```
cd t_Jvmstat
initsite --template.
```

Run the Cacti graph templates created scripts in order

```
./script/create_graph_template.sh
```

Export the Cacti graph templates to file

```
cacti-cli --export Jvmstat
```

Aggregate script, graph registration rules, and archive the export file set Cacti graph templates

```
sumup --export = Jvmstat --archive=$GETPERF_HOME/var/template/archive/config-Jvmstat.tar.gz
```

Import of Jvmstat template
---------------------

Was created in the previous $ GETPERF_HOME / var / template / archive / config-Jvmstat.tar.gz becomes archive of Jvmstat template,
Import using the following command on the monitoring site

```
cd {monitoring site home}
sumup --import=Jvmstat --archive=$GETPERF_HOME/var/template/archive/config-Jvmstat.tar.gz
```

Import the Cacti graph templates.

```
cacti-cli --import Jvmstat
```

To reflect the imported aggregate script, and then restart the counting daemon

```
sumup restart
```

How to use
=====

Agent Setup
--------------------

The following agent collecting configuration file and copy it to the monitored server, please re-start the agent.

```
cd {site home}/lib/agent/Jvmstat/
scp -rp * {monitored server user}@{monitored server}@~/ptune/
```

Customization of data aggregation
--------------------

After the agent setup, and data aggregation is performed, site home directory of the lib/Getperf/Command/Master/Jvmstat.pm file under will be generated.
This file is the master definition file of monitored storage, to describe the use of the Java VM instance.
Please customize an example Jvmstat.pm_sample under the same directory.

Graph registration
-----------------

After the agent setup, and data aggregation is performed, site node definition file under the node of the home directory will be output.
Specify the output file or directory and run the cacti-cli.

```
cacti-cli node/Jvmstat/{JavaVM instance}/
```

AUTHOR
-----------

Minoru Furusawa <minoru.furusawa@toshiba.co.jp>

COPYRIGHT
-----------

Copyright 2014-2016, Minoru Furusawa, Toshiba corporation.

LICENSE
-----------

This program is released under [GNU General Public License, version 2](http://www.gnu.org/licenses/gpl-2.0.html).
