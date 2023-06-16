How to test cacti-cli
=====================

Requiement
----------

Install php library

	cd $GETPERF_HOME
	rex prepare_composer

Install Cacti module

	rex prepare_cacti

Install test framework

	sudo -E yum install php-xml php-pear php-phpunit-PHPUnit --enablerepo=epel

Prapare test site
-----------------

Prepare test site. Create "cacti_cli" site to "$GETPERF_HOME/t"

	cd $GETPERF_HOME/t/
	initsite.pl -f cacti_cli
	cp -r cacti_cli.staging/* cacti_cli/

Test
----

Prepare test link

	cd $GETPERF_HOME/lib/cacti
	ln -s $GETPERF_HOME/t/ t

Run all

	phpunit 

Run some test

	phpunit tests/test-view.php

