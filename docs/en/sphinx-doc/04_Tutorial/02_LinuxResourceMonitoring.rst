Linux monitoring
==========

Linux setup is done in OS general user. Create a directory called ptune under the home directory of OS general user, run module, and place the configuration file, the log storage directory. Package to be installed there is a need to download the file to match the monitored platform, will advance the previous chapter will be the `agent compile <../ 03_Installation / 10_AgentCompile.html>` need _ description. Here, it gives agent setup procedure in a 64bit environment of CentOS6.

Getperf agent setup
--------------------------------

Log in as a general user on the monitored server. Download the module to select the target platform from the aggregation server download site.

::

    wget http: // {monitoring server address} /docs/download/getperf-zabbix-Build4-CentOS6-x86_64.tar.gz

Unzip the package.

::

    tar xvf getperf-zabbix-Build4-CentOS6-x86_64.tar.gz

Use the getperfctl of agent management command, and the communication confirmation of the monitoring server.
For communication with the monitoring server to the HTTPS communication of client authentication type, as the set-up, client certificates, and the download. Run in getperfctl setup command.

::

    ~ / Ptune / bin / getperfctl setup

After the execution, and the input from the console message. 'Site and enter the key', site of key site message that you created in the previous section of the 'Please enter the access key', please enter the access key. Enter y at the confirmation of you sure that you want to update to complete the setting.

By attaching the specified option of following street site of key and access code, it is possible to omit the value input. When two or more units of setup, Please be sure to use this option.

::

    ~ / Ptune / bin / getperfctl setup --key = {site key} --pass = {access key}

When the 'configuration file has been updated [network]' and is output, it is complete HTTPS settings. Please start the daemon with the following command.

::

    ~ / Ptune / bin / getperfctl start

Service start-up confirmation. Make sure that the appropriate process exists.

::

    ps -ef | grep _getperf

Zabbix agent setup
-------------------------------

Run the Zabbix agent configuration file creation script.

::

    ~ / Ptune / script / zabbix / update_config.sh

This script generates a zabbix_agentd.conf file under the ptune directory. zabbix_agentd.conf file is in the last line, and the address of the monitoring server
Register the host name of its own, which was acquired by the hostname command.

Start the Zabbix agent with the following command.

::

    ~ / Ptune / bin / zabbixagent start

Service start-up confirmation. Make sure that the appropriate process exists.

::

    ps -ef | grep zabbix_agent

OS automatic start setting at the time of start-up
----------------------

It performs automatic start-up settings at the time of OS start-up. This procedure will need to run in the root user. For Getperf agent and Zabbix agent's been started in the above procedure, it is also possible to continue the set after this as holding this procedure.
Please if there is no work rights on the root have the following tasks to the system owner.

::

    su - root
    perl (ptune home directory) /bin/install.pl --all

Check the settings, enter the y

If you want to start Getperf agent only please refer to the following.

::

    perl (ptune home directory) /bin/install.pl --module = getperf

In complete agent configuration above, is to set the aggregation server side after this.

Starting the agent manually, the stop
----------------------------------------

Start-up of each agent in the following script, you can stop. Please run in the OS user that was used in the installation.

Getperf agent of start / stop

::

    ~ / Ptune / bin / getperfctl stop # If you want to stop
    ~ / Ptune / bin / getperfctl start # If you want to start

Start / stop of Zabbix agent

::

    ~ / Ptune / bin / zabbixagent stop # If you want to stop
    ~ / Ptune / bin / zabbixagent start # If you want to start
    