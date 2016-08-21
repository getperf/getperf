Agent compile
======================

Getperf agent is a coded binary modules in the C language, it assumes the installation of by a plurality of the monitored server. It has taken the following approach you in order to improve the efficiency of the work of the monitored.

1. Prepare a module tailored to the monitored environment
2. Installation work in a monitored to minimize the step

1 is a pre-compiled work of the monitored platform in such as the development environment, 2 will be the task of packaging the agent module. Working with the monitor, package download, extract, and a confirmation of minimal activity only. In order to achieve these efficiency, it has a higher load of pre-preparatory work. It wrote that flow in the figure below.

.. Figure :: ../image/agent_compile.png
   : Align: center
   : Alt: Agent Installation procedure

   Agent installation procedure

1. Create a pre-compiled package

   SSL certificate of the monitoring server, Getperf agent source, to create an archive that summarizes the binary of Zabbix agent of each platform.

2. Compilation of the development environment

   Linux, on each, such as Windows platform, to compile and download the archive that was created in 1. On each platform
   C compiler is required.

3. upload to the download site

   The compiled binary and packaging, and upload it to the monitoring server.

4. package download and installation

   You download and install the pre-compiled packages.

1-3 becomes the advance preparation work, 4 becomes part of the installation on the monitored side.

Creating Agent precompiled package
==========================================

Agent download site created
----------------------------------

Set the download for the Web page.

::

    cd $ GETPERF_HOME
    sudo -E rex prepare_agent_download_site

Precompiled package creation
----------------------------

Create a pre-compiled modules of the agent.

::

    rex make_agent_src

This is, SSL certificate for the Web service, the agent source code, will be the module that the Zabbix agent and packaging. In a Web browser http: // Please open the {server address} / download. getperf-2.x-BuildX-source.zip in the list will be the pre-compiled packages.

.. Note ::

    For * 403 Forbidden error

      You may get an error that when you open a Web browser 'You do not have permission to access'.
      Since there is a possibility of Getperf management user's home directory permissions problem, in that case, please try to add the reference authority in the home directory in the following.

      ::

        chmod a + rx ~ /

Compiled on each platform
================================

Compiling in Linux environment
-----------------------

Download and compile the pre-compiled packages. An example of a case where a ~ / work / src directory to the working directory you noted below.

::

    mkdir -p ~ / work / src
    cd ~ / work / src
    wget http: // {server address} /docs/agent/getperf-2.x-Build5-source.zip

Extract the source module.

::

    unzip getperf-2.x-Build5-source.zip

Create a header file of the Linux distribution. After the execution, Linux distribution information is recorded include / gpf_common_linux.h header file is generated.

::

    cd getperf-agent
    perl make_linux_include.pl

Compile the source.

::

    ./configure
    make

Using deploy.pl script, and then packaged as a pre-compiled packages.

::

    perl deploy.pl

Please specify the package of output destination to the appropriate directory. The default is the home directory. SSL certificate, Web Service URL, enter the enter key remains the default. When you run, the following directory under the specified directory, the file will be generated.

::

    ptune # agent home directory
    getperf-2-Buildx-xxx-xxx.tar.gz # archive of agent Home
    upload_var_module.zip # agent home, archive of the update module

upload_var_module.zip becomes the archive file a set of files for the download site, and upload it to the monitoring server.

::

    cd {package of destination}
    scp upload_var_module.zip {management user} @ {monitoring server address}: / tmp /

Please unzip the home directory of the download site by the following steps on the monitoring server side.

::

    cd $ GETPERF_HOME / var / docs / agent /
    unzip /tmp/upload_var_module.zip

Compile in a Windows environment
-------------------------

Advance preparation
~~~~~~~~

Installation of VisualStudio C compiler
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

And compile it using the Visual C ++. If there is no compiler environment, Microsoft Corporation
`Please install from the Visual Studio Express <https://www.visualstudio.com/downloads/>` _ download site.
Since all the libraries used at the bottom of the agent source win32 additional package in principle is not necessary.
Use the library are as follows.

  - Zlib1.2.5
  - OpenSSL 1.0.0e

Installation of Perl
^^^^^^^^^^^^^^^^^^^

Use the Perl in the task of creating compiled package. `ActivePerl development site from <http://www.activestate.com/>` _, please download and install the latest version of Windows for Perl.

Installation of 7zip
^^^^^^^^^^^^^^^^^^^

In addition, you can use the 7zip in the compression work of the package. `Please download and install from 7zip development site <https://sevenzip.osdn.jp/download.html>` _.

compile
~~~~~~~~~~

From the Start menu, choose VisualStudio command prompt (Developper Command Prompt), to launch the command prompt. This is, nmake, it will command prompt the path of the compiler tool has been set in the environment variable, such as cl.
c: it was created as a working directory and note the procedure on the assumption that the compiled under the.

::

    mkdir c: \ work
    cd c: \ work

And download pre-compiled packages were thawed. http from the Web browser: // {open the monitoring server address / download, the pre-compiled packages getperf-2.x-Build5-source.zip c: and download it to. By using a file decompression tool, and unzip it.

::

    c: \ work> cd getperf-agent
    c: \ work \ getperf-agent> nmake / f Makefile.win

And packaging as a compiled package.

::

    c: \ work \ getperf> perl deploy.pl

File that is created is the same as that of Linux, to upload the upload_var_module.zip to the monitoring server, and unzip the bottom of the monitoring server of $ GETPERF_HOME / var / agent /.

Compilation of a UNIX environment
----------------------

Basic will be the same as the Linux compilation procedure. The notes you wrote below.

- How to compile error in the source code with a UTF-8 BOM

   As well as Linux use the gcc compiler, but there are cases where the version of gcc parsing error of UTF-8 BOM of source code occurs when old. BOM as follows using the code conversion tools, such as the case nkf command
   Please delete the

   find -name '* .h' -o -name '* .c' | xargs nkf -oc = UTF-8 --overwrite
  