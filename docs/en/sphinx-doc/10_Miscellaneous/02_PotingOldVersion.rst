Cooperation with the old version (v1)
========================

Functional overview
--------

Getperf is v2.5, due to design changes, which is the old version (~ v2.4) are not compatible with version. As measures to migrate the old site to the new site, offers a mechanism for data transfer (forward) to the data of the new site of the old site. Functional structure is as follows. \ `Rsync using the <https://ja.wikipedia.org/wiki/Rsync>` _ \ has a synchronized set the zip transfer data of the old site to the new site. Transfer to zip data is being thawed under the specified site home directory, then the data aggregation, data registration, cooperation with each OSS will use the site home of the mechanism of the new site. This mechanism is periodically run in the cron.

.. Figure :: ../image/site_sync.png
   : Align: center
   : Alt: Site Sync

   Site Sync
Upon introduction, the following settings are required in advance.

- In the old monitoring the server side, rsync
   And installation of the daemon, rsync of zip storage directory of the old site
   Set to
- New monitoring the server side, the communication confirmation and the former site data by the rsync command,
   Scheduled start setting of sitesync script

.. Note ::

   New monitoring server side of the aggregate in the scheduled start by cron, it performs a series of processing up to data storage. For processing if you are already running an aggregate daemon is run with a double, please stop the daemon in sumup stop.

Old monitoring server-side settings
------------------

first
~~~~~~~~

Here, briefly of CentOS6, wrote rsync installation procedure due to yum. For such only the basic settings, the setting procedure details developer
`Please check rsync <https://rsync.samba.org/>` _ documents and the like.

Confirmation of the SE Linux
~~~~~~~~~~~~~~~

If the SE Linux is enabled, please disable.

::

    sudo getenforce

Enforcing if available. Or the SE Linux of rsync setting, as follows SE
Disable the Linux.

::

    sudo setenforce 0

Edit the / etc / selinux / config, even when you restart SELinux
Disable the state.

::

    vi / etc / selinux / config

The value of the SELINUX change and save the disabled.

::

    SELINUX = disabled

Installation of rsync
~~~~~~~~~~~~~~~~~~~~

::

    sudo -E yum -y install rsync xinetd

In xinetd configuration, to enable the rsync.

::

    sudo vi /etc/xinetd.d/rsync

Change to disable = no.

And the xinetd launch configuration.

::

    sudo chkconfig xinetd on

rsync setting
~~~~~~~~~~

Set as synchronization of the transfer data storage directory of the old site can be taken. rsyncd.conf
The file and edit as follows example. Here, OS user
pscommon, the group is a user of cacti, old01
You wrote the setting to synchronize the site called.

sudo vi /etc/rsyncd.conf

::

    # Name (site keys of the old site)
    [Archive_old01]
    # Of transfer data storage directory
    path = / home / pscommon / perfstat / _bk
    # Destination permitted IP address (to be able to communicate from the new server)
    hosts allow = 192.168.10.0/24
    hosts deny = *
    list = true
    # Of transfer data owner
    uid = pscommon
    # Owner group of transfer data
    gid = cacti
    read only = false
    dont compress = * .gz * .tgz * .zip * .pdf * .sit * .sitx * .lzh * .bz2 * .jpg * .gif * .png

rsync start
~~~~~~~~~~

After rsync configuration, restart the xinetd, and start the rsync daemon.

::

    sudo /etc/rc.d/init.d/xinetd restart

New monitoring server-side settings
------------------

rsync communication confirmation
~~~~~~~~~~~~~

New monitoring the server side and the communication confirmation of rsync. Similar to the old monitoring server rsync
Please refer to the installation of. After the installation, please refer to the communication check by running the following command. The following, and then copy the data transfer of the old monitoring server under the / tmp directory new monitoring server.

::

    rsync -av --delete \
    rsync: // {old monitoring server address} / archive_ {site} key \
    ./tmp

\ * \ * (Note) SE in the old monitoring the server side
Linux the following authorization error that it is valid is generated \ * \ *

::

    Oct 3 12:28:57 xxx rsyncd [4073]: rsync: chroot / home / pscommon / perfstat / _bk failed: Permission denied (13)

Site synchronization scripts (sitesync) operation check
～～～～～～～～～～～～～～～～～～～～～～～～～～～～～～～～～～～～～～

Above rsync
Once you have the communication confirmation of command in the new monitoring server of the site home directory
sitesync
And make sure that it works in the script itself. The following are, above, after the data synchronization by rsync, moved site home under of data aggregation, make the data registration.

::

    cd {site directory}
    $ {GETPERF_HOME} / script / sitesync rsync: // {old monitoring server address} / archive_ {site} key

When executed correctly, analysis
Collection file of the old site will be saved under. Processing after the data aggregation after this is the same as that of the prior art.

::

    ls analysis / {monitored in the old site}

\ * \ * (Note) sitesync
Script please and then execute the move to the site home directory \ * \ *

Scheduled start in cron
--------------

Above, when you are the same work confirmation of sitesync scripts, cron
Set up the scheduled start by.

::

    0,5,10,15,20,25,30,35,40,45,50,55 * * * * (cd {site directory}; {GETPERF home directory} / script / sitesync rsync: // {old monitoring server address} / archive_ {site key}> / dev / null 2> & 1) &

Work after this, it will be the data aggregation and graph settings as usual.
