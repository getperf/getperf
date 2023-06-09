パッケージインストール
======================



MySQL 8.0 インストール
----------------------

パッケージインストールの前に、バージョン8 を指定して MySQL パッケージをインストールします。



::

   wget https://dev.mysql.com/get/mysql80-community-release-el8-4.noarch.rpm

   sudo -E yum localinstall mysql80-community-release-el8-4.noarch.rpm


::

   sudo -E yum repolist all | grep mysql

   sudo yum -y install yum-utils
   sudo yum-config-manager --disable mysql57-community
   sudo yum-config-manager --enable mysql80-community

::

   yum info mysql80-community

   sudo yum module disable mysql

::

   sudo yum -y install mysql-community-server

   sudo  yum -y install mysql-community
   sudo systemctl enable mysqld
   sudo systemctl start mysqld

PHP
---

PHP

dnf module list php

Name        Stream         Profiles                          Summary
php         7.2 [d]        common [d], devel, minimal        PHP scripting language
php         7.3            common [d], devel, minimal        PHP scripting language
php         7.4            common [d], devel, minimal        PHP scripting language
php         8.0            common [d], devel, minimal        PHP scripting language

sudo dnf module enable php:7.3


 sudo dnf install php php-cli php-common
sudo systemctl restart httpd

sudo yum install php-mysqlnd


 sudo vim /var/www/html/info.php

http://192.168.0.59/info.php

つながった

Gradle
-------

Java パッケージマネージャ SDKMAN! をインストールします

::

    curl -s "https://get.sdkman.io" | bash 

.bash_profile に SDKMAN 初期化スクリプトを追加します

::

    vi ~/.bash_profile
    (最終行に追加)
    source "$PATH/.sdkman/bin/sdkman-init.sh"

.bash_profile を再読み込みします

::

    source ~/.bash_profile

インストールできるGradleのバージョン一覧を表示し、6 系の最新バージョンを確認します

::
 
    sdk list gradle

確認したバージョンを指定して Gradle をインストールします

::

    sdk install gradle 6.7.1


.. エージェント Web サービスのインストールを行います。
.. yum を用いて gcc,JDK等の開発環境、Apache、PHP をインストールします。
Javaプログラムのビルドツール Apache Antと、Gradleをインストールします


    sdk list ant

確認したバージョンを指定して Gradle をインストールします

::

    sdk install ant 1.9.15


そのた
------

sudo -E yum  install \
   pcre-devel \
   php php-mbstring \
   php-mysqlnd php-pear php-common php-gd php-devel php-cli \
   cairo-devel libxml2-devel pango-devel pango \
   libpng-devel freetype freetype-devel  \
   curl git rrdtool zip unzip \
   mysql-devel


       .. sudo -E yum --enablerepo=epel install \
       ..      autoconf libtool \
       ..      gcc gcc-c++ make openssl-devel pcre-devel \
       ..      httpd php php-mbstring \
       ..      php-mysqlnd php-pear php-common php-gd php-devel php-cli \
       ..      openssl-devel expat-devel \
       ..      java-1.8.0-openjdk java-1.8.0-openjdk-devel \
       ..      redhat-lsb \
       ..      cairo-devel libxml2-devel pango-devel pango \
       ..      libpng-devel freetype freetype-devel libart_lgpl-devel \
       ..      curl git rrdtool zip unzip \
       ..      mysql-devel



.. MySQL 5.6 バージョン指定インストール
.. ---------------------------------------

.. パッケージインストールの前に、MySQL バージョン5.6 を指定するように
.. yum リポジトリを更新 


.. ::

..    # RHEL7 の場合
..    sudo -E yum localinstall http://dev.mysql.com/get/mysql57-community-release-el6-7.noarch.rpm
..    # RHEL8 の場合
..    sudo -E yum localinstall http://dev.mysql.com/get/mysql57-community-release-el7-10.noarch.rpm

..    sudo -E yum repolist all | grep mysql

..    sudo -E yum -y install yum-utils
..    sudo -E yum config-manager --disable mysql57-community
..    sudo -E yum config-manager --enable mysql56-community

..    sudo dnf module disable mysql     
..    sudo yum info mysql-community-server

.. MySQL パッケージをインストールする

.. ::

..    sudo  yum -y install mysql-community-server
..    sudo systemctl enable mysqld
..    sudo systemctl start mysqld

.. 以降は、mysql-devel 等の依存パッケージも 5.6 系がインストールされるようになる

.. RedHat7,CentOS7の場合
.. ---------------------

.. EPEL yum リポジトリをインストールします

.. ::

..   sudo -E yum -y install epel-release

.. .. note::

..    RHEL8 の場合、

..    ::

..        sudo -E dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm

.. REMI yum リポジトリをインストールします

.. ::

..   cd /tmp
..   wget http://rpms.famillecollet.com/enterprise/remi-release-7.rpm
..   sudo rpm -Uvh remi-release-7.rpm

.. .. note::

..    RHEL8 の場合、

..    ::

..       cd /tmp
..       wget http://rpms.famillecollet.com/enterprise/remi-release-8.rpm
..       sudo rpm -Uvh remi-release-8.rpm

.. 基本パッケージをインストールします

.. ::

..   sudo -E yum --enablerepo=epel install \
..         autoconf libtool \
..         gcc gcc-c++ make openssl-devel pcre-devel \
..         httpd php php-mbstring \
..         php-mysql php-pear php-common php-gd php-devel php-cli \
..         openssl-devel expat-devel \
..         java-1.8.0-openjdk java-1.8.0-openjdk-devel \
..         redhat-lsb \
..         cairo-devel libxml2-devel pango-devel pango \
..         libpng-devel freetype freetype-devel libart_lgpl-devel \
..         curl git rrdtool zip unzip \
..         mysql-devel

.. .. note::

..    RHEL8 の場合の指定。php-mysqlnd に変更。httpd 2.4, php 7.2, python36 が入る

..    ::

..        sudo -E yum --enablerepo=epel install \
..             autoconf libtool \
..             gcc gcc-c++ make openssl-devel pcre-devel \
..             httpd php php-mbstring \
..             php-mysqlnd php-pear php-common php-gd php-devel php-cli \
..             openssl-devel expat-devel \
..             java-1.8.0-openjdk java-1.8.0-openjdk-devel \
..             redhat-lsb \
..             cairo-devel libxml2-devel pango-devel pango \
..             libpng-devel freetype freetype-devel libart_lgpl-devel \
..             curl git rrdtool zip unzip \
..             mysql-devel

Gradle をインストールします

インストールスクリプトを編集して、バージョンを最新 6.7.1 に変更
ダウンロードサイトのURLをhttpからhttpsに変更します

::

   cd $GETPERF_HOME
   vi ./script/gradle-install.sh
   #gradle_version=2.3
   gradle_version=6.7.1

   #wget -N http://services.gradle.org/distributions/gradle-${gradle_version}-all.zip
   wget -N https://services.gradle.org/distributions/gradle-${gradle_version}-all.zip

::

   cd $GETPERF_HOME
   sudo -E ./script/gradle-install.sh
   sudo ln -s /usr/local/gradle/latest/bin/gradle /usr/local/bin/gradle

Apache HTML ホームページのアクセス権限を変更します

::

   sudo chmod a+wrx /var/www/html

Apache Ant をインストールします

::

   sudo -E yum -y install ant

PHP設定ファイル /etc/php.ini を変更します

::

   sudo -E perl ./script/config-pkg.pl php
