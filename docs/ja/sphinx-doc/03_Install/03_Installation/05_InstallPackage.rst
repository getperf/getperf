パッケージインストール
======================

各種パッケージをインストールします。

MySQL 8.0 インストール
----------------------

パッケージインストールの前に、バージョン8 を指定して MySQL パッケージをインストールします。

以下のコマンドで OS 標準の AppStream から mysql:8.0 を指定し、
MySQLサーバ(mysql-server) をインストールします。

::

   sudo -E dnf module enable mysql:8.0
   sudo -E yum install mysql-server

MySQL 設定
----------

MySQL の設定をします。

::

   sudo vi /etc/my.cnf.d/mysql-server.cnf

[mysqld]の後に以下の行を追加します。

.. note::

   最後の、default-time-zone は後述のタイムゾーン設定後にコメントアウトを外します。

::

   [mysqld]
   default_password_lifetime=0
   default_authentication_plugin=mysql_native_password
   character-set-server=utf8mb4
   collation-server=utf8mb4_unicode_ci
   sql_mode=NO_ENGINE_SUBSTITUTION
   #default-time-zone='Asia/Tokyo'

MySQL を起動します

::

   sudo systemctl enable mysqld
   sudo systemctl start mysqld

MySQL にログインします。

::

   mysql -u root -p

Oracle Linux の場合はパスワードは無しで ENTER を押してください。

root パスワードを設定します。

::

   USE mysql;
   ALTER USER 'root'@'localhost' identified BY '{パスワード}';
   exit;

.. note:: 既定のパスワードは、 getperf です。

MySQL に Timezone テーブルをロードします。

::

    mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql -u root -p mysql

設定ファイル(my.cnf)を編集しタイムゾーンを設定します。

::

   sudo vi /etc/my.cnf.d/mysql-server.cnf

default-time-zone のコメントアウトを除きます。

::

    （中略）
    [mysqld]
    character-set-server=utf8mb4
    collation-server=utf8mb4_unicode_ci
    default-time-zone='Asia/Tokyo'

MySQL を再起動します。

::

   sudo systemctl restart mysqld

MySQLのセキュリティ設定スクリプトを実行します。

::

    mysql_secure_installation

コンソールから、以下を入力してスクリプトを完了します。
パスワードは getperf_site.json 設定ファイル更新で設定したパスワードを入力します。

::

   mysql_secure_installation
   Set root password? [Y/n] ※エンター
   New password: ※パスワードを設定 ⇒ 設定ファイルの作成で編集した MySQLパスワードを指定
   Remove anonymous users? [Y/n] ※エンター
   Disallow root login remotely? [Y/n] ※エンター
   Remove test database and access to it? [Y/n] ※エンター
   Reload privilege tables now? [Y/n] ※エンター

タイムゾーンの設定が「Asia/Tokyo」になっていることを確認します。

::

   mysql -u root -p
   # タイムゾーンが Asia/Tokyo になっていることを確認
   > SELECT @@global.time_zone;
   # SQLモードが NO_ENGINE_SUBSTITUTION になっていることを確認
   > show VARIABLES LIKE "%sql_mode%";
   > exit;

Perl MySQL ライブラリのインストール
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

以下コマンドで Perl MySQL ライブラリをインストールします。

::

    sudo -E cpanm DBD::mysql



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

composer を実行して、PHP ライブラリをインストールします。

::

   cd ~/getperf
   sudo -E yum install php-json
   rex prepare_composer

php.ini パッチを適用します。

::

   sudo -E perl $HOME/getperf/script/config-pkg.pl php

php-fpm と httpd サービスを再起動します。

::

   sudo systemctl restart php-fpm
   sudo systemctl restart httpd
 
Cactiモジュールダウンロードとパッチ適用
---------------------------------------

Cacti 開発元からモジュールダウンロードとスクリプトのパッチ適用をします。
以下の設定ファイルでダウンロードする Cacti バージョンを指定しています。

::

   cd ~/getperf
   cat config/getperf_cacti.json

::

   {
        "GETPERF_CACTI_HTML":             "/var/www/html",
        "GETPERF_CACTI_ARCHIVE_DIR":      "/home/psadmin/getperf/var/cacti",
        "GETPERF_CACTI_DOWNLOAD_SITE":    "https://files.cacti.net/cacti/linux/",
        "GETPERF_CACTI_ARCHIVE":          "cacti-1.2.24.tar.gz",
        "GETPERF_CACTI_HOME":             "/home/psadmin/getperf/lib/cacti",
        "GETPERF_CACTI_TEMPLATE_DIR":     "template/1.2.24",
        "GETPERF_CACTI_DUMP":             "template/1.2.24/cacti.dmp",
        "GETPERF_CACTI_DOMAIN_TEMPLATES": ["Linux","Windows"],
        "GETPERF_CACTI_CONFIG":           "template/1.2.24/config.php.tpl"
   }

パッチ適用可能なバージョンは、Cacti-0.8.8g か、 Cacti-1.2.24 となり、
どちらかのバージョンの指定があることを確認します。

以下のコマンドでダウンロード、パッチ適用をします。

::
   
   rex prepare_cacti

実行すると、var/cacti の下に以下のような指定バージョンの Cacti ファイルが生成
されることを確認します。

::

   ls  -l var/cacti/
   total 41960
   drwxrwxr-x 18 psadmin psadmin     4096 Feb 27 22:58 cacti-1.2.24
   -rw-rw-r--  1 psadmin psadmin 42958488 Jul  6 15:16 cacti-1.2.24.tar.gz

Gradle, Ant インストール
------------------------

Gradle をインストールします

::

   cd $GETPERF_HOME
   sudo -E ./script/gradle-install.sh
   sudo ln -s /usr/local/gradle/latest/bin/gradle /usr/local/bin/gradle

Apache Ant をインストールします

::

   sudo -E yum -y install ant

その他
------

Apache HTML ホームページのアクセス権限を変更します。

::

   sudo chmod a+wrx /var/www/html

