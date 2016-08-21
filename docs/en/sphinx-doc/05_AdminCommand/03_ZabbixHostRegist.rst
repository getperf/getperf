Zabbix monitoring registration
==============

how to use
--------

Zabbix repository database to the node definition (/ node) to register the monitored under.

::

    Usage: zabbix-cli
            [--hosts = {Hostsfile}] [--add | --rm | --info] {./node/{domain}/{node}}

To Zabbix from the specified node definition to register the following.

- Host Group
- Template
- Host

Creating a .hosts file
---------------------

zabbix-cli will register the IP address of the monitored in Zabbix. If you from the name of the monitored in such DNS not reserve an IP address, under the site home directory
To .hosts file, you must be registered with the IP address. IP, please register an IP address to .hosts file in the order of the monitored name.

::

    cd ~ / work / site1
    vi .hosts

    XXX.XXX.XX.XX {monitored}

.. Note ::

  * For monitored name

    Monitored name that describes the .hosts, please be the same as the monitored directory name of the node defined path. Monitored directory name of the node defined path has the following conversion from the actual host name.

    - Uppercase letters converted to lowercase
    - Remove the suffix part of the domain (such as .your-company.co.jp)

option
----------

zabbix-cli command registers to be monitored to Zabbix repository database in the following rules.

1. If the monitored node is registered to cancel the process below.
2. Register the host group ** ** of Zabbix in the following rules. If registered will skip the process.

   - If the domain is the 'Linux', 'Windows', 'Solaris', such as OS name, put the 'Servers' behind

      Example: Linux Servers, Windows Servers

   - If a node path is registered, - add '{node path} {domain}' to the host group

      Example: DB - Linux

   - If a multi-site has been activated, the beginning - put '{site} key'

      Example: site1 - Linux Servers

3. Register the Zabbix of ** template ** in the following rules. If registered will skip the process.

   - If the domain is the 'Linux', 'Windows', 'Solaris', such as OS name, put the 'Template OS' to the top

      Example: Template OS Linux, Template OS Windows

   - If a node path is registered, - to register the '{node path} {domain}', let link the template of '{domain}' (inherited)

      Example: Template OS Linux - DB (link)

   - If a multi-site has been activated, the beginning - put '{site} key'

      Example: site1 - Template OS Linux

4. Register the host.
5. host groups and templates that were registered in a couple you to belong to the host.

2, 3 will be complicated rules, but it is with the operation of the order to keep the default of the host group, the template and the matching of Zabbix. The command to check the definition information, a description of each operation as an example.
First, go to the site home directory.

::

    cd ~ / work / site1

--info {node defined path}
~~~~~~~~~~~~~~~~~~~~~~~

You will have to confirm your registration information to Zabbix. The actual registration is not. Add to Zabbix by changing the --add option.

Example: confirmation Linux monitored Zabbix registration information

::

    zabbix-cli --info ./node/Linux/ {monitored} /

    # Groups and templates will be following.

       "Groups": [
          "Linux Servers"
       ],
       "Templates": [
          "Template OS Linux"
       ]

Example: information confirmation of when a node path (DB) has been added

Define the "node_path" to node / Linux / {monitored} /info/cpu.json file.

::

    vi node / Linux / {monitored} /info/cpu.json

        "Node_path": "DB / {monitored}",

    zabbix-cli --info ./node/Linux/ {monitored} /

    # Groups and templates will be following.

       "Groups": [
          "Linux Servers",
          "DB - Linux"
       ],
       "Templates": [
          "Template OS Linux",
          "Template OS Linux - DB (link)"
       ]

Example: confirmation information if Zabbix multisite is enabled

And to 1 USE_ZABBIX_MULTI_SIZE of getperf_zabbix.json.

::

    vi $ GETPERF_HOME / config / getperf_zabbix.json

            "USE_ZABBIX_MULTI_SIZE": 1,

    zabbix-cli --info ./node/Linux/ {monitored} /

    # Groups and templates will be following.

       "Groups": [
          "Linux Servers",
          "{Site key} - DB - Linux"
       ],
       "Templates": [
          "Template OS Linux",
          "Template OS Linux - {site key} - DB (link)"
       ]

--add {node defined path}
~~~~~~~~~~~~~~~~~~~~~~

Register the specified node defined path to Zabbix.

--rm {node defined path}
~~~~~~~~~~~~~~~~~~~~~

Removes the specified node defined path.
