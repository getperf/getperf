パッケージインストール
======================

エージェント Web サービスのインストールを行います。
yum を用いて gcc,JDK等の開発環境、Apache、PHP をインストールします。
また、Javaプログラムのビルドツール Apache Antと、Gradleをインストールします

RedHat6,CentOS6の場合
---------------------

EPEL yum リポジトリをインストールします

::

   sudo -E yum -y install epel-release

REMI yum リポジトリをインストールします

::

   cd /tmp
   wget http://rpms.famillecollet.com/enterprise/remi-release-6.rpm
   sudo rpm -Uvh remi-release-6.rpm

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

MySQL をインストールします

::

   sudo -E yum  --enablerepo=remi,epel install mysql-server

Gradle をインストールします

::

   cd $GETPERF
   sudo -E ./script/gradle-install.sh
   sudo ln -s /usr/local/gradle/latest/bin/gradle /usr/local/bin/gradle

Apache HTML ホームページのアクセス権限を変更します

::

   sudo chmod a+wrx /var/www/html

Apache Ant をインストールします

::

   sudo -E rex install_ant

PHP設定ファイル /etc/php.ini を変更します

::

   sudo -E perl ./script/config-pkg.pl php
