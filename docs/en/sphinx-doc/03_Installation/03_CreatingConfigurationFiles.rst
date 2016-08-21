Creating a configuration file
==================

Run the automatic generation script cre_config.pl of configuration files.

::

    cd $ GETPERF_HOME
    perl script / cre_config.pl

Of $ GETPERF_HOME / conf will generate a configuration file under. For more information `definition of the configuration file <docs / ja / docs / 11_Appendix / 01_Configuration.md>` _ Please refer to.

1. getperf_site.json: Getperf main configuration file of
2. getperf_cacti.json: configuration file for the monitoring software Cacti
3. getperf_rrd.json: configuration file for the time-series database RRDtool
4. getperf_zabbix.json: monitoring software Zabbix configuration file
5. getperf_graphite.json: configuration file for the time-series database Graphite

5 of the setting is disabled by default and, if necessary, please enable the value of a configuration file

getperf_site.json
------------------

And the base setting of Getperf, and set the various installation software property of.

::

    vi config / getperf_site.json

Getperf home directory, and the log output setting. From the point of view of security, please change the MySQL root password of "GETPERF_CACTI_MYSQL_ROOT_PASSWD".

::

    "GETPERF_CACTI_MYSQL_ROOT_PASSWD": ​​"XXX",

getperf_cacti.json
-------------------

Placement of the graph monitoring tool Cacti, and the configuration version of. Getperf modules are dependent on Cacti version of the specified. For Cacti has no capability of downgrade, you will not be able to specify a lower version than the default value. Please specify a higher level of version if necessary.

getperf_rrd.json
-----------------

Li retention period of time-series database RRDtool, and the setting of the counting period.
The retention period will be less by default, please if necessary to edit the changes.

- The most recent details are kept for one day at a sampling of the 2-minute interval
- Held the last week of 8 days at a sampling of 15-minute intervals
- Hold the most recent one month is 31 days at a sampling of 60-minute intervals
- More than that held 730 days at a sampling of the day

getperf_zabbix.json
--------------------

And the integrated monitoring software Zabbix configuration of open source.

::

    vi config / getperf_zabbix.json

Installation of this software is optional, the default is enabled. Please to the case to disable it, the "GETPERF_AGENT_USE_ZABBIX" to 0.

::

    "GETPERF_AGENT_USE_ZABBIX": 1

Also, if you want to enable from the point of view of security, please change the password "ZABBIX_ADMIN_PASSWORD" of the administrator user admin of Zabbix Web console

::

    "ZABBIX_ADMIN_PASSWORD": "getperf",

getperf_graphite.json
----------------------

And the setting of time-series database Graphite.

::

    vi config / getperf_graphite.json

Installation of this software is optional, the default is invalid. If you enable, please to 1 "GETPERF_USE_GRAPHITE". Graphite will be state of the α release.

::

	GETPERF_USE_GRAPHITE": 1
	