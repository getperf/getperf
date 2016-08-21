Aggregate example
======

To add the information to the node definition
------------------------------

Such as the OS name in the node definition, to register the information that is not time-series data. As an example, describing the procedure to register the Linux OS of the information to be monitored. As the standard of information collected during the site initialization
It has a Linux OS of the information collected in the category of SystemInfo. This information is in the agent, it has obtained a copy of the / etc / issue file.

Example: analysis / {monitored} /SystemInfo/20151114/180000/os\_info.txt

::

    CentOS release 6.6 (Final)
    Kernel \ r on an \ m

Collecting the results will be recorded in the bottom of the node definition file node / {domain} / {monitored} / info directory. The script is as follows. Precautions commented.

Example:
OS information registration script of (lib / Getperf / Command / Site / SystemInfo / OsInfo.pm)

::

    package Getperf :: Command :: Site :: SystemInfo :: Issue;
    use warnings;
    use FindBin;
    use base qw (Getperf :: Container);

    sub new {bless {}, + shift}

    sub parse {
        my ($ self, $ data_info) = @_;

        open (IN, $ data_info-> input_file) || die "@!";
        my $ line = <IN>;
        $ Line = ~ s / (\ r | \ n) * // g; # trim return code
        . $ Line = ~ s / \ s * (\\ r | \\ m | \\ n) * // g; # trim right special char
        close (IN);

        my $ host = $ data_info-> host;
        # 1. node definition of associative array
        my% stat = (
            issue => $ line,
        );
        # 2. registration of node definition
        $ Data_info-> regist_node ($ host, 'Linux', 'info / os', \% stat);

        return 1;
    }
    1;

1. Register to the associative array OS information acquired from the received data
2. Register an associative array to the node definition. To the argument, and specify node, domain, file path, an associative file. File path is specified in the form of 'info / {metric}'.

When you run a file called info / os.json to node definition directory will be generated.

Example: node definition information (node ​​/ Linux / {monitored} /info/os.json)

::

    {
       "Issue": "CentOS release 6.6 (Final)"
    }

This information is used in the definition of the comments and the title of the Cacti graph.

Grouping of node by node path
------------------------------------

Monitored location, use the node path if you want to the grouping in such applications. Node path is one of the node definition, add the directory item name as node_path, to specify the monitored. For example, if you want to add a category called DB to be monitored, you can add the following code.

Example: example of a node definition registration information

::

        my% stat = (
            node_path => "/ DB / $ host",
        );
        $ Data_info-> regist_node ($ host, 'Linux', 'info / node', \% stat);

Name after the info of the third argument of regist_node () can be any. In addition, you may want to add a node_path already certain node definition. This information will be used in grouping of graph registration of Cacti.

Filtering by the view
------------------------------------------

Use the view if you narrow down only a specific node. view under the directory becomes the definition of view, to manage the configuration of 'view / {tenant} / {domain} / {node} .json'.
Tenant in the key information of view, '_default' will be the specified value. '_default' Is created automatically when a node registration, all the nodes belong to the '_default'.

::

    ls view / _default / Linux /
    linux01.json linux02.json linux03.json
    linux11.json linux12.json linux13.json

To create a view, first create a directory for the new tenant. Nodes that belong to the tenant under the directory that you created copy from _default.
In the following example will be the definitions that belong to the node of linux01, linux02 to tenant01.

::

    mkdir -p view / tenant01 / Linux /
    cp view / _default / Linux / linux01.json view / tenant01 / Linux /
    cp view / _default / Linux / linux02.json view / tenant01 / Linux /

View definition that you create will be used in Cacti graph registration below.
