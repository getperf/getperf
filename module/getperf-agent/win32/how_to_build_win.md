Windows agent build procedure
=======================

Package requirement
===================

* ZLib 1.2.8
* OpenSSL 1.0e
* CUnit 2.1.8 (Option for test)

Package install
===============

Zlib
----

Open http://www.zlib.net/

Search 'zlib compiled DLL'. Download zip archive of compiled DLL.

	mkdir /tmp/zlib
	cd /tmp/zlib
	wget http://zlib.net/zlib128-dll.zip
	unzip zlib128-dll.zip

Copy DLL to $WIN32_HOME/bin

	export WIN32_HOME=$GETPERF_HOME/module/getperf-agent/win32
	cp zlib1.dll $WIN32_HOME/bin/

Copy include and lib to $WIN32_HOME/zlib.

	cp -r include lib $WIN32_HOME/zlib/

OpenSSL
-------

You get the source with the installer from Shining Light Productions.

http://slproweb.com/products/Win32OpenSSL.html

Search 'Win32 OpenSSL v1.0.2g' (Recommended for software developers).
Download installer of Win32 OpenSSL.

Run installer Extract to 'C:\OpenSSL-Win32'.
Select 'Copy OpenSSL DLLs to:' to 'The OpenSSL binaries'.
Archive directory OpenSSL-Win32 and copy to the Linux server /tmp/OpenSSL-Win32.zip.
Extract zip.

	cd /tmp
	unzip ~/OpenSSL-Win32.zip

Copy DLL to $WIN32_HOME/bin

	cd OpenSSL-Win32/bin
	cp msvcr120.dll libeay32.dll ssleay32.dll $WIN32_HOME/bin/

Copy include and lib to $WIN32_HOME/zlib.

	cd ../include
	mkdir $WIN32_HOME/ssl/include/
	cp -r openssl $WIN32_HOME/ssl/include/
	cd ../lib
	mkdir $WIN32_HOME/ssl/lib/
	cp libeay32.lib ssleay32.lib $WIN32_HOME/ssl/lib/

Compile agent source
====================

Build agent source package.

	cd $GETPERF_HOME
	rex make_agent_src

Thereafter, according to the agent compile steps to install.

	cd {some directory}
	Download zip source and extract.
	($GETPERF_HOME/var/docs/agent/getperf-2.x-Build5-source.zip)
