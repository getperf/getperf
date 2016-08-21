Graph registration
==========

Chart template that you created in the previous section, graph definition file, based on the node definition file
And the graph registered in Cacti repository database.

cacti-cli usage
------------------

Graph registration, use the \ ** cacti-cli {node-defined path} ** \ command.
Node-defined path is node / {domain} / {node} / {metric} .json
It becomes a form, and then the graph registered with the following rules.

- Graph definition file lig / graph / {domain} / {metric} .json
   Refer to the
- Refer to defined graph templates to graph definition file in order to create a graph of the node definition
- If you specify a parent directory to a node defined path to register the all node definition file under the

Below, of the Linux domain server ostrich
This example shows how to graph registered in. If you want to graph registration of the metric,
Specifies the node / {domain} / {node} / {metric} .json

::

    cacti-cli node / Linux / ostrich / vmstat.json

If you want to register all of the metric under the node, node / {domain} / {node}
Specify the

::

    cacti-cli node / Linux / ostrich /

If you want to register all of the nodes under the domain, you specify the node / {domain} /

::

    cacti-cli node / Linux /

Processing of graph registration, if the existing graph is present, the default is to skip the process without anything. If you want to overwrite update an existing graph
Add the --force [-f] option.

::

    cacti-cli -f node / Linux / ostrich / vmstat.json

force
Since the option to register from delete the existing graph, the arrangement of the tree menu will move to the position of the most behind the same level. If the position do not want to move in, - skip-tree
Add the option.

::

    cacti-cli -f --skip-tree node / Linux / ostrich / vmstat.json

Node Definition of graph registration with a device
----------------------------------

When equipped with the device of the node definition, and then graph registered in the order of the device list that is defined in the node definition. For example, in the following example Linux
In the disk I / O of the node definition, devices
A list of tags in order that the graphs registration. Or changing the order of the device to be registered, if you want to narrow down, to edit the list of devices in the pre-node definition.

::

    vi node / Linux / ostrich / device / iostat.json
    {
       "Devices": [
          "Sda",
          "Dm-0",
          "Dm-1",
          "Dm-2"
       ],
       "Rrd": ". Linux / ostrich / device / iostat __ * rrd"
    }

Registration of graph specifies the same node definition file.

::

    cacti-cli node / Linux / ostrich / device / iostat.json

If you want to sort a list of devices, specify the --device-sort {sort options} to run option.
Sort options, natural (natural sort), natural-reverse (natural sort descending order), normal (alphabetic sort), to specify the normal-reverse (alphabetic sort in descending order). The default is none (not sorted).

::

    cacti-cli node / Linux / ostrich / device / iostat.json --device-sort natural

About view definition
------------------

For registration order of the node under the domain

All of the nodes under the domain are stored in the bottom of the view / \ _ default / {domain} / {node} .json.

::

    ls view / _default / Linux /
    gitlab.json ostrich.json

The following example will in turn register the graph view list of definitions of Linux domain.

::

    cacti-cli node / Linux /

If you want to sort the list of view, to run option to specify the --view-sort {sort options}.
Sort options, natural (natural sort), natural-reverse (natural sort descending order), normal (alphabetic sort), to specify the normal-reverse (alphabetic sort in descending order). The default is the timestamp (time stamp of the old order).

::

    cacti-cli node / Linux / --view-sort natural

You can register the list that was the order and filter of the node as a view in a separate menu. In the following example creates a view called test1, Linux
Edit the list of

::

    mkdir view / test1
    cp -r view / _default / Linux / view / test1 /
    Organize # view / test1 / json file under
    # Leaving want to refer to the node only to delete the rest

Created view is specified in --tenant {view name}. Cacti
In the tree menu
The menu is newly added that {view name}, the tree menu of the specified list is created

::

    cacti-cli node / Linux / --tenant test1
    