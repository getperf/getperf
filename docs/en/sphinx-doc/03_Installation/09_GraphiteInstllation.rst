Graphite installation (optional)
================================

Editing of getperf_graphite.json configuration file
-----------------------------------------

When the open-source and the installation of the series database Graphite. This software is the default becomes the option is disabled.
First, to enable edit the getperf_graphite.json configuration file.

::

    cd $ GETPERF_HOME
    vi config / getperf_graphite.json

Installation features of Graphite is still become the α release, there is a possibility that changes to specifications. Unless otherwise desired specified, the editing of value only the following items.

- GRAPHITE_DB_PASS

   Password of the event for the MySQL database management. Please change the default value from the point of view of security.

- GETPERF \ _USE \ _GRAPHITE

   Change to 1 to enable the Graphite.

Graphite installation
---------------------

Graphite and install the server set. And the installation from the EPEL repository.

::

    sudo -E rex prepare_graphite

Start the data registration for the daemon process carbon-cache of Graphite.

::

    sudo service carbon-cache restart
    sudo chkconfig carbon-cache on

Graphite setting
-----------------

To set the retention of stored data as needed.

::

    sudo vi /etc/carbon/storage-schemas.conf

The following examples are for 8 days interval of 5 seconds, 5 minutes for 90 days, will be the setting for holding a 60-minute five years.

::

    [Default_1min_for_1day]
    pattern =. *
    retentions = 5s: 8d, 5m: 90d, 60m: 5y

To reflect the setting, and then restart the carbon-cache.

::

    sudo service carbon-cache restart

Check the operation of Graphite
-------------------

Behavior to confirm the post-installation following confirmation.

- 'Ps -ef \ grep carbon' in the daemon process Make sure that you have started.
- In the 'sudo tail -f /var/log/carbon/console.log' check the logs.
- From the Web browser 'http: // {server address}: 8081 /' the open to ensure management console screen.

This completes the installation of Graphite.
