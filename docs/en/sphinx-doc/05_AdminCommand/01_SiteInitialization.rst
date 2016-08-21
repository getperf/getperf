For Getperf management command
============================

Getperf
It offers a number of command for the administrative user. This chapter explains how to use these commands.

- Initialization of the site (initsite.pl)
- Site data aggregation (sumup)
- Zabbix monitoring registration (zabbix-cli)
- Of the monitored remote operation (nodeconfig)

For graph registration command cacti-cli of Cacti are described in the registration <../ 07_CactiGraphRegistration / 01_GettingStarted.html> `_` Cacti graph.

Initialization of the site (initsite.pl)
===========================

how to use
--------

In the specified directory and create a monitoring site. Directory must be executed in the state of not yet created. The end of the directory of the specified directory becomes a key site, it will be key information indicating a unique site.

::

    initsite.pl -h
    Usage: initsite.pl {site_dir} [--update] | [- addsite = "AAA, BBB"] | --list

Processing flow
----------

Site initialization performs the following processing.

1. Create Directory

  The following files under the specified directory, create a directory.

  ===================== ============================= =========
  Directory / file applications
  ===================== ============================= =========
  Rexfile Rex script for the monitored operation
  analysis received data directory
  html Cacit site Home
  lib aggregate definition, graph definition directory
  node node definition directory
  script monitored operation for the script directory
  storage accumulation data directory
  summary aggregate data directory
  view view definition directory
  ===================== ============================= =========

  .. Note ::

    Create a directory that you specify at the beginning. If it already exists an error will.

2. Create a summary definition

   An aggregate defined under the lib / Getperf, and then copy the graph defined under the lib / graph. Copy to aggregate definition, graph definition copies Linux, under the template name of the directory for Windows resource monitoring.

3. DB created for Cacti

   Create a Cacti repository database to MySQL. Database name is the key site. Linux, and then import the database that have registered the Windows resource monitoring template.

4. Apache setting for Cacti

   Link the Cacti site home to the Apache HTTP server. URL is: will the 'http // {monitoring server address} / {site} key'.

5. Git Repository Creation

   Create a Git repository. If you want a copy of the site that was created in a different server, run the following git clone command.

   ::

       git clone ssh: // {management user} @ {monitoring server address} / {GETPERF_HOME} / var / site / {site} .git key

option
----------

--update
~~~~~~~~

And the registration of the copied site, etc. git clone. If you have a site of clone in a new monitoring server, Cacti MySQL database, Web server, you will need a set of Web services. Do the synchronization of the site and specify the directory where you run a clone in the --update option. After the execution, it enables access to the Cacti console of the site that you copied from the Web browser.

--addsite
~~~~~~~~~

Add more than one site at the time of key monitoring site creation. The specified value is the list of sites the key to which you want to add in --addsite. This is used to build together in newly one site more than one monitoring site of the existing.

--list
~~~~~~

Lists outputs a site that has been registered.
