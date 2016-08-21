.. note::

  Make the correct translation from machine translation

concept
==========

Monitoring by the two approaches
=========================

Getperf is software that combines the monitoring software of multiple open source and has the following features.

* In system monitoring operation is considered that there are two approaches of fault corresponds to the problem analysis, and each provides a different solution.
* Failure correspondence, in the initial failure handling, a comprehensive response is required, use the `Zabbix <www.zabbix.com>`_ as the solution.
* Problem analysis, in the escalation business cause of the fault, as a solution of the analysis, `Cacti <http://www.cacti.net/>`_.
* By dividing the fault corresponds to the problem analysis, fault detection quickly in Zabbix, surely do, perform the cause analysis in Cacti in parallel, will make a long-term plan. By combining the two, to provide efficient solutions to the system monitoring operation.

I thought that the system monitoring operation there are two applications using open source suitable for each, to integrate the system monitoring.

.. list-table:: 
   :widths: 20 40 40
   :header-rows: 1

   * -
     - Incident Management (Zabbix)
     - Problem Analysis (Cacti)
   * - Applications
     - Utilized in the initial failure handling
     - Utilized in the secondary analysis of failure
   * -
     - Known Issues addressed (routine tasks)
     - Deal with unknown problem (atypical work)
   * - Approach
     - E-mail notification of alert
     - Monitoring of the graph
   * -
     - Exhaustive, comprehensive approach
     - Heuristic, refinement while operation
   * - Needs
     - Firmly the mechanism is necessary
     - Flexible mechanism is necessary
   * -
     - Immediacy, need certainty
     - Ad hoc analysis, analysis of large amounts of data

Monitoring business efficiency
==============

Efficiency of the installation work
------------------------

Software configuration management software `Rex <https://www.rexify.org/>`_ the using and installing the various open source monitoring software in the command base. To pre-configured file, version of open source that you want to use, and then set the port, such as the installation directory the properties of each monitoring software to be used. Then performs the installation automatically in batch scripts. By automating the installation process, we will build an efficient and quick system monitoring environment.

Efficiency of the customization work
------------------------

By using the management commands to control a variety of open source monitoring software, automates the monitoring configuration tasks. To model the system monitoring, the node to be monitored, the monitoring data metric, defines a template of monitoring as a domain, set the various open source monitoring software based on the definition. General monitoring software, you must perform configuration tasks in the manual on the Web browser, but it is possible to monitor settings without these manual tasks by execution model of definition and management commands.

.. Figure :: ../image/getperf_model.png
   : Align: center
   : Alt: GetperfModel
