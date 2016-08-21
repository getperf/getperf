Windows monitoring
============

Windows of the agent installation is done in the administrator user.
Installation is optional, but here c directly under the C drive: Install to create a directory called.

.. Note ::

    By using the command prompt, run the setup command, but because in the setting of the services that require administrative privileges, please operate with administrative privileges with the command prompt.
    Administrator privileged command prompt, select the command prompt from the Windows Startup menu, start by selecting with administrative privileges by right-clicking.

.. Note ::

    Windows of the package, Windows version, architecture (32bit, 64bit) does not package files are different due to differences in.
    Common, please use the platform name for the package called Windows-MSWin32.

Getperf agent setup
--------------------------------

Select a command prompt from the Startup menu, start with the right click administrator privileges.

::

    cd / d c: \

Download site of the monitoring server from a Web browser
http: // Open the {monitoring server address} / docs / download /, the following package
c: Saves directly under the.

::

    getperf-zabbix-Build4-Windows-MSWin32.zip

Open Windows Explorer, the folder
c: to move to, the module was downloaded
c: to unzip. Right-click the package file to select the decompression from the Explorer, the unzipped
c: please unzip to fix to.

When you unzip
c: execution module under, each configuration file is placed. c: I would like to run the setup command below. Ask the client certificate issued to the monitoring server, HTTPS
And the communication settings.

::

    cd \ ptune \ bin
    . \ Getperfctl.exe setup

Enter the site key, the access key, y in the confirmation of the 'Do you want to update?'
To complete the to set the input. Setting communication above is the end. Then the settings of the service start-up.
Getperf in getperfctl install command to the Windows Service
And the registration of the agent.

::

    . \ Getperfctl.exe install

And to boot from the Windows service of Getperf agent.

::

    . \ Getperfctl.exe start

And the start-up check of the agent.
c: Time of the directory collection command execution result in bottom start because it is stored in the
Make sure it is generated.

Zabbix agent setup
-------------------------------

C: under the Zabbix
Run the agent configuration file creation script. Under the ptune
zabbix \ _agentd.conf file is generated.

::

    cd C: \ ptune \ script \ zabbix
    update_config.bat

Subsequently carried out the registration of the Windows services in the following script, Zabbix
Start the agent.

::

    setup_agent.bat

When the Zabbix agent is started, c: directly under the, zabbix \ _agent.log
There will be generated. Make sure the start to open the log in, such as Notepad. agent #
It started Make sure that it is output. Windows
The case of, is performed in accordance with the service start-up settings for each agent, you do not need to separately carry out the automatic start-up settings at the time of OS start-up.

In complete agent configuration above, is to set the aggregation server side after this.

Starting the agent manually, the stop
----------------------------------------

Start-up of each agent in the following script, you can stop. administrator
Please be executed by a user.

Getperf agent of start / stop

::

    C: \ ptune \ bin \ getperfctl.exe stop # If you want to stop
    C: \ ptune \ bin \ getperfctl.exe start # If you want to start

Start / stop of Zabbix agent

::

    C: \ ptune \ script \ zabbix \ agent_control.bat --stop # If you want to stop
    C: \ ptune \ script \ zabbix \ agent_control.bat --start # If you want to start
