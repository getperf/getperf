Aggregate definition
========

Aggregation processing flow
--------------

Aggregate processing flow of the monitoring server will be less.

1. Unzip the received data zip file under the anlysis
2. Select the summary script parses the file path where you unzipped
3. run aggregate script

2 Select a summary script according to the search rules of aggregation script.

Search rules of aggregation script
--------------------------

Aggregation script is in the package file of Perl, to load the script as Perl of class. The class name is determined from the category name and collecting file name of the agent. The rule is as follows.

1. analysis
   To extract the category name and the file name from the collected data file path below.
2. category name and the file name will be converted to a Camel notation.
3. The file name and file extension, except for the string of the suffix that begins with \ _ \ _ (underscore two).
4. under the site directory
   lib / Getperf / Command / Site / {category name} / {file name} .pm
   Find the script as an aggregate.
5. If it does not exist, under the GETPERF \ _HOME
   lib / Getperf / Command / Base / {category name} / to find the {file name} .pm.
6. If you do not exist any of the files of the 4 and 5 to skip the tabulation process.

4 is used to customize the aggregation processing becomes a site-specific script file. 5 will be invariant script at all sites a common script file. We did a search example of counting script below.

Example: Linux loadavg.txt

- Collecting data file path:
    analysis / {monitored} /Linux/20151111/170000/loadavg.txt
- Perl package path:
    Search for $ SITE_HOME / lib / Getperf / Command / Site / Linux / Loadavg.pm
- If not,
    Search for $ GETPERF_HOME / lib / Getperf / Command / Base / Linux / Loadavg.pm

Example: Network of snmp \ _get \ _ \ _ sw1.txt

- Collecting data file path:
    analysis / {monitored} /Network/20151113/110000/snmp_get__sw1.txt
- Perl package path:
    Search for $ SITE_HOME / lib / Getperf / Site / Network / SnmpGet.pm
- If not,
    Search for $ GETPERF_HOME / lib / Getperf / Base / Network / SnmpGet.pm

Coding of counting script
----------------------------

This section describes each coding procedure and the aggregation script of the existing Linux HW resource to reference. Aggregation script of Linux of HW resources, will be installed by default when the site initialization. Go to the site directory, make sure the scripts that are registered.

Data aggregation loadavg load average
～～～～～～～～～～～～～～～～～～～～～～～～～～～～～～～～～～～～

First it indicates the data aggregated example of the simplest loadavg. Received data example of loadavg will be following.

Example: loadavg received data
(Analysis / {monitored} /Linux/20151114/180000/loadavg.txt)

::

    0.00 0.00 0.00 1/348 31163
    0.00 0.00 0.00 1/343 31205
    0.00 0.00 0.00 1/342 32432
    <Snip>

The first three digits, 1 minute, 5 minutes, to display the CPU and IO utilization was measured before 10 minutes.
Make sure the script to aggregate book value. The fact is just a script to register in time series database to extract the value of the three-digit. Description has to append a comment the required locations.

Example: loadavg aggregate script (lib / Getperf / Command / Site / Linux / Loadavg.pm)

::

    package Getperf :: Command :: Site :: Linux :: Loadavg; # 1. package name
    use strict;
    use warnings;
    use Data :: Dumper;
    use Time :: Piece; # 2. Required Libraries
    use base qw (Getperf :: Container); # 2. Required Libraries

    sub new {bless {}, + shift}

    sub parse {
        my ($ self, $ data_info) = @_; # 3. $ data_info received data objects

        my% results;
        my $ step = 5;
        my @headers = qw / load1m load5m load15m /; # 4. data source list

        $ Data_info-> step ($ step); # 5. registration of step

        Search of # 6. host name; my $ host = $ data_info-> host
        my $ sec = $ data_info-> start_time_sec-> epoch; # 7. Find start time
        open (my $ in, $ data_info-> input_file) || die "@!";
        while (my $ line = <$ in>) {
            next if ($ line = ~ / ^ \ s * [a-z] /); # skip header
            $ Line = ~ s / (\ r | \ n) * // g; # trim return code
            $ Line = $ 1 if ($ line = ~ / ^ (\ S + \ s + \ S + \ s + \ S +) \ s + /);
            $ Results {$ sec} = $ line;
            $ Sec + = $ step;
        }
        close ($ in);
        # 8. registration of metric
        $ Data_info-> regist_metric ($ host, 'Linux', 'loadavg', \ @headers);
        # 9. report output
        $ Data_info-> simple_report ( 'loadavg.txt', \% results, \ @headers);
        return 1;
    }

    1;

