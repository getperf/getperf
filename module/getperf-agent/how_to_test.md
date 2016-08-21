Test procedure
==============

Linux
=====

Setup of CUnit
--------------

Download & Compile the source from developer site

	wget http://sourceforge.net/projects/cunit/files/latest/download
	tar xvf download
	cd CUnit-2.1-3

	libtoolize --force
	aclocal
	autoheader
	automake --force-missing --add-missing
	autoconf
	./configure

	make
	sudo make install

	export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH

Set up of integration test
=======

When the Web service integration test, do the Web service connection settings.
Edit the script

	cd $GETPERF_HOME/module/getperf-agent/test
	vi make_test_config.pl

Edit these lines

	my $site = 'kawasaki';
	my $agent = 'ostrich';

Generate configuration files, and test Web service communication.
Set the Web service address and port from '$GETPERF_HOME/config/getperf_site.json'.

	perl make_test_config.pl

Web service test use 'wget' command. If it output '200 OK', communication test is ok.

The script 'make_test_config.pl' generate 'test_config.h'.
So re-compile as these config.

	make clean
	make

Unit Test
---------

Test code, test data, it composed under the 'test' directory
Compile by make

	cd test
	cd $GETPERF_HOME/module/getperf-agent/test
	make clean
	make

Test module is 'gpf_test'. You can test as follows

	./gpf_test -s gpf_config
	./gpf_test -s gpf_param
	./gpf_test -s gpf_log
	./gpf_test -s gpf_common  	# Key input
	./gpf_test -s gpf_process

Integration test of the Web service and functional test is as follows

	./gpf_test -s gpf_soap_common
	./gpf_test -s gpf_soap_admin -t [12..15]  # TestId=1..11 is old version test, unavailable
	./gpf_test -s gpf_soap_agent -t [6..9]    # TestId=1..5  is old version test, unavailable
	./gpf_test -s gpf_admin      -t [11..15]  # TestId=1..10 is old version test, unavailable
	./gpf_test -s gpf_agent      -t [10]      # TestId=1..9  is old version test, unavailable

gpf_soap_admin test
-------------------

TestId from 1 to 11 based ob old version Web service. So current version is unavailable.
You can test from 12 as follows.

	./gpf_test -s gpf_soap_admin -t 12

TestId = 15 (Module update). prepare dummy download module of Web service

	cd $GETPERF_HOME/var/agent
	perl ../../module/getperf-agent/test/make_moduel_test_archive.pl

About TestId 15, Major version is 2, Build is 4. Architecture set the same as the runtime environment. 

	./gpf_test -s gpf_soap_admin -t 15

gpf_soap_agent test
-------------------

Prepare dummy upload file of Web service

	dd if=/dev/zero bs=1024 count=10 of=./_bk/arc_host1__stat_20150201_000000.zip

Run test

	./gpf_test -s gpf_agent      -t 10

Windows
=======

Windows test needs libcunit.dll, which it must be built in Visual Studio.
See [How to build of Windows unit test](win32/how_to_test_win.md).

Compile by nmake

	cd test
	namake /f Makefile.win

Set the path of ssleay32.dll, zlib1.dll, libeay32.dll, libcunit.dll.

	set PATH=%PATH%;..\win32\bin

Test operation is same as Linux

	.\gpf_test.exe -s gpf_config -t 1
