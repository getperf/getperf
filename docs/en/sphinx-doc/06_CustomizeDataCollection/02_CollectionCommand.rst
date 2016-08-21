Definition of collection command
==================

Process flow of the agent
------------------------

Agent the data collected in the following flow.

1. Read the collection command configuration file for each category
Periodically run the command list for each category 2. In the specified interval
3. Wait until all of the commands in the category is completed, the execution results After all command is finished
   Transfer to the monitoring server and zip compression
4. Delete the log of past execution results

The above configuration is done in the {agent Home} / conf under the category file.

Set of collection command
------------------

Place a collection command configuration file under the conf of the agent home directory.
The agent at the time of start-up, it reads all the .ini files under conf.
Principle, to set the file name and {category name} .ini, but it does not matter alias because the specified category name is in the configuration file.
In addition, it is also possible to set multiple categories in a single file. Setting examples you noted below.

Example: Linux HW resource information collection command set

::

    ; Collecting enable (true or false)
    STAT_ENABLE.Linux = true

    ; Interval sec (> 300)
    STAT_INTERVAL.Linux = 300

    ; Timeout sec
    STAT_TIMEOUT.Linux = 340

    ; Run mode (concurrent or serial)
    STAT_MODE.Linux = concurrent

    ; Collecting command list (Windows)
    ;. STAT_CMD {category} = '{command}', [{outfile}], [{interval}], [{cnt}]
    ; Category ... category name
    ; Command ... command file name
    ; (_script_: Script directory, _odir_: output directory)
    ; Outfile ... output file name
    ; Interval ... interval sec [option]
    ; Cnt ... execute times [option]
    ; Ex)
    ; STAT_CMD.Windows = '/ usr / bin / vmstat 5 61', vmstat.txt
    ; STAT_CMD.Windows = '/ bin / df -k -l', df_k.txt, 60, 10

    STAT_CMD.Linux = '/ usr / bin / vmstat -a 5 61', vmstat.txt
    STAT_CMD.Linux = '/ usr / bin / free -s 30 -c 12', memfree.txt
    STAT_CMD.Linux = '/ usr / bin / iostat -xk 30 12', iostat.txt
    STAT_CMD.Linux = '/ bin / cat / proc / net / dev', net_dev.txt, 30, 10
    STAT_CMD.Linux = '/ bin / df -k -l', df_k.txt
    STAT_CMD.Linux = '/ bin / cat / proc / loadavg', loadavg.txt, 30, 10

Parameter names are written in the form of 'item. Category'. The definition of the parameters in the street of the comments of the description, STAT_MODE if you want to run the command in the command list in parallel, if you want to run concurrent, the serial is a serial. STAT_CMD is the rule following in the definition of the command list.

- To describe in the following format. Command, '' (single quotation marks), "" it requires there be enclosed in either of (double quotation marks).

   'Command', execution result .txt

- Description of the redirection will be following.

   'Command> run result .txt'

- Behind the execution result .txt, interval, when you add the number of executions, run the repeat command, and then append the execution results.

   'Command', execution result .txt, interval (in seconds), the number of executions

- As a macro, and script of the directory '_script_', there is '_odir_' output directory. Use as follows example.

   '_script_ / Get_cpu_stat.sh> _odir_ / get_cpu_stat.txt'

Reflection of the setting
----------

To reflect the setting is to restart the agent using the getperfctl command. An example of a case where the $ HOME / ptune was the agent home directory you noted below.

::

    ~ / Ptune / bin / getperfctl stop
    ~ / Ptune / bin / getperfctl start

Execution result of the command is stored in the bottom of the '{agent Home} / log / {category} / {DATE} / {time}'.
stat_ in {category} .log's agent body run log, the start time of each command, end time, process ID, and exit code, to record the error message when an error occurs.

Other configuration files
--------------------

The other configuration files noted below.

{Agent Home} /getperf.ini
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The agent body of the configuration file, the definition of each parameter is the following.

.. Csv-table ::
    : Header: item name, specified value, defined
    : Widths: 10, 5, 30

    DISK_CAPACITY, 0, the threshold value of the disc [%]. Quit the daemon is an error if less than the specified value
    SAVE_HOUR, 24, LOG save time
    RECOVERY_HOUR, 3, dates back time of log retransmission at the time of data transfer failure
    MAX_ERROR_LOG, 5, maximum number of lines of the log output of the command execution error. Error log is recorded in the execution log of the agent body
    LOG_LEVEL, 5, log level. None 0, FATAL 1, CRIT 2, ERR 3, WARN 4, NOTICE 5, INFO 6, DBG 7
    DEBUG_CONSOLE, false, enabling the console log output
    LOG_SIZE, 100000, the log file size [Byte]
    LOG_ROTATION, 5, the number of log rotation generation
    LOG_LOCALIZE, true, activation of Japanese console log output. If false will be English output
    HANODE_ENABLE, to transfer false, the execution result of HANODE_CMD not the If you have activated transfer to the monitoring server in the host name as the service name
    HANODE_CMD, '', service name check script of the cluster configuration. script / of it placed under. Instead of the host name the script execution as a result of service host name, and then forwarded to the monitoring server
    POST_ENABLE, false, enabling the transfer process after zip compression. If true, without the transfer of the agent Web service, and the data transfer by using a command defined in POST_CMD
    POST_CMD, '', to describe the transfer command. Macro * zip * is the zip file path
    PROXY_ENABLE, false, enabling the proxy server
    PROXY_HOST, '', proxy server address. If not specified, it will use the value of HTTP_PROXY of environment variables
    PROXY_PORT, '', proxy server port. If not specified, it will use the value of HTTP_PROXY of environment variables
    SOAP_TIMEOUT, 300, time-out period of the agent Web service

{Agent Home} / network / bottom of the file
～～～～～～～～～～～～～～～～～～～～～～～～～～～～～～～～～～～～～～～～～～

Under {agent Home} / network / of, and place the communication configuration file with the monitoring server. 'Getperfctl setup' after execution of the command, each file is automatically generated.

- License.txt

   After getperfctl setup run, it will be the license file that is received from the monitoring server.
   If you want to re-run the getperfctl setup, please run from once to delete this license file. There are set of license expiration,
   If GETPERF_LICENSE_POLICY of getperf_site.conf within the file is none the automatic update of the license file in monitoring the server side, the agent is automatically downloaded at the timing when it expires. Expiration date
   You specify the GETPERF_SSL_EXPIRATION_DAY.

- Getperf_ws.ini

   It will be the connection settings of the agent Web service of the monitoring server. If you want to disable the data transfer, please refer to the REMHOST_ENABLE to false. Other parameters are automatically generated by the getperfctl setup command.

- Ca.crt, client.crt, client.csr, client.key, client.pem

   It will be the SSL certificate set. ca.crt certificate of self-certification authority of the monitoring server, client.crt client certificate, client.csr client certificate request, client.key the client's private key, client.pem is client.crt and client. It will be the file you merge key. Both will be the file that is automatically generated by the monitoring server side. Also to the SSL certificate has an expiration date, Lisense.txt
   At the timing of the update of the expiration date, the agent will automatically download the new SSL certificate set.
   