parse () becomes the data aggregation subroutine, an object of the received data of the second argument of $ data_info aggregate target, it reads the data to open a file from the received data objects.

1. The package name will follow the script path name. Script path name is the path that has been retrieved by the search rules of the above-mentioned aggregation script.
2. When the series library 'Time :: Piece', the object container library 'Getperf :: Container' will be required libraries.
3. using the second argument of $ data_info received data objects, and access to various API.
4. A list of the data source name to be registered in time-series database. The data registration to RRDtool There are a few of the notes, is described in the next section.
5. Set the sampling interval of the registration data of the time-series database.
6. Extract the host name from the received data file.
7. Gets the starting time of the received data file (UNIX time).
8. node, domain, metric, to register the header list to the node definition. Node definition, are recorded in the node / {domain} / {node} / {metric} .json file.
9. Write the aggregate data to a file. A file is under the 'summary / {monitored} / {category} / {DATE} / {time}' directory. Argument, the output file name, the pointer of the output data, and specify a pointer to the header list. Output data is an associative array of concatenated string of each value was a time stamp to the key. The output data is different from the format by the report function to be used.

parse () after the process is completed, the update of the node definition file, perform the data load to RRDtool. It is described in the example of executing sumup command described in the tutorial section. With a receive data file and run the sumup.

Example: Example of execution of loadavg data aggregation command

::

    sumup analysis / {monitored} /Linux/20151116/140000/loadavg.txt
    2015/11/16 14:53:24 [INFO] command: Site :: Linux :: Loadavg
    2015/11/16 14:53:24 [INFO] load row = 10, error = (10/0/0)
    2015/11/16 14:53:24 [INFO] sumup: files = 1, elapse = 0.011321

Node definition file is as follows, specify the path to the RRDtool data to be loaded.

Example: confirmation of loadavg metric definitions

::

    more node / Linux / {monitored} /loadavg.json
    {
       "Rrd": "Linux / {monitored} /loadavg.rrd"
    }

Output example of sumup command becomes less, and load this data to RRDtool.

Example: loadavg aggregated data (summary / {monitored} /Linux/20151114/180000/loadavg.txt)

::

    timestamp load1m load5m load15m
    1455210091 0.00 0.00 0.00
    1455210096 0.00 0.00 0.00
    1455210101 0.00 0.00 0.00
    <Snip>

The first line specifies the data source list in the argument of the simple_report () in the header information. And outputs a header list that you specified in the function, the second line after the result data, loadavg
Time will be the added data to the three-digit. This file, and load it into RRDtool.

iostat disk I / O data aggregation
～～～～～～～～～～～～～～～～～～～～～～～～～～～～～～

It shows a summary example of the received data composed of a plurality of devices. Disk I / O and, the data of the network of I / O information of multiple devices to a single file has been recorded.
Aggregate script divides the aggregate results for each device, and run on the device file unit was split even load to RRDtool. The iostat output command of disk I / O statistics and described as an example.

Example: iostat received data
(Analysis / {monitored} /Linux/20151116/084500/iostat.txt)

::

    Linux 2.6.32-279.el6.x86_64 (t00020823cap17) 11/14/2015 _x86_64_
    (2 CPU)

    avg-cpu:% user% nice% system% iowait% steal% idle
               0.99 0.00 0.71 0.12 0.00 98.19

    Device: rrqm / s wrqm / s r / s w / s rkB / s wkB / s avgrq-sz avgqu-sz await svctm% util
    sda 0.05 26.81 0.34 32.12 2.33 235.77 14.67 0.13 4.10 0.12 0.39
    dm-0 0.00 0.00 0.39 58.93 2.32 235.73 8.03 0.28 4.69 0.07 0.39
    dm-1 0.00 0.00 0.00 0.01 0.01 0.03 8.00 0.00 4.59 0.32 0.00
    <Snip>

Aggregate script extracts the disk I / O statistics for each device, and file output for each device. Description has to append a comment the required locations.

Example: iostat aggregate script (lib / Getperf / Command / Site / Linux / Iostat.pm)

