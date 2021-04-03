Setup of Getperf web service
============================

preparation
============

Set up the gradle environment in Rex

	cd $ GETPERF_HOME
	rex install_package

Create test site

    mkdir -p ~/site
    initsite -f ~/site/cacit_cli

Test
====

Perform a JUnit test reads the 'src/test/resorces/getperf_site.json'
Below, directory path need to be modified to suit the execution environment

	"GETPERF_HOME": "/home/psadmin/work/getperf",
	"GETPERF_SITE_DIR": "/home/psadmin/work/getperf/t",
	"GETPERF_STAGING_DIR": "/home/psadmin/work/getperf/t/staging_data",

As it runs the following

	gradle test

When the test task is completed build/reports/test results under the tests are output in HTML.

Build
=====

When performing a series of tests, compile, and deploy (jar created) in bulk

Attach the services.xml and create jar

	gradle axisJar
	gradle build

jar is generated to the build/libs/getperf-ws-1.0.0.jar

Without a test, if you make only the jar file

	gradle jar
