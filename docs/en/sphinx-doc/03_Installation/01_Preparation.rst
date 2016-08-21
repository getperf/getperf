=====================
Installation
=====================

Advance preparation
========

You will need the following settings in CentOS environment prior to installation. Please skip this section if you have already configured. In addition, Getperf
Installation, to complete the installation of the monitoring server by using the general user with sudo privileges. To create a user in advance, Getperf
To complete the installation as an administrative user.

- Disabling SELinux
- Allow setting of Firewall
- Getperf user-created for the management
- Proxy settings
- Certificate import in-house certificate authority

Disabling SELinux
----------------

Since the setting of the software to be installed is in a setting that SELinux does not work, please disable SELinux. root
Please perform the following in the user.

Check the operating status of SELinux in getenforce command.

::

    getenforce

If the output Enforcing, has SELinux is enabled. Disable SELinux with the following command.

::

    setenforce 0

Edit the / etc / selinux / config, to disable the SELinux state at the time of restart.

::

    vi / etc / selinux / config

The value of the SELINUX change and save the disabled.

::

    SELINUX = disabled

Permission settings of the Firewall
-------------------

Use port of each software in the previous section, you will need an external access permission settings.
If the Firewall settings are, and the permission settings of these ports.
Configuration is done by editing the iptables configuration file, here for simplicity,
Stop the iptables itself to the permission settings of all ports.

::

    sudo /etc/rc.d/init.d/iptables stop
    sudo chkconfig iptables off
    sudo chkconfig ip6tables off

Also, If you can not name resolution of the local host in such DNS, please register with the IP address of the local host to the / etc / hosts.

::

    vi / etc / hosts
    XXX.XXX.XX.XX monitoring server host name

Getperf user-created for the management
-----------------------

Create a Getperf management for the user, and then add the root authority. Work, please run in the root user.
The user name as an example here, we are with psadmin, but please be appropriately changed.

::

    useradd psadmin

Set the password

::

    passwd psadmin

Edit the configuration file with visudo.

::

    visudo

Default
At the end of the line looking for a line of secure_path, / usr / local / bin: Add the / usr / local / sbin

::

    Defaults secure_path = / sbin: / bin: / usr / sbin: / usr / bin: / usr / local / sbin: / usr / local / bin

Add a line of user registration on the last line. In order to run in batch by using the install script, sudo
User, please the setting of no password of NOPASSWD.

::

    psadmin ALL = (ALL) NOPASSWD: ALL

So that the Apache process to be installed can be accessed under the home directory, change the access rights of the home directory

::

    su - psadmin
    chmod a + rx $ HOME

Proxy settings
--------------

Installation is done by downloading a variety of open source from the external Internet. If access via proxy in an intranet environment is required, you will need the following proxy settings. These settings are done in the Getperf management for the user that was created in the user.

Setting the proxy environment
~~~~~~~~~~~~~~~~~~~~

The future of the work is done in the Getperf management user. The proxy server
proxy.your.company.co.jp, you wrote the setting procedure by 8080 as an example the connection port.

Add the proxy server the / etc / hosts
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

::

    sudo vi / etc / hosts

Add the street proxy server in the following example to the last line.

::

    xxx.xxx.xxx.xxx proxy.your.company.co.jp

Environment variable settings of management user
^^^^^^^^^^^^^^^^^^^^^^^^

::

    vi $ HOME / .bash_profile

Add the proxy of the environment variable in the last line. Incidentally add the settings to the / usr / local / bin on PATH.

::

    PATH = $ PATH: $ HOME / bin: / usr / local / bin

    export PATH

    export http_proxy = http: //proxy.your.company.co.jp: 8080
    export HTTP_PROXY = http: //proxy.your.company.co.jp: 8080
    export https_proxy = http: //proxy.your.company.co.jp: 8080
    export HTTPS_PROXY = http: //proxy.your.company.co.jp: 8080
    export ftp_proxy = http: //proxy.your.company.co.jp: 8080

Environment variable settings read

::

    source ~ / .bash_profile

