.. note::

  Make the correct translation from machine translation

System summary
============

System configuration is as follows. Took place of the mask according to the setting file in the options, you can specify the presence or absence of the installation.

.. Figure :: ../image/getperf_config.png
   : Align: center
   : Alt: System Config.

Monitoring agent
----------------

And open source monitoring software Zabbix agents, to place the packaged modules the Getperf agent of self-made.
Getperf agent of self-made has the following features.

- It is coded data collection agent in the C language.
- Work in a multi-threaded, there is a feature a small footprint.
- The communication interface with the monitoring server
   `GSOAP <http://www.cs.fsu.edu/~engelen/soap.html>` use the _.
- Periodically run the command by an internal scheduler, execution result (collecting data)
   Compressed into zip, and forwards it to the monitoring server.
- To simplify the operation, it has become a intuitive and easy-to-understand mechanism.

Data reception
----------

Coded in Java, it is a data reception Web services.

- To transfer the collected data from the monitoring agent to the aggregation side monitoring site.
- To Web services
   `Axis2 <http://axis.apache.org/axis2/java/core/>` use the _.
- Use the Tomcat to the HTTP server Apache HTTP Server, the Web container.

Data aggregation
----------

It has the following features in the aggregate modules using Perl.

- Perl
   Of object container `Object-Container <http://search.cpan.org/dist/Object-Container/>` You can write an aggregate processing with less code using the _.
- Supports change management by Git.
- Supports multi-site ability to manage more than one monitoring site.
- Supports the view function with a filtering and order of change function monitored.
- Zabbix, Cacti
   It supports the monitoring settings working with command-based using the monitoring settings command and management template.

Data accumulation
----------

Accumulation of aggregate data of the time-series database
`RRDtool <http://oss.oetiker.ch/rrdtool/>` use the _. In options
`Graphite <https://github.com/graphite-project> You can add` _ a.
If you added a Graphite, in addition to the data accumulation of RRDtool, data of the same definition to Graphite will be accumulated

Data visualization / analysis
-----------------

- Use Cacti <http://www.cacti.net/> `_ to` monitoring of problem analysis.
- Integrated monitoring to incident management software `Zabbix <http://www.zabbix.com/>` _
   Use the.
- To automate the configuration of these software by using the monitoring configuration commands for each software.
