Agent remote shell
============================

how to use
--------

nodeconfig
It does the monitored remotely by using a command. Operation can be monitored, that can be accessed via ssh Linux, only the UNIX server, Windows will be excluded. Run the command from the move to the site home directory.

::

    Usage: nodeconfig
            --add = {node_path} [--user = s] [--pass = s] [--home = s] [--node_dir = s]
            --rex = {node_path} {command} {--param = s} ... [--hosts = s]

    ex) nodeconfig --rex = node / HW / test1 upload --file = / tmp / getperf-CentOS6-x86_64.tar.gz

If you can not name resolution of the host name, you need to register in advance IP address to .hosts file.
Remote operation will use the _ `Rex <https://www.rexify.org/>`. Go to the site home directory, and displays the executable task list when you run the 'rex -T'.

Advance preparation
--------

ssh connection settings for the monitored
~~~~~~~~~~~~~~~~~~~~~

Monitored ssh login user, password, to register the ptune home directory. Remote operation requires all of the monitored, registered in the server required.

Example: ssh connection user, registration of password

First, go to the site directory.

::

    cd ~ / work / site1
    nodeconfig --add =. / node / Linux / {monitored} / --user = {OS user} --pass = {OS password} --home = {ptune home directory}

Registration information is recorded in the node / Linux / {monitoring deal} /info/ssh.json.

Node path directory settings of the monitored
～～～～～～～～～～～～～～～～～～～～～～～～～～～～～～～～～～～～

--node \ _dir = {node path directory}
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Register the node path directory to be monitored.

::

    nodeconfig --add =. / node / Linux / {monitored} / --node_dir = {node path directory}

Registration information is recorded in the node / Linux / {monitoring deal} /info/node\_info.json.

Example: node path defined node / Linux / {monitored} /info/node\_path.json

::

    {
       "Node_path": "{node path directory} / {monitored}"
    }

option
----------

--rex = {node-defined path} {task}
～～～～～～～～～～～～～～～～～～～～～～～～～～～～～～～

Run the Rex task on a monitored.

The execution of the confirmation command
^^^^^^^^^^^^^^^^^^

Example: the execution of the uptime command

::

    nodeconfig --rex =. / node / Linux / uptime

Example: execution of disk capacity confirmation command

::

    nodeconfig --rex =. / node / Linux / disk_free

Start / stop of Getperf agents for the monitored
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Example: Getperf stop of agent

::

    nodeconfig --rex =. / node / Linux / agent_stop

Example: Start of Getperf agent

::

    nodeconfig --rex =. / node / Linux / agent_start

Example: restart of Getperf agent

::

    nodeconfig --rex =. / node / Linux / agent_restart

Start / stop of a monitored Zabbix agent
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Example: Stop of Zabbix agent

::

    nodeconfig --rex =. / node / Linux / stop_zabbix_agent

Example: Start of Zabbix agent

::

    nodeconfig --rex =. / node / Linux / start_zabbix_agent

Backup of Getperf agent configuration file to be monitored
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ ^^^^^^^

Getperf backup of the agent configuration file. The monitored, the configuration file set under the ptune home directory, and archives to /tmp/getperf_config.tar.gz.

::

    nodeconfig --rex =. / node / Linux / backup_agent

Upload of the monitored file
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

--file
Upload the file specified by the option to ptune home directory to be monitored. Upload destination is changed as follows Rex task.

- Upload (and upload it to the under ptune home)
- Upload_bin (and upload it to the bottom of the bin under the ptune Home)
- Upload_conf (and upload it to the bottom of conf under ptune Home)
- Upload_script (and upload it to the bottom of the script under ptune Home)

Example: ptune upload to the home directory

::

    touch Readme.txt
    nodeconfig --rex =. / node / Linux / upload --file = Readme.txt

Example: Getperf upload of Linux agent configuration file

::

    nodeconfig --rex =. / node / Linux / upload_conf --file = lib / agent / Linux / conf / HW.ini
    