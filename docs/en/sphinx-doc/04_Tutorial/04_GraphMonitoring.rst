Monitoring setting flow
==============

When you start the agent performs the received aggregation processing the data on the site side. The flow will be less.

.. Figure :: ../image/site_data_flow.png
   : Align: center
   : Alt: site data flow

   Site data flow

Data aggregated by 1. site aggregates daemon

   Web service receives the data from the agent, do the summary of the data received by the site aggregate daemon. Aggregation processing is possible by the user in the Perl script to add an aggregate processing (customizable). Perl script is by aggregating the received data, and load it into the time series database. In this case, it referred to as the time-series database stored data. In addition, to extract the accompanying information from the received data, to register as a node definition. As an example of incidental information, monitored from the agent in the CentOS `/ proc / cpuinfo <https://www.centos.org/docs/5/html/5.1/Deployment_Guide/s2-proc-cpuinfo.html>` _ of If you receive the results, counting script for cpuinfo extracts the CPU configuration information (such as the processor model), to register as a node definition. View definition will be used to narrow down the placement order and nodes of the node of the monitoring screen in the node list.

2. manual registration of the management command

   Aggregate defined in the aggregated node definition, based on the view definition, and the registration to each monitoring software using the management command. Management command offers a dedicated command for each open source monitoring software to be used. Cacti for the management command, was to define the layout and graph configuration of the monitoring screen, and then the graph registration read the graph definition file. Zabbix
   Use management command to register to be monitored on the basis of the node definition.

Checking the site aggregate data
======================

When you start the agent, site aggregation daemon in monitoring the server side is responsible for automatically data aggregation. Details of data aggregation, are described in a later `data aggregation customize <../ 06_CustomizeDataCollection / 01_GettingStarted.html>` _. Here we will look at while checking the actual data whether you are processing in any flow site aggregate daemon.

received data
----------

Here is what it should monitor wrote a summary example the received data in the case of Linux. Go to the site home to ensure each data file.

::

    cd ~ / work / site1

The agent creates the date of the run-time collection command, the time directory, and save the result under the same directory. After the command is finished, transfer the directory to the monitoring server and zip compression. Monitoring server after receiving the zip file, unzip the bottom of the analysis / {monitored} / {domain}.

Example: confirmation of the received data of Linux domain

::

    ls analysis / {monitored} / Linux / {DATE} / {time} /
    df_k.txt iostat.txt loadavg.txt memfree.txt
    net_dev.txt stat_Linux.log vmstat.txt

Each file is the result of executing the collection command, it is stored in {metric} .txt format. stat_Linux.log will be file that records exit code of each collection command in the execution log of agent body, an error.

Aggregate definition
--------

Aggregate definition and place it in the lib / Getperf / Command / Site / {domain} / {metric} .pm in Perl script. File name and the script of each received data will be of one-to-one configuration. Aggregate script or later of aggregate data, the accumulated data, node definition, and the registration of the view definition.

Example: Aggregate definition of Linux domain

::

    ls lib / Getperf / Command / Site / Linux /
    DfK.pm Iostat.pm Loadavg.pm Memfree.pm
    NetDev.pm PsAux.pm Vmstat.pm

Aggregated data
----------

Aggregate script processing for each of the received data metric. The execution result of the aggregation script of each file is stored in the bottom of the summary directory.

Example: confirmation of aggregate data of Linux domain

::

    ls summary / {monitored} / Linux / {DATE} / {time} /
    device loadavg.txt memfree.txt netDevTotal.txt
    vmstat.txt

In each file aggregate data, it will be the file that describes the time-series data separated by spaces. device directory stores the aggregated data for each device disk, network, etc.. Add the device name in the file name, it will be the format of "{metric name} __ {device name} .txt".

Example: confirmation of aggregate data of Linux domain device

::

    ls summary / {monitored} / Linux / {DATE} / {time} / device /

Accumulated data
----------

Each aggregate data is loaded into the data file of RRDtool of time-series database. Each metric, and then save the stored data file for each device.

Example: confirmation of the accumulated data of the Linux domain

::

    ls storage / Linux / {monitored} /
    device loadavg.rrd memfree.rrd netDevTotal.rrd vmstat.rrd

Reference data with rrdtool command, registration, and management of the schema. By the 'rrdtool info {data file name}', you can see the definition information of the data file.

Example: information confirmation of RRDtool of Linux domain

::

    rrdtool info storage / Linux / {monitored} /loadavg.rrd | grep ds

Node definition
----------

Node definitions are stored under the node in the definition information for each metric. Files are written in JSON format, it describes the path to the RRDtool data file for each metric.

Example: Determining the nodes on the definition of the Linux domain

::

    ls node / Linux / {monitored} /
    device info loadavg.json memfree.json netDevTotal.json
    vmstat.json

