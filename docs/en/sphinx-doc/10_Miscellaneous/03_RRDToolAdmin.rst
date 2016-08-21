RRDtool management command
===================

This section describes the RRDtool of command operation script (rrd-cli). The main functions are as follows.

* Additional aggregate elements of RRD in the file / Delete
* Create an empty RRD file an existing RRD files to the source

.. Note ::

    This script supports RRDtool v1.5 or higher only. Although the earlier error does not occur,
    It does not function properly. RRDtool v1.5, please refer to the "RRDtool tuning" of the previous section.

how to use
---------------

::

    Usage: rrd-cli
            [--add-Rra | --remove-rra] {rrd_paths} [--interval i] [--days i]
            --create {rrd_path} --from {rrd_path}

Additional aggregate element / Delete
~~~~~~

And the Add / Remove aggregate elements of RRD file. Go to the site home directory, under the storage directory
Specify the RRD file. We wrote the example below.

Adding a summary elements of the 5-second intervals in the eight-day retention in vmstat.rrd file.

::

    rrd-cli --add-rra storage / Linux / {monitored} /vmstat.rrd --interval 5 --days 8

Delete aggregate elements of the 5-second intervals.

::

    rrd-cli --remove-rra storage / Linux / {monitored} /vmstat.rrd --interval 5

Adding together using the wild card is available.

::

    rrd-cli --add-rra storage / Linux / * / vmstat.rrd --interval 5

If you specify a directory to update all of the RRD files below it.

::

    rrd-cli --add-rra storage / Linux / {monitored} / --interval 3600 --days 180

Empty RRD file creation
~~~~~~

Create a new RRD files based on the definition of an existing RRD files.

::

    rrd-cli rrd-cli --create storage / Linux / {monitored} /device/iostat__sdb.rrd --from storage / Linux / {monitored} /device/iostat__sda.rrd

.. Note ::

    In the case of cluster configuration, if the disk still in the node of the standby system is not mounted, RRD file is not created
    If you have any. If this is the case, manually create an RRD file in the above script, to create a pre-empty RRD files.
    