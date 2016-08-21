Zabbix installation
==================

Editing of getperf \ _zabbix.json configuration file
---------------------------------------

And the integrated monitoring software Zabbix installation of open source.
First, edit the configuration file getperf_zabbix.json.

::

    cd $ GETPERF_HOME
    vi config / getperf_zabbix.json

Each setting item noted below.

- ZABBIX_SERVER_VERSION

   Zabbix of LTS (Long Term Support) to specify the 2.2 system, which is a version. By default, it will be 2.2.10, but if there is an update of the minor release specifies the version of the top. Check version of, please check the list of Zabbix source of development site URL below.

   http://www.zabbix.com/jp/download.php (Zabbix source section)

- ZABBIX_AGENT_VERSION

   Agent will download the compiled binary from a compiled Zabbix agent download the above URL. Please specify the versions that are listed in the download list.

- DOWNLOAD_AGENT_PLATFORMS

   Zabbix agent will download and install the binary of each platform. It lists the list of pre-monitoring platforms. Platform name, `Select the download file compiled Zabbix agent <http://www.zabbix.com/jp/download.php>` _ from, you wrote the suffix name of the back of the release version of the download file name. For example, zabbix_agents_2.2.9.linux2_6.i386.tar.gz will linux2_6.i386 is the platform name.

- ZABBIX_ADMIN_PASSWORD

   Write the password of Zabbix Web console of the administrator user. Please change the default value from the point of view of security.

- USE_ZABBIX_MULTI_SIZE

   Constitute a multiple of the monitoring site, please to 1 if you want to change the Zabbix monitoring settings for each of the monitoring site. It is a plurality of monitoring site configuration, Zabbix instance, but will be one of, if you have one, group by each monitoring site in the instance, monitoring templates, and the setting by dividing the monitoring item.

- GETPERF_AGENT_USE_ZABBIX

   Please be 0. If you want to disable the Zabbix.

Zabbix installation
-------------------

And installation of Zabbix server set, and the download of the agent set. Zabbix server installation from yum repository provided by the developer.

::

    sudo -E rex prepare_zabbix

The agent, a platform of the binary that you specified in the configuration file {GETPERF_HOME} / module / getperf-agent / var / zabbix
I would like to download below. Since MD5 checksum result of each download file is output to the installation message, please make sure that it is the same as the MD5 description of the URL of the developer download site described above.

.. Note ::

  - About MySQL database creation error

     MySQL if it is installed with yum, and Zabbix server, version described in the getperf_zabbix.json different
     There is a case to fail to create the database. If this is the case and the confirmation of the version from the following installation directory.

     ::

         ls / usr / share / doc / | grep zabbix
         zabbix-2.2.10
         zabbix-server-mysql-2.2.10

     Please specify the correct version to ZABBIX_SERVER_VERSION of getperf_zabbix.json. The following example specifies the 2.2.10. After setting, the following command to manually delete the database being created (zabbix), by re-running the installation script, re-creation of the database.

     ::

         mysqladmin -u root -p drop zabbix
         sudo script / deploy-zabbix.pl

     root password of mysql will be GETPERF_CACTI_MYSQL_ROOT_PASSWD of config / getperf_site.json.

Check the operation of Zabbix
-----------------

When the installation is successful, Zabbix server process will start automatically. Make the following confirmation.

- | Running a 'ps -ef grep zabbix_server' to confirm that you want to start the process
- Run the 'tail -f /var/log/zabbix/zabbix_server.log' Make sure the log
- From the Web browser 'http: // {monitoring server address} / zabbix /' Make sure the open management console login screen
- From a management console login screen, user admin, password and log in by entering the ZABBIX_ADMIN_PASSWORD

The installation work of Zabbix is ​​complete. Zabbix monitoring settings after this, management command zabbix-cli
Done using the. For more information, `Zabbix monitoring registration <../ 05_AdminCommand / 03_ZabbixHostRegist.html>` _ Please refer to.

About working after this
--------------------

This completes the installation of the monitoring server that serves as a base above. Work after this becomes the following, 1 please install only if required by the option. 2 will be pre-work of the agent side of the installation to be monitored.

1. time-series database installation Graphite (optional)
2. Compilation of agent
