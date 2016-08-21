Directory structure
================

The directory structure of the monitoring server
～～～～～～～～～～～～～～～～～～～～～～～～～～～～

Directory structure of the software to be installed in the monitoring server is as follows.

- ** / Usr / local ** Apache HTTP server for the agent for Web services under the
   Place the Tomcat Web container.
- ** / Home / {install user} / getperf **
   And the body of the aggregate module under the, document, and place the set of configuration files under the home directory OS general user.
- Place the ** / etc / getperf / ssl ** of SSL certificates for Web service communication for the agent under.
- ** Of any directory **
   Monitoring site-specific data, set to, and place the summary definition file. During the initialization command execution of monitoring site to specify the site home directory (SITE \ _HOME).

Directory configuration of the monitoring agent
～～～～～～～～～～～～～～～～～～～～～～～～～～～～～～～～～～

Monitoring agent will place a set of modules under the home directory of the general user.

- Installation is to download the pre-compiled binary packages, and unzip it.
- Although installation is optional, usually placed under the home directory of the monitoring agent dedicated general user ($ HOME / ptune).
- It is also optional Windows environment, but the default c: of place it below.
- You must have disk capacity of 100 MB to the directory for the agent.

Use port of each software
--------------------------

Ports that each software in monitoring the server uses are as follows. These port is to be described in the pre-set file, it is possible to specify a different port.

.. Table :: Truth table for "not"

================================= ============= ==== =======
Use setting software use port
================================= ============= ==== =======
Cacti Web console Apache HTTP 80
Agent Web Service (for management) Apache HTTP 57000
                                  Apache HTTPS 57443
                                  Tomcat for management 57,005
                                  Tomcat AJP for 57009
Agent Web services (for data) Apache HTTP 58000
                                  Apache HTTPS 58443
                                  Tomcat for management 58005
                                  Tomcat AJP for 58009
Zabbix Web console (optional) Apache HTTP 80
Zabbix server (optional) Zabbix 10050
GraphiteWeb console (optional) Python 8081
Graphite loader (optional) Python 2003
GrafanaWeb console (optional) NodeJS 3000
================================= ============= ==== =======

Zabbix is ​​an option, but the default is enabled.