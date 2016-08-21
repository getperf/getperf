RRDtool tuning
===================

Data loading process by RRDtool as the number of monitored increase might become a bottleneck.
In that case there is a case package installed RRDtool version is older, performance improvement can be expected by upgrading to a new version.
Compile the source from the development site noted below the steps to install the latest version.

- Yum package: v 1.3.8
- RRDtool site: v 1.5.3

RRDtool Install
---------------

CentOS
~~~~~~

::

    sudo yum -y install cairo-devel libxml2-devel pango-devel pango libpng-devel freetype freetype-devel libart_lgpl-devel

    wget http://oss.oetiker.ch/rrdtool/pub/rrdtool-1.5.5.tar.gz
    tar xvf rrdtool-1.5.5.tar.gz
    cd rrdtool-1.5.5

    export PKG_CONFIG_PATH = / usr / lib / pkgconfig /
    ./configure
    make
    sudo make install

    /opt/rrdtool-1.5.3/bin/rrdtool -v

Ubuntu
~~~~~~

::

    sudo apt-get install libcairo-dev libxml2-dev libghc-pango-dev

    wget http://oss.oetiker.ch/rrdtool/pub/rrdtool-1.5.3.tar.gz
    tar xvf rrdtool-1.5.3.tar.gz
    cd rrdtool-1.5.3

    ./configure
    make
    sudo make install

    /opt/rrdtool-1.5.3/bin/rrdtool -v

Getperf setting
------------

It enabled when you register the rrdtool path to environment variable RRDTOOL \ _PATH.

::

    echo 'export RRDTOOL_PATH = / opt / rrdtool-1.5.5 / bin / rrdtool' >> ~ / .bash_profile
    source ~ / .bash_profile

Result of simple data load tests run by its own PC is now less.

::

    perl t / 4_rrd.t
    ...
    Elapse = 8.550309 # RRDtool v1.3.8
    ...
    Elapse = 2.367747 # RRDtool v1.5.3
    