node / {domain} / {monitored} / under the info directory recorded the incidental information of the node file anlysis / under the {monitored} / SystemInfo / proc / cpuinfo, the received data, such as / proc / meminfo It will result in the aggregate to the original. In JSON format has a record of each information.

Example: confirmation of the supplementary information of the node definition of Linux domain

::

    ls node / Linux / {monitored} / info /
    arch.json cpu.json mem.json os.json

View definition
----------

View the list of monitored nodes that belong to the domain, and then configure from view / {domain} / empty JSON file in the form of {monitored} .json.

Example: confirmation of Linux domain of the view definition

::

    ls view / _default / Linux /

Cacti graph registration
================

And the graph registered in Cacti monitoring site using cacit-cli command. cacti-cli more information and a description in the registration <../ 07_CactiGraphRegistration / 01_GettingStarted.html> `_` Cacti graph. Here's a graph registration on the basis of the previous section of the data.
Graph registration is done by specifying the path of the node definition. Specifying the path There are several patterns and note the execution example below.

Graph definition
----------

cacti-cli command refers to the graph definition file, and set the layout of the graph to be registered. Graph definition, under the lib / graph / {domain} directory, are stored for each metric, the graph of the title, the placement of the graph menu, definitions, such as the legend of the graph has been recorded. This definition will be the rule definition of graph registration.

Example: Defining graph of Linux domain

::

    ls lib / graph / Linux /
    diskutil.json iostat.json loadavg.json memfree.json
    netDev.json ps.json template vmstat.json

Cacti site
------------

Graph that has been registered from the Web browser, make sure to open the URL of the following Cacti site. Login admin user, password, please login at the admin.

::

    http: // {monitoring server address} / site1 /

.. Note ::

    * About screen layout display collapse in Internet Explorer

      In the version of the above Cacti-0.8.8c There is a problem that appears collapsed screen layout on the screen of the graphs tab. In that case
      `Cacti patching <../ 10_Miscellaneous / 07_CactiPatch.html>` _ to the reference, please apply the patch for Cacti.

Graph registration
----------

If you want to create a graph of individual metrics, cacti-cli
Please specify the path to the JSON file to run option.

Example: graph registration of Linux loadavg metric

::

    cacti-cli node / Linux / {monitored} /loadavg.json

If you want to graph registration of all of the metrics to be monitored, please specify the path to the 'node / {domain} / {monitored}'.

Example: Linux graph registration of monitored all metric

::

    cacti-cli node / Linux / {monitored} /

If you want to graph registration of all of the monitored belonging to the domain, please specify the path to the 'node / {domain}'.

Example: Linux all monitored graph registration

::

    cacti-cli node / Linux /

.. Note ::

    * For Overwrite existing graph

      If the graph to be registered already exists, cacti-cli command cancels the registration without an update of the graph. If you want to force the update, - Please add the force option

Zabbix monitoring registration
===============

To Zabbix monitoring site using zabbix-cli command to the registration of the monitored. It specifies the path of the node as well as cacti-cli. Registration becomes a monitored unit, done by specifying the directory path of the 'node / {domain} / {monitored} /'.

IP address setting of the monitored
------------------------

zabbix-cli will register the IP address of the monitored in Zabbix. If you from the name of the monitored in such DNS not provision the IP address, (site home) /. In the hosts file, you must be registered with the IP address. IP, please register an IP address to .hosts file in the order of the monitored name.

::

    vi .hosts

    XXX.XXX.XX.XX {monitored}

.. Note ::

    * For monitored name

      Monitored name that describes the .hosts must be the same as the monitored directory name of the node defined path.
      Monitored directory name of the node defined path has the following conversion from the actual host name.

      - Uppercase letters converted to lowercase
      - Remove the suffix part of the domain (such as .your-company.co.jp)

Zabbix monitoring registration
---------------

zabbix-cli [--add \ | --rm \ | --info] using the {node-defined path} command
And the registration of Zabbix. Zabbix in the following command
And the confirmation of the registration information.

Example: confirmation of Linux monitored Zabbix registration information

::

    zabbix-cli --info ./node/Linux/ {monitored} /

The actual registration will be following command.

Example: Linux monitored Zabbix registration

::

    zabbix-cli --add ./node/Linux/ {monitored} /

cacti-cli
Similarly, in the case of the specified domain and, to register all monitored belonging to the domain. Detail is
`Zabbix monitoring registration <../ 05_AdminCommand / 03_ZabbixHostRegist.html>` are described in _.

Zabbix site
-------------

From the Web browser, make sure the monitoring item to open the URL of the following Zabbix monitoring site. Login admin user, password
Please log in with $ GETPERF_HOME / conf / password noted getperf_zabbix.json.

::

    http: // {monitoring server address} / zabbix

zabbix-cli command is the only set of monitored monitoring and trigger based on the template. Customization and the template, the trigger of the notification destination is done manually from the Web management screen.
