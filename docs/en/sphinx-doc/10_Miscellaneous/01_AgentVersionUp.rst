Agent version up of
==============================

Agent manages the version build number. If the build of the monitored agent is old, it has the ability to download the new version from the monitoring server. The procedure is as follows.

Advance preparation
--------

To the monitoring server you need to have the latest compiled agent package. \ `In accordance with the agent compile procedure <docs / ja / docs / 03_Installation / 10_AgentCompile.md>` _ \, will be provided the latest agent module of each platform. Update file
$ Located under the GETPERF \ _HOME / var / argent / update.

Example: CentOS6 confirmation of the update file (64bit version)

::

    cd $ GETPERF_HOME
    find var / agent / update / CentOS6-x86_64 / -type f
    var / agent / update / CentOS6-x86_64 / 2/5 / getperf-bin-CentOS6-x86_64-5.zip
    var / agent / update / CentOS6-x86_64 / 2/4 / getperf-bin-CentOS6-x86_64-4.zip

Agents of version-up procedure
----------------------------------

Once you stop the agent.

::

    ~ / Ptune / bin / getperfctl stop

Make sure the current version. Make sure the build number in the first line of the title. Example:
GETPERF Agent v2.7.3 (build 4)

::

    ~ / Ptune / bin / getperfctl -v

Run the setup command.

::

    ~ / Ptune / bin / getperfctl setup

If you have the latest build will show Messe maintenance of the following updates.

::

    The latest getperf exists [the current build: 4 <5]
    Are you sure you want to update the module (y / n)?:

y
Enter the Download the latest module, unzip the module according to the procedure of the output message.

::

    cd ~ / ptune
    unzip ~ / ptune / _wk / getperf-bin-CentOS6-x86_64-5.zip

getperfctl -v
In Once you have verified that the build number has been updated, and then start the agent.

::

    ~ / Ptune / bin / getperfctl start
    