::

    package Getperf :: Command :: Site :: Linux :: Iostat;
    use strict;
    use warnings;
    use Data :: Dumper;
    use Time :: Piece;
    use base qw (Getperf :: Container);

    # Avg-cpu:% user% nice% system% iowait% steal% idle
    # 0.37 0.00 1.97 0.24 0.00 97.41

    # Device: rrqm / s wrqm / s r / s w / s rkB / s wkB / s avgrq-sz avgqu-sz await svctm% util
    # Sda 0.34 14.29 7.65 1.97 153.33 65.03 45.37 0.01 1.16 0.93 0.89

    sub new {bless {}, + shift}

    sub parse {
        my ($ self, $ data_info) = @_;

        my% results;
        my $ step = 30;
        my $ start_timestamp = $ data_info-> start_timestamp;
        my @headers = qw / rrqm_s wrqm_s r_s w_s rkb_s wkb_s svctm pct /;

        $ Data_info-> step ($ step);
        my $ host = $ data_info-> host;
        my $ sec = $ data_info-> start_time_sec-> epoch;
        open (my $ in, $ data_info-> input_file) || die "@!";
        while (my $ line = <$ in>) {
            $ Line = ~ s / (\ r | \ n) * // g; # trim return code

            if ($ line = ~ / ^ \ s * ([a-zA-Z] \ S *?) \ s + (\ d. * \ d) $ /) {
                my ($ device, $ body) = ($ 1, $ 2);
                # 1. Specify the path name of the aggregate data file. Register the device with the suffix
                my $ output_file = "device / iostat __ $ {device} .txt";
                # 2. Set the header of counting results
                $ Results {$ output_file} {headers} = \ @headers;
                # 3. registration of the device
                $ Data_info-> regist_device ($ host, 'Linux', 'iostat', $ device, undef, \ @headers);

                # 4. registered an associative array of each element as a key data source name
                my @values ​​= split (/ \ s + /, $ body);
                for my $ header (qw / rrqm_s wrqm_s r_s w_s rkb_s wkb_s /) {
                    my $ value = shift (@values);
                    $ Results {$ output_file} {out} {$ sec} {$ header} = $ value;
                }
                $ Results {$ output_file} {out} {$ sec} {pct} = pop (@values);
                $ Results {$ output_file} {out} {$ sec} {svctm} = pop (@values);

            } Elsif ($ line = ~ / ^ Device: /) {
                $ Sec + = $ step;
            }

        }
        close ($ in);
        # 5. Aggregate result the device every file output
        for my $ output_file (keys% results) {
            my $ headers = $ results {$ output_file} {headers};
            $ Data_info-> pivot_report ($ output_file, $ results {$ output_file} {out}, $ headers);
        }
        return 1;
    }

    1;

Order to change the file output for each device, we have the distribution by adding the device name to the suffix of the file name.

1. Set the file path that you add a device to the suffix of the path name. File path with the device is specified in the form of a 'device / {metric} __ {device} .txt'.
2. Assume the distribution data source is different from the case of each device, and set the header for each individual device.
3. Register the node definition of the device. The argument, node name, domain name, metric name, device name, text name of the device, to specify the pointer in the header. Node definitions are stored in the form of a 'node / {domain} / {monitored} / device / {metric} .json'.
4. Register the results in the associative array to each element key.
5. output count results for each device file.

With a receive data file and run the sumup. Node definition, new devices element has been added.

Example: confirmation of iostat metric definitions

::

    more node / Linux / {monitored} /device/iostat.json
    {
       "Devices": [
          "Sda",
          "Dm-0",
          "Dm-1"
       ],
       "Rrd": ". Linux / t00020823cap17 / device / iostat __ * rrd"
    }

Aggregate data is generated for each device file. Device file, you will need to save to the bottom of the device directory.

Example: iostat aggregated data (summary / {monitored} / Linux / 20151114/180000 / device / iostat \ _ \ _ sda.txt)

::

    timestamp rrqm_s wrqm_s r_s w_s rkb_s wkb_s svctm pct
    1455210061 0.05 26.81 0.34 32.12 2.33 235.77 0.12 0.39
    1455210091 0.00 2.60 0.00 1.20 0.00 15.20 0.28 0.03
    1455210121 0.00 18.47 0.00 5.20 0.00 94.67 0.99 0.52
    <Snip>

Data aggregation of the HTTP response
～～～～～～～～～～～～～～～～～～～～～～～～～～～

As an aggregate example of a remote collection, HTTP of the external server
Set the data summary of the response to the new. By using the curl command, the response time of the specified URL to measure the [second], and aggregates the results.

Example: Measurement example of the HTTP response time of an external server [s]

::

    curl -o / dev / null "http: // {external server address} /" -w "% {time_total} \ n" 2> / dev / null
    0.020

