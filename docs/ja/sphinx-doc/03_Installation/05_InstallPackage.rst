パッケージインストール
======================

各種パッケージをインストールします。

MySQL 8.0 インストール
----------------------

パッケージインストールの前に、バージョン8 を指定して MySQL パッケージをインストールします。

RH8系の OS の場合、以下のコマンドで OS 標準の AppStream から mysql:8.0 を指定し、
MySQLサーバ(mysql-server) をインストールします。

::

   sudo -E dnf module enable mysql:8.0
   sudo -E yum install mysql-server

RH7系のOS の場合、以下、MySQLドキュメントのMySQL Yum リポジトリを使用して MySQL 
を Linux にインストールするを参考にして、MySQL 8.0 をインストールします。

::

   https://dev.mysql.com/doc/refman/8.0/ja/linux-installation-yum-repo.html

MySQL Yum リポジトリをインストールします。パッケージ名は上記 URL の
ダウンロードページから適切なパッケージ名を確認して入力してください。

::

   wget https://dev.mysql.com/get/mysql80-community-release-el8-4.noarch.rpm
   sudo -E yum localinstall mysql80-community-release-el8-4.noarch.rpm

インストールするMySQLバージョンのリポジトリを確認します。

::

   sudo -E yum -y install yum-utils
   sudo -E yum repolist all | grep mysql

上記リストで MySQL 8.0 より古いリポジトリが有効化されていた場合は、
以下のコマンドで無効化します。

::

   sudo -E yum-config-manager --disable mysql57-community

また、OS 標準の MySQL モジュールのリポジトリを無効化します。

::

   sudo -E yum module disable mysql

上記リストのMySQL 8のリポジトリを有効化します。

::

   sudo -E yum-config-manager --enable mysql80-community

MySQL サーバをインストールします

::

   sudo -E yum -y install mysql-community

MySQL の設定を変更します。

::

   sudo vi /etc/my.cnf

[mysqld]の後に以下の行を追加します。

.. note::

   最後の、default-time-zone は後述のタイムゾーン設定後にコメントアウトを外します。

::

   [mysqld]
   default_authentication_plugin=mysql_native_password
   # MySQL Yum リポジトリからインストールした場合は、以下のパスワード設定のコメントアウトを外してください
   #validate_password.length=4
   #validate_password.mixed_case_count=0
   #validate_password.number_count=0
   #validate_password.special_char_count=0
   #validate_password.policy=LOW
   character-set-server=utf8mb4
   collation-server=utf8mb4_unicode_ci
   #default-time-zone='Asia/Tokyo'


MySQL を起動します

::

   sudo systemctl enable mysqld
   sudo systemctl start mysqld

MySQL の root パスワードを設定します。仮パスワードを確認します。

::

   sudo cat /var/log/mysqld.log | grep 'temporary password'

::

   mysql -u root -p

上記仮パスワードを入力してログインします。
上記で仮パスワードがない場合は ENTER を押してください。

config/getperf_site.json の GETPERF_CACTI_MYSQL_ROOT_PASSWD に記載した、
パスワードを設定します。

::

   USE mysql;
   ALTER USER 'root'@'localhost' identified BY '{パスワード}';

.. note:: 既定のパスワードは、 getperf です。

MySQL に Timezone テーブルをロードします。

::

    mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql -u root -p mysql

設定ファイル(my.cnf)を編集しタイムゾーンを設定します。

::

   sudo vi /etc/my.cnf.d/mysql-server.cnf

default-time-zone を設定します。

::

    （中略）
    [mysqld]
    character-set-server=utf8mb4
    collation-server=utf8mb4_unicode_ci
    default-time-zone='Asia/Tokyo'   #追加

MySQL を再起動します。

::

   sudo systemctl restart mysqld


PHP 7.3 インストール
---------------------

PHP 7.3 のバージョンを選択して、PHP パッケージをインストールします。

PHPモジュールリストを確認します。

::

   sudo -E dnf module list php

::

   Name        Stream         Profiles                          Summary
   php         7.2 [d]        common [d], devel, minimal        PHP scripting language
   php         7.3            common [d], devel, minimal        PHP scripting language
   php         7.4            common [d], devel, minimal        PHP scripting language
   php         8.0            common [d], devel, minimal        PHP scripting language

上記リストから php:7.3 を選択します。

::

   sudo -E dnf module enable php:7.3

PHP パッケージをインストールします。

::

   sudo -E yum -y install php php-cli php-common

また、関連する PHP パッケージをインストールします。

::

   sudo -E yum  install \
      pcre-devel \
      php php-mbstring \
      php-mysqlnd php-pear php-common php-gd php-devel php-cli \
      cairo-devel libxml2-devel pango-devel pango \
      libpng-devel freetype freetype-devel  \
      curl git rrdtool zip unzip \
      mysql-devel

httpd サービスを再起動します。

::

   sudo systemctl restart httpd


Gradle, Ant インストール
------------------------

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

その他
------

Apache HTML ホームページのアクセス権限を変更します。

::

   sudo chmod a+wrx /var/www/html

PHP設定ファイル /etc/php.ini を変更します。

::

   cd $GETPERF_HOME
   sudo perl ./script/config-pkg.pl php
