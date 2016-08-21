Getperf Agent Installation
==========================

This text wrote the steps to set up the agent from the binary package of CentOS 6.5 environment . Different version , distribution , in the case of the Windows environment , please compiled from the source with reference to the Agent compile procedure ] (docs/en/setup/agent_compile.md).

Compile Agent
-------------

Compile the agent source , and create a Web site for download agent binaries.
In a Web browser, acess to http://{server address}/download/, You can download the source module "getperf-2.x-Buildx-source.zip"

    mkdir -p ~/work/src
    cd ~/work/src
    wget http://{server address}/download/getperf-2.x-Build4-source.zip

Unzip the source module and compile.

    unzip getperf-2.x-Build4-source.zip
    cd getperf-agent
    ./configure
    make

BUild the agent module archive.

    perl deploy.pl

When you run, the following directories under the specified directory, files will be generated.

    ptune                                    # Agent home
    getperf-2-Build4-CentOS6-x86_64.tar.gz   # Agent archive
    upload_var_module.zip                    # Agent update module

upload_var_module.zip is the set of files for the download site. Please unzip the home directory of the download site by the following procedure.

    cd $GETPERF_HOME/var/agent/
    unzip {specified directory}/upload_var_module.zip

In the case of Windows environment, please compiled from the source with reference to [Windows version of Agent Setup](docs/setup/windows_agent.html).

Usage
=====

Agent setup
-----------

Download / unzip module , go to the 'ptune/bin'.

    cd $HOME
    wget http://{server address}/download/getperf-2-Build4-CentOS6-x86_64.tar.gz
    tar xvf getperf-2-Build4-CentOS6-x86_64.tar.gz

Edit the configuration file. Run setup.

    cd $HOME/ptune/bin
    ./getperfctl setup

You will need to enter the access key that has been issued in the site initialization during the agent of authentication . After the agent authentication , Web service will update the SSL certificate .
Once the setup is complete , you will start the agent .

    ./getperfctl start

Distribute the automatic startup script to '/etc/init.d/'.

    sudo cp getperfagent /etc/init.d/
    sudo vi /etc/init.d/getperfagent
    (Set the agent home directory to PTUNE_HOME, and set the execution user to GETPERF_USER)
    sudo chkconfig getperfagent on

AUTHOR
======

Minoru Furusawa <minoru.furusawa@toshiba.co.jp>

COPYRIGHT
=========

Copyright (C) 2014-2016, Minoru Furusawa, Toshiba corporation.

LICENSE
=======

This program is released under [GNU General Public License, version 2](http://www.gnu.org/licenses/gpl-2.0.html).
