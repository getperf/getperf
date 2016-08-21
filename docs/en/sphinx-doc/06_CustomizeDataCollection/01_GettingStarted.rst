Flow of data aggregation
================

Upon receipt of the collection command data from the agent, the monitoring server performs the data aggregated at the aggregate definition defining in advance. Its flow is as follows.

.. Figure :: ../image/data_collection.png
   : Align: center
   : Alt: flow of data aggregation

   Flow of data aggregation

1. collection command

   It will be the command list to be executed by the agent. The agent internal scheduler is periodically run the command list, and then transfer the execution results to the monitoring server.

2. Aggregate definition

   Find the aggregate appropriate script from the file name of the received data from the agent. The script summary of the data, when loaded into series database, node definition, and the update of the view definition. Node definition, view definition will be used in the configuration of each monitoring software. The script can be coded in a relatively small code using a dedicated API.

Aggregation model
==========

Collection command, the aggregate-defined settings will require understanding of the following aggregation model. And aggregation model, monitored, in the definition model of monitoring item, based on this model performs data aggregation.

.. Figure :: ../image/data_collection_model.png
   : Align: center
   : Alt: data aggregation model

   Data aggregation model

Agent collected the data model
------------------------------

Category in the execution group definition of internal scheduler, the collection command belonging to the category at the specified interval to periodically run. Collection command has the following two patterns.

1. Local collection

   It will be the setting for collecting internal information of the server, such as vmstat. Command name, execution argument, to register the execution result file. Server to be executed will be monitored.

2. Remote collection

   In collecting setting of the external monitored in such as SNMP and SQL, there is a need to add a label that can identify the external monitored the collection definition. Specified label will be monitored.

Aggregate results of the data model
----------------------

Monitoring server refers to look up the summary appropriate script from the category name and the collection command name of the agent. Domain in the process of counting script received data is applicable, node, metric, and then register each definition of the device.

1. domain

   OS type in the enclosed aggregate data, storage, and define the network, the software names of various M / W as the domain name. In the case of the local harvest, usually, the category name of the agent is the domain.
   The example, Linux, Windows is like. In the case of remote sampling to define the enclosed monitored. For example, if you have the remote in the information taken from the database of the vCenter in a virtualized environment, the domain name is defined for each type of the monitored cluster, host, VM, divided, such as in a data store.

2. node

   In the definition of the monitored, in the case of the local harvest, it will be the agent execution server name. In the case of remote sampling to extract the name of the monitored an aggregate script. From collection command execution results, or to extract the monitored from a file path name of the command execution result. For example, if you want to remote collecting the network equipment in the SNMP, the file name, such as the snmpget__localsw01.txt, and give it a monitoring target name to the end of the file name. Aggregate script to extract the node by analyzing the file name. In addition, the node can be defined in the directory structure of a multi-tier. For example, such as / Tokyo / DB / host01, you can add the monitored areas and applications to the directory. Directory part is used as a group in the registration of the monitoring software.

3. metric

   The name definition of collection command aggregate result, usually the same as the file name of the collection command execution result. Metric is composed of a plurality of elements, it will be the definition that is similar to the schema of the database.

4. The device

   The device will be an additional definition of metrics consisting of a plurality of I / F, such as a disk or network. Register the device name in the list format.

5. view definition

   Define the view in the case of the order and filtering of the monitored node. The default view in the order of registration of monitored, all the nodes are defined view.

6. node definition

   It will be the definition of the additional information to be monitored. For example, to register OS version name or, processor of the model, such as the number of clocks.
   