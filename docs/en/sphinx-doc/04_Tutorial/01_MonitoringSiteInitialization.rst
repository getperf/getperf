Initialization of the monitoring site
==================

Do the construction of the monitoring site by using the monitoring server and agent installation package that was installed in the previous chapter. Procedure will be less.

.. Figure :: ../image/tutorial_flow.png
   : Align: center
   : Alt: PDCA

1. site initialization

   To the monitoring server and the registration of the monitoring site. Under the specified directory, data reception, data aggregation, data storage, and create a directory of the node definition. After site registration, to launch the site aggregate daemon. Specified directory becomes the site of the home directory, and monitor configuration tasks to move to this directory.

2. Agent Installation

   And the package installation of the agent. After extracting the package, specify the site key of the site that was created in 1 Do HTTPS communication settings with the monitoring server. After the communication settings, and then start the agent. Monitoring server side receives the data from the agent, and the data aggregation according to aggregation rules that site aggregate daemon has defined.

3. Cacti graph registration

   When the data aggregation processing from the agent is executed, and the time-series data for the graph monitoring, node definition is generated. Node definition is the definition file that summarizes the metric information of aggregated data (such as the processor of the model). And time-series data generated, based on the node definition
   This graph registered in Cacti monitoring software. Graph registration Cacti
   Using the management command

4. Zabbix graph registration

   3 using Zabbix for management commands in the same procedure as Zabbix
   To register the monitored host

Initialization of the site
--------------

.. Note ::

    * Getperf If you want to initialize the site in a non-user management for the user

      OS that is different from the Getperf management for user
      Please set the environment variable if you want to run in the following at the user.

      ::

          source (GETPERF home directory) /script/profile.sh
          echo source $ GETPERF_HOME / script / profile.sh >> ~ / .bash_profile

Using the site initialization command initsite.pl, to build the site under the specified directory. Here, under the ~ / work of the home directory, create a site called 'site1'.

::

    mkdir ~ / work
    cd ~ / work
    initsite.pl site1

Log of the site creation process is output, 'Welcome to Getperf monitoring site
! Is a success if it is output as'. The following are entries in the log will be used in setting up the agent, so please make a note.

::

    The site key is "XXX".
    The access key is "XXX".

Site key is the key information to uniquely determine the site. It will be the end of the directory name of the site directory specified in initsite.pl.
Access key will be the access key password for the agent.

.. Note ::

    * To check the access key

      Please execute the following command to move to the site directory.

      ::

            cd (site home directory)
            sumup --info

Make sure you can access the open and Cacti site URL in the log message. Cacti site URL is, http: will // {monitoring server} / {site} key.

::
    
    http: // {monitoring server} / site1

And log in as admin / admin.

.. Note ::

    * By git clone for the replication of the development site

      For the development commands that start with git clone in the log message on the command to replicate the site home to a different server, and then used to check the operation in a different environment as a site for the test. For more information, `Please refer to the Site Replication <../ 10_Miscellaneous / 05_SiteCloning.html>` _ by Git.

Start-up of the site aggregate daemon
------------------------

sumup site management command of
It was used to start the daemon process for the site data aggregation. Management command in the site, and run it go to the site home directory. Start the daemon with the following command.

::

    cd site1
    sumup start

sumup [start \ | stop \ | restart \ | status]
In start-up of the daemon process, stop, restart, you can state confirmation. Please make sure to start the daemon with the following command.

::

    sumup status
    ps -ef | grep sumup

You have completed the site initialization above. Agent installation after this, by specifying the site key and access key site that you created, and then start the transmission of the collected data.