And the settings that you want to run the curl command at five-minute intervals to the agent. vi
~ / Ptune / conf / HTTP.ini
In to create the following configuration file. ~ / Ptune / bin / getperfctl
stop, ~ / ptune / bin / getperfctl start
Please re-start the agent in. In the specified output file as a note, and then add the address of the external server in the directory. This directory is used in the analysis of monitored nodes.

Example: Agent HTTP collected set of ({agent Home} /conf/HTTP.ini)

::

    ; ---------- Monitor command config (HTTP Response) -------------------------------- ---
    STAT_ENABLE.HTTP = true
    STAT_INTERVAL.HTTP = 300
    STAT_TIMEOUT.HTTP = 300
    STAT_MODE.HTTP = concurrent

    STAT_CMD.HTTP = 'curl -o / dev / null "http: // {external server address} /" -w "% {time_total} \ n"', {external server address} /http_response.txt

Aggregate script will be less. Precautions have to append a comment.

Example: HTTP response aggregation script
(Lib / Getperf / Command / Site / HTTP / HttpResponse.pm)

::

    package Getperf :: Command :: Site :: HTTP :: HttpResponse;
    use strict;
    use warnings;
    use Data :: Dumper;
    use Time :: Piece;
    use base qw (Getperf :: Container);

    sub new {bless {}, + shift}

    sub parse {
        my ($ self, $ data_info) = @_;

        my% results;
        my $ step = 300;
        my @headers = qw / response /;

        $ Data_info-> step ($ step);
        $ Data_info-> is_remote (1); # 1. remote collection set
        my $ host = $ data_info-> postfix; # 2. host name from the received data file path extraction
        my $ sec = $ data_info-> start_time_sec;

        open (IN, $ data_info-> input_file) || die "@!";
        while (my $ line = <IN>) {
            $ Line = ~ s / (\ r | \ n) * // g; # trim return code
            my $ timestamp = $ sec-> datetime;
            $ Results {$ timestamp} = $ line;
            $ Sec + = $ step;
        }
        close (IN);
        $ Data_info-> regist_metric ($ host, 'HTTP', 'http_response', \ @headers);
        # 3. Aggregate data file path setting
        my $ output = "/HTTP/${host}/http_response.txt";
        $ Data_info-> simple_report ($ output, \% results, \ @headers);
        return 1;
    }

    1;

The basic process flow is the same, but different locations noted in the comments.

1. Activate the remote collection. Change to the aggregation processing for the remote collection.
2. Extract from the directory portion of the received data path host name (monitoring target node).
3. Aggregate data path '{domain} / {node} / {metric} .txt'
   In specifies. In the case of device data, will be the '{domain} / {node} / device / {metric} \ _ \ _ {device} .txt'.

If you have activated the remote collection, how to specify the path of aggregate data will change.

Example: HTTP response
Aggregated data (summary / {monitored} / HTTP / 20151114/180000 / HTTP / {external server address} /http\_response.txt)

::

    timestamp response
    1455210091 0.023

Behind the time directory of aggregate data path, domain, directory node of the pair will be added. For the distribution of the plurality of nodes, and tabulated separately the directory. External server address will be monitored node in the above example.

Setting of the reflection procedure
--------------

The changes of aggregate script to be reflected in the rollup will need to restart the counting daemon. Run the following command.

Example: restart aggregate daemon

::

    cd {site} Home
    sumup restart

RRDtool data source defined by the header
-------------------------------------

Header definition of aggregate data to become a data source list of RRDtool, but in the following format ':' You can add an option in the delimiter.

Definition of header

::

    ds-name: ds-type: heartbeat: min: max

- Ds-name:
   Data source name. RRDtool There are several limitations to the naming scheme (which will be described in detail later).
- Ds-type: data source type. GAUGE \ | COUNTER \ | DERIVE \ | ABSOLUTE
   Choose from. The default is GAUGE.
- Heartbeat:
   Heartbeat value (sec). If the registration interval is longer than this value is treated as missing values. Default
   step \ * 100.
- Min: lower limit of the value. The default is 0.
- Max: the upper limit of the value. The default is unlimited (U).

Using examples noted below.

Example: header definition of a network counter

::

    my @headers = ( 'inBytes: COUNTER', 'inPackets: COUNTER', 'outBytes: COUNTER', 'outPackets: COUNTER');

** Note ** of the data source name naming

- The name must be within 19 characters
- A string that can be used will be the case letters, numbers, and '_'