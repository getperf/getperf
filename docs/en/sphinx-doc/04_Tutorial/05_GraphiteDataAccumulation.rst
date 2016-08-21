Collecting data by Graphite
========================

If you enable the data accumulation by the time-series database Graphite, and the same data and the default of RRDtool it is also registered in Graphite. Graphite
Enabling the $ edit the GETPERF_HOME / config / getperf_graphite.json, `Graphite install <../ 03_Installation / 09_GraphiteInstllation.html>` to run the _. The accumulated data of Graphite will be saved in the following directory.

Example: confirmation of registration data of Graphite of Linux monitored

::

     ls / var / lib / carbon / whisper / Linux / {monitored} /
     device loadavg memfree netDevTotal vmstat

Graphite site
---------------

Confirmation of the accumulated data from Graphite management console is available. Please open the URL for the following Graphtie management console from a Web browser.
Cooperation with Graphite will still be with the α release.

::

     http: // {monitoring server address}: 8081 /
     