Site data aggregation
================

how to use
--------

To aggregate the data received from the agent at sumup command. sumup command runs from the move to the site of the site directory of interest. There is a manual and two steps of automatic, manual verification and aggregate processing, done at the time of the customizations that you edit the aggregation script. Automatic site aggregate daemon on the basis of the aggregate definition registered will make the data aggregated at the automatic. When you register a new collection command to the agent, run the 'sumup --init {execution result of the relevant collection command}', to create a model of aggregation script.

::

    sumup -h
    Usage: sumup.pl
            [[--init] {Input file or directory}]
            [[--export = {Domain} | --import = {domain} [--force]] [--tar = {file.tar.gz}]]
            [--daemon] [--recover | --fastrecover]
            [--info | --auto | --manual]
            [Start | stop | restart | status]

    '--daemon' Options run the zip directory monitoring in the foreground.
    If you execute as daemon process, Run 'start' command.

sumup {received data path}
----------------------

Manually perform the data aggregation. First, go to the site directory.

::

    cd ~ / work / site1

To the argument, and then run the sumup command specifying the file path under / analysis. Path are described as the following directory, the designation can be an example of a wild card.

Example: aggregate the Linux for the specified time loadavg collecting data

::

    sumup analysis / {monitored} / Linux / {DATE} / {time} /loadavg.txt

In the case of the directory specified to aggregate all of the files under that directory.

Example: counting all of the files in the specified time of Linux

::

    sumup analysis / {monitored} / Linux / {DATE} / {time} /

Specified in the wild card is also available.

Example: aggregate loadavg collecting data of all monitored Linux

::

    sumup analysis / * / Linux / * / * / loadavg.txt

option
----------

--init {received data path}
～～～～～～～～～～～～～～～～～～～～～～～～

It is the option to create a model of data aggregation script. If you add a new collection command on the agent side, to create a model of aggregation script of a new collection command in monitoring the server side. You specify that you want to perform a result of the path taken command by adding the --init option. For example, an example of creating when you add a new uptime command in the Linux environment will be less.

Example: uptime.txt aggregate script template created

::

    sumup --init analysis / {monitored} / Linux / {DATE} / {time} /uptime.txt

Above, a script called lib / Getperf / Command / Site / Linux / Uptime.pm is created. Edit this script to the definition of the data aggregation. For more information on script editing, `data aggregation customize <../ 06_CustomizeDataCollection / 01_GettingStarted.html>` _ Please refer to.

--export = {domain} --tar = {file.tar.gz}
～～～～～～～～～～～～～～～～～～～～～～～～～～～～～～～～～～～～～

Export the definition information for the specified domain. Export file is used when you want to copy (import) the definition to the other site. A domain, Linux, the enclosed aggregate data, such as Windows, the node definition, aggregate definition, graph definition, all of the definitions such as Cacti template belongs to a certain domain. To the file specified by --tar option
And compressed in a tar.gz format.

Example: Export of Linux domain

::

    sumup --export = Linux --tar = / tmp / domain-export-linux.tar.gz

For the files to export, the directory is as follows.

1. aggregate definition (lib / Getperf / Command / Site / {domain} /)
2. graph definition (lib / graph / {domain} /)
3. The agent definition (lib / agent / {domain} /)
4. Cacti export file
   (Lib / cacti / template / 0.8.8e / cacti-host-template- {domain} .xml)

4, from Cacti repository database, host template, graph templates, will be the file that you exported the data source template.

.. Note ::

    * Links of domain

        If you want to export in accordance with the relevant domain, by registering the domain you want to link to package_links.json file, exports also collectively linked domain. Aggregate definition, graph definition, in the following format in each directory of the agent definition, to create a package_links.json.

        Example: lib / Getperf / Command / Site / {domain} /package_links.json

        ::

              [
                  "Linked domain name"
              ]

--import = {domain} --tar = {file.tar.gz} [--force]
～～～～～～～～～～～～～～～～～～～～～～～～～～～～～～～～～～～～～～～～～～～～～～～

And the import of the exported file. Done by specifying the domain.

Example: Import of Linux domain

::

    sumup --import = Linux --tar = / tmp / domain-export-linux.tar.gz

Domain will cancel the processing in the case registered. If you want to force a import, - Please add the force option.

--info
~~~~~~

And outputs information about the specified site. Please be sure to use this command if you want to check the access key.

--auto
~~~~~~

Enable the automatic startup of the site aggregate daemon when the OS start-up. The settings are stored under $ GETPERF_HOME / config / site / directory. /etc/init.d/sumupctl
Script to check the settings for each site, in the case of valid to start the site aggregate daemon.

--manual
~~~~~~~~

Disable the automatic startup of the site aggregate daemon OS boot. And the flag definition "auto_aggregate" site configuration file to 0.

--recover
~~~~~~~~~

In the recovery of such data failure, you can use the sumup --recover command if you want to recount of the received data. To ignore the check point of the previous data aggregation processing, and recount all of the data file at the bottom of the received data directory / anlaysis.

.. Note ::

    * Notes: RRD for the update error of data

      RRDtool on the specification, there is a re-registration can not be constraints of past data, - also use the recover option becomes a double registration error update is disabled.

--fastrecover
~~~~~~~~~~~~~

Operation is the same as the --recover but, / anlysis without counting all of the received data under, and recount only the most recent of the received data.

Start / stop of the site aggregate daemon
-----------------------------

Start / stop of the site aggregate daemon also uses sumup command.

sumup [start \ | stop \ | restart \ | status]
～～～～～～～～～～～～～～～～～～～～～～～～～～～～～～～～～～～～

Start-up of the site aggregate daemon, stop, restart, do the status confirmation.

Example: check the status of the site aggregate daemon

::

    sumup status
    Getperf Sumup daemon [Running]
    