wget proxy settings
^^^^^^^^^^^^^^^^^^^^

::

    vi ~ / .wgetrc

Setting an example

::

    http_proxy = http: //proxy.your.company.co.jp: 8080

Proxy settings of the curl
^^^^^^^^^^^^^^^^^^^^

::

    vi ~ / .curlrc

Setting an example

::

    proxy = http: //proxy.your.company.co.jp: 8080 /

Proxy settings of Gradle
~~~~~~~~~~~~~~~~~~~~~~

::

    mkdir -p ~ / .gradle /
    vi ~ / .gradle / gradle.properties

Setting an example

::

    systemProp.http.proxyHost = proxy.your.company.co.jp
    systemProp.http.proxyPort = 8080
    systemProp.http.proxyUser =
    systemProp.http.proxyPassword =

    systemProp.https.proxyHost = proxy.your.company.co.jp
    systemProp.https.proxyPort = 8080
    systemProp.https.proxyUser =
    systemProp.https.proxyPassword =

    org.gradle.daemon = true

Maven proxy settings
~~~~~~~~~~~~~~~~~~~~~

::

    mkdir ~ / .m2
    vi ~ / .m2 / settings.xml

Setting an example

::

    <Settings>
      <Proxies>
        <Proxy>
          <Active> true </ active>
          <Protocol> http </ protocol>
          <Host> proxy.your.company.co.jp </ host>
          <Port> 8080 </ port>
          <NonProxyHosts> www.google.com | * .somewhere.com </ nonProxyHosts>
        </ Proxy>
      </ Proxies>
    </ Settings>

If the text layout collapse in auto indentation, perform the following vi command before pasting.

::

    : Set paste

The execution of the root user is also required, and the same settings to the / root / .m2.

::

    sudo mkdir /root/.m2
    sudo vi /root/.m2/settings.xml

Proxy settings of sudo runtime git
～～～～～～～～～～～～～～～～～～～～～～～～～～～～～～～

** Could not resolve host 'github.com' deal ** when an error has occurred

In the case of through the proxy, you need to add a proxy to the root of git setting.

::

    sudo vi /root/.gitconfig

Setting an example

::

    [Http]
            proxy = http://proxy.your.company.co.jp:8080

/ Etc / hosts editing
~~~~~~~~~~~~~~~

The case of the environment in which the name server is not enabled, and the address of its own server, you might address setting of the proxy server is required.

::

    sudo vi / etc / hosts

Add the following line.

::

    Host name of XX.XX.XX.XX own server
    YY.YY.YY.YY proxy server name

Certificate Import in-house certificate authority
----------------------------

In the security measures, if SSL authentication by the authentication station access the web site is necessary, install the outside for the certificate authority certificate.

OpenSSL setup
^^^^^^^^^^^^^^^^^^^

From the corporate IS department site to download the certificate to a certificate authority certificate storage directory.
The following work will run on all root. In the following example, to download a certificate archive file called intra_ssl_cert.zip,
You wrote an example to import intra_ssl_cert.cer.

::

    cd / etc / pki / tls / certs /
    wget http://xx.xx.xxx.xxx/YYY/intra_ssl_cert.zip --no-proxy

    unzip intra_ssl_cert.zip
    rm -f intra_ssl_cert.zip

Back up the ca-bundle.crt.

::

    cp -p ca-bundle.crt ca-bundle.crt.bak

Register thawed outside of the certificate to the ca-bundle.crt (append).

::

    cat intra_ssl_cert.cer >> ca-bundle.crt

Java SSL setup
^^^^^^^^^^^^^^^^^^^^

By using the keytool, to install the certificate that you downloaded above to Java.

::

    keytool -import -alias IntraRootCA -keystore / etc / pki / java / cacerts -file /etc/pki/tls/certs/intra_ssl_cert.cer

Enter keystore password: and if you are asked, CentOS
Enter the JDK default "changeit"

.. Note ::

    If keytool is not entered, sudo -E yum -y install
    Please install the JDK in the java-1.7.0-openjdk-devel