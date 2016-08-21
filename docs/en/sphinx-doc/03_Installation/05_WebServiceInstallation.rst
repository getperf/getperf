Web service installation
=======================

To complete the installation of the agent Web service. First, by using the yum gcc, development environment such as JDK, Apache, PHP
Install. In addition, the build tool Apache Ant Java programs, install the Gradle

::

    sudo -E rex install_package

Register the start-stop script /etc/init.d/sumupctl of data aggregation service.

::

    sudo -E rex install_sumupctl

Apache installation
------------------

Download the source of the Apache HTTP server, and install it on the under / usr / local. Install the two instances for a data reception for the management,
Respectively, and install in / usr / local / apache-admin and / usr / local / apache-data of the home directory.

::

    rex prepare_apache

Apache version will detect and install the latest 2.2 system from the download site

Tomcat installation
------------------

Download the Tomcat Web container and install it under / usr / local.
As well as the Apache, in and for data reception for the management, respectively, and / usr / local / tomcat-admin
You install the home directory of / usr / local / tomcat-data.

::

    rex prepare_tomcat

Tomcat version will detect and install the latest 7.0 system from the download site

Web service installation
-----------------------

Download the Apache Axis2 Web services engine, and deploy (install) to the Tomcat Web container.

::

    rex prepare_tomcat_lib

In the deployment process is the end, you do Apache, the restart of Tomcat process.
There are cases where service stop error of service restart occurs, but the present error can be ignored. After a successful deployment, Web
It enables access to the Axis2 management screen from the browser.

- Management http: // {IP address of the monitoring server}: 57000 / axis2 /
- Data receiving http: // {IP address of the monitoring server}: 58000 / axis2 /

Once you are Axis2 management screen access, and deploy the Getperf Web service in Axis2.

::

    rex prepare_ws

After a successful deployment, you can check the Web service from the menu of the above-mentioned Axis2 management screen.
Select the Services menu in the Management screen, and select the GetperfService. When you select WSDL (definition information of Web services) will be displayed.
