パッケージインストール
======================

エージェント Web サービスのインストールを行います。
yum を用いて gcc,JDK等の開発環境、Apache、PHP をインストールします。
また、Javaプログラムのビルドツール Apache Antと、Gradleをインストールします

MySQL 5.6 バージョン指定インストール
---------------------------------------

パッケージインストールの前に、バージョン5.6 を指定して MySQL
パッケージをインストールする

::

    sudo -E yum localinstall http://dev.mysql.com/get/mysql57-community-release-el6-7.noarch.rpm
    sudo -E yum repolist all | grep mysql

    sudo -E yum -y install yum-utils
    sudo -E yum-config-manager --disable mysql57-community
    sudo -E yum-config-manager --enable mysql56-community

    yum info mysql-community-server

    sudo  yum -y install mysql-community-server
    sudo systemctl enable mysqld
    sudo systemctl start mysqld

以降は、mysql-devel 等の依存パッケージも 5.6 系がインストールされるようになる

RedHat7,CentOS7の場合
---------------------

EPEL yum リポジトリをインストールします

::

   sudo -E yum -y install epel-release

REMI yum リポジトリをインストールします

::

   cd /tmp
   wget http://rpms.famillecollet.com/enterprise/remi-release-7.rpm
   sudo rpm -Uvh remi-release-7.rpm

基本パッケージをインストールします

::

   sudo -E yum --enablerepo=epel install \
         autoconf libtool \
         gcc gcc-c++ make openssl-devel pcre-devel \
         httpd php php-mbstring \
         php-mysql php-pear php-common php-gd php-devel php-cli \
         openssl-devel expat-devel \
         java-1.8.0-openjdk java-1.8.0-openjdk-devel \
         redhat-lsb \
         cairo-devel libxml2-devel pango-devel pango \
         libpng-devel freetype freetype-devel libart_lgpl-devel \
         curl git rrdtool zip unzip \
         mysql-devel

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
