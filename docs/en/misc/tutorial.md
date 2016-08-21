Tutorial for the customizing steps of your monitoring site.
===========================================================

1. Set collection commands of the agent
2. Coding script of aggregate collection data on the monitoring server
3. Confirm results
4. Create graphs

I explain HW resource collection command of Linux of the standard function as reference here.

1. Set collection commands of the agent
=======================================

/Proc/loadavg metric　
--------------------

Make the settings to get the load average of [**/proc/loadavg**](http://web.mit.edu/rhel-doc/4/RH-DOCS/rhel-rg-ja-4/s1-proc-topfiles.html). Execution result of this command is as follows.

    cat /proc/loadavg
    0.19 0.42 0.30 1/433 21868

Since the execution cycle of Linux domain is 300 seconds , set to run 10 times this command at 30 second  intervals. Add this command on the List of collection command.

    vi ~/ptune/conf/HW.ini

    # Collection command list
    STAT_CMD.Linux = '/usr/bin/vmstat -a 5 61',   vmstat.txt
    STAT_CMD.Linux = '/usr/bin/free -s 30 -c 12', memfree.txt
    STAT_CMD.Linux = '/usr/bin/iostat -xk 30 12', iostat.txt
    STAT_CMD.Linux = '/bin/cat /proc/net/dev',    net_dev.txt, 30, 10
    STAT_CMD.Linux = '/bin/df -k -l',             df_k.txt
    STAT_CMD.Linux = '/bin/cat /proc/loadavg',    loadavg.txt, 30, 10   ;

Restart the agent to reflect the setting.

    ~/ptune/bin/getperfctl stop
    ~/ptune/bin/getperfctl start

Results of loadavg
------------------

After starting the agent, command execution results are stored in the following directory,

    cd ${AGENT_HOME}/ptune
    ls log/Linux/20150526/140000/
    df_k.txt  iostat.txt  loadavg.txt  memfree.txt  stat_Linux.log  net_dev.txt  vmstat.txt

All of the collection command has been completed, 'stat_Linux.log' file will be execution history of the command including start and end time of commands, processID and the exit cod in YAML format.

2. Aggregate collection data on the monitoring server
=====================================================

Confirm the agent transfer data
-------------------------------

Confirm '/proc/loadavg' results.
The agent fowards in zip format results to analysis of site directory in 300 seconds periods (10 times at 30 second intervals).
After 300 seconds, unzip results data and confirm loadavg.txt under the latest date directory.

    cd (site directory)/site1
    ls analysis/localhost/Linux/20150612/162000/
    df_k.txt    loadavg.txt  net_dev.txt     vmstat.txt
    iostat.txt  memfree.txt  stat_Linux.log

Sumup command
-------------

Use the 'sumup' script for customizing the aggregate data. Displays help by the -h option.

    sumup -h

    Unknown option: h
    No input path
    Usage : sumup.pl
            [--init] [input file or directory]
            [--daemon] [--recover|--fastrecover]
            [--info|--auto|--manual]
            [start|stop|restart|status]

    '--daemon' options run the zip directory monitoring in the foreground.
    If you execute as daemon process, Run 'start' command.

Definitions of each option are as follows.

[--init] [input file or directory]
: Aggregate data manually, specify a file or directory under analysis. the wild card is available.
Add a '--init' option to create a  ** template ** aggregation script of the specified file.

[--daemon] [--recover|--fastrecover]
: Monitor the storage directory for zip transfer data. In event-driven, when update the zip file, decompression zip files, aggregate data, load, and save the metric definition.
--recover option performs a series of aggregation processing from the zip thawing for all zip files that are saved.
--fastrecover option aggregates the most recent zip files.
These options will be used to recover the data.

[--info|--auto|--manual]
:Outputs the site information, such as access key.
--auto otion, automatically aggregate data when OS start-up, -manula option, aggregate data manually.

[start|stop|restart|status]
: The management command when you start the aggregate data as a daemon process, contlrol atart and stop process,


Create an aggregation script from template
------------------------------------------

Create an aggregation script template of loadavg.txt.

    sumup --init analysis/localhost/Linux/20150612/162000/loadavg.txt

After running the above command, following scripts are made under the lib directory.

    vi lib/Getperf/Command/Site/Linux/Loadavg.pm

From the 24 line, in a while statements, read the aggregation data.
Run this script.

    sumup analysis/localhost/Linux/20150612/162000/loadavg.txt

    0.91 0.42 0.16 1/399 29358
    0.55 0.38 0.15 1/399 29369
    0.33 0.34 0.15 1/399 29378
    (＊snip＊)

It becomes the result of the yelling reading line as it is printed. Operating mechanism of this process is as follows. In the script, add these functions,

* define metric
* aggregate data
* load the data
* save the metric definition

Edit and modify this script as follows,

     1: package Getperf::Command::Site::Linux::Loadavg;
     2: use strict;
     3: use warnings;
     4: use Data::Dumper;
     5: use Time::Piece;
     6: use base qw(Getperf::Container);
     7:
     8: sub new {bless{},+shift}
     9:
    10: sub parse {
    11:     my ($self, $data_info) = @_;
    12:
    13:     my %results;
    14:     my $step = 5;
    15:     my @headers = qw/load1m load5m load15m/;                # 1. Define the header
    16:
    17:     $data_info->step($step);                                # 2. Set the sampling interval
    18:     my $host = $data_info->host;                            # 3. Get the agent name
    19:     my $sec  = $data_info->start_time_sec;                  # 4. Get start time of the command
    20:     if (!$sec) {
    21:         return;
    22:     }
    23:     open( IN, $data_info->input_file ) || die "@!";
    24:     while (my $line = <IN>) {
    25:         next if ($line=~/^\s*[a-z]/);   # skip header
    26:         $line=~s/(\r|\n)*//g;           # trim return code
    27:         $line=$1 if ($line=~/^(\S+\s+\S+\s+\S+)\s+/);       # 5. Parse the line read
    28:         my $timestamp = localtime($sec)->datetime;
    29:         $results{$timestamp} = $line;
    30:         $sec += $step;
    31:     }
    32:     close(IN);
    33:     $data_info->regist_metric($host, 'Linux', 'loadavg', \@headers);    # 6. Register metric
    34:     $data_info->simple_report('loadavg.txt', \%results, \@headers);     # 7. Save aggregation data
    35:     return 1;
    36: }
    37:
    38: 1;

1. Define the header
In the loadavg, define 1-3 column as load1m, load5m, load15m.

2. Set the sampling interval
Using step()API, set the sampling command interval. This is where you set to 5 seconds.

3. Get the agent name
Using host()API, get the agent name. The acquired agent name is defined as a node.

4. Get start time of the command
Using start_time_sec() API, get start time of the command.

5. Parse the line read
For parseing the data line, extract the item in the 1-3 column.

6. Register metric
Using the regist_metric () API, register the metric definition.
>From the first argument, specify node name, domain name, metric name, the header information.
This sample has no change, so remove the comment. The registered information is stored under the node directory.

7. Save aggregation data
Using simple_report() API, save aggregation data.
>From the first argument, spcify output file name, result array, the header information.
This sample has no change, so remove the comment. The output files are saved under the summary directory, and loads to RRDTool in post-processing.


3. Confirm results
==================

Confirm results from the edited script running.

    sumup analysis/ostrich/Linux/20150613/072500/loadavg.txt

    2015/06/13 07:34:24 [INFO] command : Site::Linux::Loadavg
    2015/06/13 07:34:24 [INFO] load row=10, error=(0/0/0)
    2015/06/13 07:34:24 [INFO] sumup : files = 1, elapse = 0.065638

1 line : package name of the aggregate command
2 line : loading results to RRDTool result
3 line : result summary

Confirm aggregate data results
------------------------------

Aggregate results are saved in 'summary/{agent}/{date}/{time}/{metric}.txt'

    more summary/ostrich/Linux/20150613/072500/loadavg.txt
    timestamp load1m load5m load15m
    2015-06-13T07:25:24 0.10 0.09 0.13
    2015-06-13T07:25:29 0.06 0.08 0.13
    2015-06-13T07:25:34 0.31 0.14 0.15
    (snip)

'{metric} .txt'is a as directory path and  will be the first argument of simple_report (), it is possible to make a multi-hierarchy in the directory.

    $data_info->simple_report('loadavg.txt', \%results, \@headers);

Confirm RRDTool results
-----------------------

Load aggregate results in the data file of RRDTool. RRDTool data is located under the storage directory.

    ls storage/Linux/ostrich/loadavg.rrd

The path format will be the 'storage/{domain}/{node}/{metric}.rrd'.
Parameters specified in the regist_metric () is applied to Domain, Node, and the metric.

    $data_info->regist_metric($host, 'Linux', 'loadavg', \@headers);

In this sample, the node is set equal to the agent's name, can be set diffrent name.
For example, if you want to register the name of the targtet machine to the node, set the name in the first argument as a node.

The domain can be set different name as the same as the node.
For example, aggregate data is Linux DB, set a domain as LinuxDB. When you want to change the settings for each domain during the customization of the graph registration, Use this setting.

Confirm loaded RRDTool data. Use rrdtool info command to check the type.

    rrdtool info storage/Linux/ostrich/loadavg.rrd | grep type
    ds[load1m].type = "GAUGE"
    ds[load5m].type = "GAUGE"
    ds[load15m].type = "GAUGE"

Items specified in the header you have been registered.

Confirm metric definitions
--------------------------

Metric definitions file are stored under the node directory. This file registers the definition which has no dynamic changes.

    more node/Linux/ostrich/loadavg.json
    {
       "rrd" : "Linux/ostrich/loadavg.rrd"
    }

Restart sumup daemon
--------------------

結果の確認ができたら集計スクリプトを再起動をします

	sumup restart

4. Create Load Average graphs
=============================

Create the aggregate results to Cacti graphs.

1. Create a graph-defined rules json file
2. Create Cacti templates
   2-1. Register data source templates
   2-2. Register graph templates
3. Create graphs

In this section, add the load average graph below.

![load average](image/loadavg.png)

Create Graph-defined rules json file
------------------------------------

Create a graph-defined rules json file for difining the aggregate data and Cacti templates as ou wrote a definition file as indicated below,

    vi config/cacti/Linux/loadavg.json

    {
      "host_template": "HW",
      "host_title": "HW - <node>",
      "priority": 1,
      "graphs": [
        {
          "graph_template": "HW - CPU Load Average",
          "graph_tree": "/HW/<node_path>/CPU/Load",
          "graph_items": ["load1m","load5m","load15m"],
          "graph_title": "HW - <node> - CPU Load Average",
          "datasource_title": "HW - <node> - CPU Load Average"
        }
      ]
    }

* Path is the 'config/cacti/{domain}/{metric}.json'.

* Define the Cacti host template and graph templates.

* The Cacti host template will be a group of various templates, groups of HW resources will be 'HW'.

* <node> replaces the node name. <node_path> replace the directory name when the node is defined in the multi-hierarchy in the directory structure,

* "host_title" is defined the appropriate node and registerd as Cacti the device. Each graph of the appropriate nodes will be placed under the device.

* "priority" is, the definition for the priority level for graph creation when you specified the directory such as 'cacti-cli node/Linux/{host}/' .
If you want to place a graph first in the graph menu, and then the priority to 1.

* "graph_template" is the definition of Cacti graph template.

* "graph_tree" is the definition of Cacti graph menu.

* "graph_items" is the graph legends, It must be the same as RRDTool data source name.

* "graph_title", "datasource_title" is the definition of the graph title and data source.

Create Cacti templates
----------------------

Before register graphs,  have to create data source templates of Cacti and graph templates.
Please refer to the [Cacti development site of the document]
(http://docs.cacti.net/manual:088:3_templates#templates).

Use the command cacti-cli. It reads the json file of graph registration rules as defined above , to register the template in Cacti. -g option to create templates , -r option to the specified json file path

    cacti-cli -g -r config/cacti/Linux/loadavg.json

Confirm the graph templates. Select the menu 'Graph Templates' from the Web management console, and select 'HW - CPU Load Average' from the templates list.

![Graph Template 1](image/graph_template1.png)

This is a prototype of graph templates cacti-cli command was created. If necessary, you will edit the graph size , the upper|lower limit, etc.

Create graphs
-------------

Use 'cacti-cli' command for registration of graphs.
Create graphs by the graph-defined rules that you have created before.

    cacti-cli ./node/Linux/ostrich/loadavg.json

Mechanism of this process is as follows.

1. Analyze the node path, '/node/{domain}/{node}/{metric}.json'
2. Read the graph definition rules, '/config/cacti/{domain}/{metric}.json' by the analysis of parameters.3. Create graphs based on the graph-defined rules.

Register graphs, data source and the tree menu. If you want to re-create graphs, add the -f option.

    cacti-cli -f ./node/Linux/ostrich/loadavg.json

Summary
=======

In this tutorial, we introduced the rough flow for the customization of monitoring items.
Please refer to the API reference for more details.

Once you create the script of the agent, the data aggregation and the graph configuration, it will be tempates.
If you create another server, you can use templates and automate the subsequent additional work.
We are aiming for efficient monitoring operation in this approach.

Reference
=========

1. [API Reference](api/api_reference.md)

Copyright (C) Minoru Frusawa 2015 All rights reserved. 
e-mail：frsw3nr@gmail.com

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU LESSER GENERAL PUBLIC LICENSE(LGPL) as published by
the Free Software Foundation; either version 3 of the License, or
(at your option) any later version.
