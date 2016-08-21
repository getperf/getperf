# Test procedure

## Setup test site

Create 't/cacti_cli' test site.

```
cd $GETPERF_HOME/t
initsite.pl -f cacti_cli
```

Copy test data from 't/cacti_cli.staging'.

```
cp -r cacti_cli.staging/* cacti_cli/
```

## Unit test

```
perl 1_aggrigator.t
perl 1_aggrigator_node.t
perl 1_aggrigator_step.t
perl 2_container.t
perl 3_loader.t
perl 4_rrd.t
perl 5_config.t
perl 6_site.t
perl 7_data_info.t
```

## Functional test

```
perl 8_monitor.t
perl 8_unzip.t
perl 9_purge.t
perl 10_ws2.t
perl 10_ws.t
perl 11_ssl.t
perl 12_deploy.t
perl 13_ws-admin.t
perl 14_ws-data.t
perl 15_ws.t
```
