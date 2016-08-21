=================
Aggregate script API
=================

You wrote the API definition of the received data objects $ data_info argument of the parse function of the aggregation script.
Subroutine aggregation script takes the form below, you code the aggregation processing by using the $ data_info as an argument.

Example: subroutine aggregate script

::

    sub parse {
        my ($ self, $ data_info) = @_;

        # API processing via the $ data_info object
    }

-----------------------------
Information acquisition of the received data, set
-----------------------------

^^^^^^^^^^^^^^^^^^^^^^^^
Received data information acquisition
^^^^^^^^^^^^^^^^^^^^^^^^

You get a variety of information from the received data path.

host ()
"" "" "" "

::

    my $ host = $ data_info-> host; # server01

It gets the monitored servers that run the agent.

postfix ()
"" "" "" "" ""

::

    From # received data 192.168.10.1/http_response.txt, get the 192.168.10.1
    my $ host = $ data_info-> postfix;

If you want the distribution to be monitored for each directory on the remote collection, you get to be monitored from the directory name.

file_suffix ()
"" "" "" "" "" "" "" "

::

    From # received data http_response__192.168.10.2.txt, get the 192.168.10.2
    my $ host = $ data_info-> postfix;

It gets the suffix of the file name of the received data. This is used to specify the monitored the suffix on the remote collection.

file_name ()
"" "" "" "" "" ""

::

    my $ file_name = $ data_info-> file_name; # http_response__192.168.10.2.txt

It gets the file name of the received data.

file_ext ()
"" "" "" "" "" ""

::

    my $ file_ext = $ data_info-> file_ext; # txt

It gets the file extension of the received data.

start_timestamp ()
"" "" "" "" "" "" "" "" "" "

::

    my $ start_timestamp = $ data_info-> start_timestamp; # 2014-11-17T08: 00: 00

Get the command start time of the received data '% Y-% m-% dT% H:% M:% S' and converts it to a format string.

start_time_sec ()
"" "" "" "" "" "" "" "" ""

::

    my $ sec = $ data_info-> start_time_sec; # 1447457299
    $ Timestamp = $ sec-> datetime; # 2015-11-13T23: 28: 19

To get the command start time of the received data and converts it to a UNIX time. Result Calling an object in the datetime function '% Y-% m-% dT% H:% M:% S' and converts it to a format string.

.. Note ::

    The return value is the Time :: Piece type, but the data types used in the data aggregation will often be advantageous and easy to use more of the int type in terms of performance. It will convert to an int type, in the epoch function below.

    ::

        my $ sec = $ data_info-> start_time_sec-> epoch;

^^^^^^^^^^^^^^^
Aggregate data set
^^^^^^^^^^^^^^^

Sets of aggregate data.

is_remote ()
"" "" "" "" "" ""

::

    $ Data_info-> is_remote (1);
    my $ host = $ data_info-> postfix;
    my $ output = "/HTTP/${host}/http_response.txt";

If you specify 1 in the argument, to enable remote collection. Aggregate data path '{domain} / {node} / {metric} .txt'
In specifies. In the case of device data, it will be the '{domain} / {node} / device / {metric} __ {device} .txt'.

step ()
"" "" "" ""

It specifies the RRDtool of step (s).

^^^^^^^^^^^^^^^^^^^^^^^^^^^
Receive data file input
^^^^^^^^^^^^^^^^^^^^^^^^^^^

input_file ()
"" "" "" "" "" "" "

::

    open (my $ in, $ data_info-> input_file) || die "@!";

It gets the file path of the received data. In conjunction with the open function to use.

input_dir ()
"" "" "" "" "" "" "

::

    my $ input_dir = $ data_info-> input_dir; # {site home} / analysis / {monitored} / Linux / 20151116/084500

It gets the directory path of the received data.

skip_header ()
"" "" "" "" "" "" "" "

::

    open (my $ in, $ data_info-> input_file) || die "@!";
    $ Data_info-> skip_header ($ in);

Skip the header reading of the first line of the data file of the received data. In the case of, - the first row, the start and end in the second line was also a letter '' '-' and if made from blank to skip the file pointer to the next line.

Registration of metric
^^^^^^^^^^^^^^^^^^^^^

Register the metric information to the node definition. regist_metric, regist_device after registration, to run the data load to RRDtool.
This section describes the setting example in the next section in the function of the additional information to the regist_node node.

regist_metric ()
"" "" "" "" "" "" "" "" ""

::

    $ Data_info-> regist_metric ($ node, $ domain, $ metric, \ @headers);

Register the path of RRDtool to node definition 'node / {domain} / {node} / {metric} .json'. @headers is used as a data source list at the time of data file creation of RRDtool.

regist_device ()
"" "" "" "" "" "" "" "" "

::

    $ Data_info-> regist_device ($ node, $ domain, $ metric, $ device, $ device_text, \ @headers);

The node definition 'node / {domain} / {node} / device / {metric} .json' to register the path and device list of RRDtool.

regist_node ()
"" "" "" "" "" "" "" ""

::

    $ Data_info-> regist_node ($ node, $ domain, $ node_info_path, \% node_infos);

The node definition 'node / {domain} / {node} / {node_info_path} .json add the information.
$ Node_info_path is specified in the form of 'info / {metric}'. % Node_infos specifies an associative array of additional information.

Report Output
^^^^^^^^^^^^

Create the aggregated data file. And file output by molding aggregated data buffered. Aggregated data file will be the input file of the load of RRDtool.

simple_report ()
"" "" "" "" "" "" "" "" "

::

    $ Data_info-> simple_report ($ output_file, \% results, \ @headers);

Directory for the aggregated data to create an aggregate data file under the 'summary / {monitored} / {category} / {DATE} / {time}' directory.
% Results is an associative array in which the time stamp on the key, the element will be a string separated by spaces or tabs from the first row in the order.

pivot_report ()
"" "" "" "" "" "" "" ""

::

    $ Data_info-> pivot_report ($ output_file, \% results, \ @headers);

Directory for the aggregated data to create an aggregate data file under the 'summary / {monitored} / {category} / {DATE} / {time}' directory.
% Results is an associative array that time stamp, the column name to the key, the element will be the value. Column will be output in the same order as the list of @headers.

standard_report ()
"" "" "" "" "" "" "" "" "" "

::

    $ Data_info-> standard_report ($ output_file, $ buffer);

And outputs directly to aggregate data file without forming a buffer.
