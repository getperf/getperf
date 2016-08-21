Definition
==========

Definition of terms
--------

![Definition of terms](docs/image/definition.png)

1. Site
    * The site is the set of all monitoring items.
    * Firstly the user specified the site home directory and initializes it
    * The certification code of the data collection agent called the access key is generated
2. Tenant
    * Tenant is the view of grouping, filterings plural nodes (the monitoring items)
    * I describe a list of nodes in '/view/{tenant}/{domain}.json'
    * A default is '_default'. It is formed at the time of data count automatically, and all nodes are registered
    * The tenant name becomes the high-end tree name (route menu) of the graph tree of Cacti
3. Node
    * Node is an end of data for the count, and a physical server, a virtual server are equivalent
    * When the agent collect in the local monitoring items of the server, an agent name becomes the node
    * When the agent collect in the remote monitoring items of the server, logical remote server name becomes the new node.
    * Each monitoring definition is saved under '/node/{domain}/{node}' directory
    * '{node}/info/{metric}.json' saves the definition of meta data, such as OS name, Processor name. At the time of graph creation , It is included in the title or comment of the graph.
    * {metric}.json saves the definition of chronological order data
    * The node can define the hierarchical structure and registers by the menu of the graph tree
    * 'device/{metirc}.json' saves a disk, the time order data definition of various interfaces including the network device
4. Domain
    * Domain is a classification definition of the data count
    * It is necessary for the domain name to make Camel notation
    * The established domain 'Linux','Windows' of the HW Resource Monitor ring definition
    * The domain are saved under '/summary/{agent}/{domain}'
    * The domain name comes in redefinition in a count script and can customize it individually
        - For example, when db-tokyo,web-tokyo is it in host name for the monitoring in 'use - segment'. When the domain is 'Tokyo', a server use and classifies it when I classify it by a segment name, the domain becomes 'Db',' Web'
    * I can customize data count and the graph registration by a domain unit
5. Metric
    * Metric is defined the count data
    * The file of defining it performs a count script, graph registration of a string charge account by a metric name
        - In the case of data count of vmstat.txt the count script /lib/Command/Vmstat.pm,
    As for the graph definition, /config/Cacti/Vmstat.pm is read
    * Your can define the metric name in a count script again, too
5. Device
    * The device compiled a network, a list of devices of the disk
    * I describe the list of devices in device/{metric}.json

Site directory configuration
--------------

* /lib
    - It store a sumup script. Camel is the file name that I wrote and saves a source file name
    - The script pass becomes Camel notation of 'lib/Getperf/Command/Site/{domain}/{metric}.pm'
* /config
    - It store a graph definition rule. I register a layout of the graph and Cacti graph template name to apply
    - The script pass becomes 'config/{domain}/{metric}.json'
* /analysis
    - With the preservation directory of collection of agents data, I save collection data from each agent regularly
    - The data which were over a preservation period are performed deletion (purge) of
    - The file pass becomes 'analysis/{domain}/{YYYYMMDD}/{HHMISS}/{metric}.txt'
* /summray
    - A text saves the preservation directory of the practice result of the sumup script, time order data in TSV form
    - The file pass becomes 'summary/{agent}/{domain}/{YYYYMMDD}/{HHMISS}/{new domain}/{node}/{metric}.txt'
* /storage
    - It store a loaded data of a sumup script in RRDTool
    - The file pass becomes 'storage/{ new domain}/{node}/{metric}.rrd'
    - In the case of each device, it becomes 'storage/{ new domain}/{node}/device/{metric}__{device}.rrd'
* /node
    - I save a node definition
    - The pass becomes 'node/{ new domain}/{node}/{metric}.json'
    - The node definition stores information, the domain of the pass of RRDtool, a node pass (the definition that layered a node)
    - Under 'node/{new domain}/{node}/info' directory, It save definitions such as an OS name, the CPU information
* /view
    - It save the list of nodes
    - It save it in 'view/{tenant}/{new domain}.json'
    - The default of the tenant name becomes '_default'. The list of all nodes is saved
    - When only some nodes give reference permission and filter it, I make the directory of the tenant newly and save the list of below target nodes
* /html
    - Web server document route for the Cacti front end
* /test
    - Directory for the test
