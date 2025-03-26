2.Zabbixサーバセットアップ
==========================

Zabbixサーバ VM で以下を実行します。

PHP 7.3のインストール
---------------------

PHP 7.3 のバージョンを選択して、PHP パッケージをインストールします。

PHPモジュールリストを確認します。

::

   # psadmin 管理者ユーザに接続して実行
   sudo -E dnf module list php

リストから php:7.3 を選択し、パッケージをインストールします。

::

   # php:7.3 を選択
   sudo -E dnf module enable php:7.3
   # PHP パッケージをインストール
   sudo -E yum -y install php php-cli php-common
   # 関連する PHP パッケージをインストール
   sudo -E dnf install -y php php-mysqlnd php-gd php-xml php-bcmath php-mbstring php-soap

MySQL 8.0のインストールと初期設定
---------------------------------


MySQL 8.0用のリポジトリをインポートし、 MySQL 8 をインストールします。

::

   # MySQL8リポジトリインポート
   sudo -E dnf install -y https://dev.mysql.com/get/mysql80-community-release-el8-1.noarch.rpm
   # MySQLインストール
   sudo -E dnf install -y mysql-server
   # MySQL自動起動設定と起動
   sudo systemctl enable --now mysqld

MySQL初期設定をします。

::

   sudo mysql_secure_installation

コンソールメッセージにしたがって以下を設定します。

   * rootパスワードを設定(規定は、 getperf を入力)。
   * 不要なデフォルトユーザーとデータベースを削除。

MySQLの設定ファイル (server.cnf)を編集します。

::

   sudo vi /etc/my.cnf.d/mysql-server.cnf 

[mysqld] の箇所の以下パラメータを編集します。

::

   [mysqld]

   default_password_lifetime=0
   default_authentication_plugin=mysql_native_password
   character-set-server=utf8mb4
   collation-server=utf8mb4_unicode_ci
   sql_mode=NO_ENGINE_SUBSTITUTION
   default-time-zone='Asia/Tokyo'
   innodb_file_per_table
   skip-character-set-client-handshake
   performance_schema=0
   innodb_log_files_in_group=2
   innodb_buffer_pool_size=システムに応じて設定(規定値：16G)
   innodb_log_file_size=システムに応じて設定(規定値：256M)
   max_connections=システムに応じて設定(規定値：1000)

MySQL に Timezone テーブルをロードします。

::

   mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql -u root -p mysql

MySQL を再起動して設定を反映します。

::

   sudo systemctl restart mysqld

Zabbixリポジトリ追加とサーバインストール
----------------------------------------

Zabbixリポジトリをインポートし、Zabbix サーバをインストールします。

::

   # Zabbix6のリポジトリをインポート
   sudo -E rpm -Uvh https://repo.zabbix.com/zabbix/6.0/rhel/8/x86_64/zabbix-release-6.0-4.el8.noarch.rpm
   # 公開鍵が古い場合に発生するエラーを回避するため、パッケージのキャッシュをクリア
   sudo -E dnf clean all
   # Zabbixサーバと関連パッケージをインストール
   sudo -E dnf install zabbix-server-mysql zabbix-sql-scripts zabbix-apache-conf zabbix-web-mysql zabbix-web-japanese zabbix-selinux-policy zabbix-get


Zabbixデータベース作成とスキーマインポート
------------------------------------------

.. note::

   既存のデータベースを再構築する場合は、以下でデータベースを削除して、
   そのあとにデータベース作成から順に実行してください。

   ::

      mysql -u root -p -e "DROP DATABASE zabbix;"

Zabbixデータベースを作成します。
パスワードの箇所は環境に合わせて修正してください（規定は getperf ）。

::

   mysql -u root -p -e "
   CREATE DATABASE zabbix CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;
   CREATE USER 'zabbix'@'localhost' IDENTIFIED BY '{パスワード}';
   GRANT ALL PRIVILEGES ON zabbix.* TO 'zabbix'@'localhost';
   FLUSH PRIVILEGES;"


Zabbixスキーマをインポートします。

::

   zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz | mysql -u root -p zabbix


Zabbixサーバ設定と起動
----------------------

/etc/zabbix/zabbix_server.confを編集します。

::

   sudo vi /etc/zabbix/zabbix_server.conf

以下のパラメータを設定します。

::

   DBName=zabbix
   DBUser=zabbix
   DBPassword=getperf ※環境に合わせて修正
   StartPollers=250
   StartIPMIPollers=10
   StartPollersUnreachable=10
   CacheSize=256M
   TrendFunctionCacheSize=16M
   ValueCacheSize=256M
   ExternalScripts=/usr/lib/zabbix/externalscripts

以下で設定内容を確認します。

::

   egrep -e '^(DB|Start|Cache|Trend|External|Proxy)' /etc/zabbix/zabbix_server.conf

ZabbixサーバおよびApache/PHPを起動します。

::

   sudo systemctl enable --now zabbix-server httpd  php-fpm

WebコンソールでのZabbixセットアップ
-----------------------------------

ブラウザで Zabbix フロントエンドにアクセスします。URL は以下の通りです：

::

   http://<サーバーのIPアドレスまたはホスト名>/zabbix

1. ウェルカム画面：言語を選択し、「次へ」をクリックします。
2. 前提条件のチェック：必要な PHP モジュールがインストールされていることを確認します。
3. データベース接続の設定：データベースのホスト、データベース名、ユーザー名、パスワードを入力します。
4. Zabbix サーバーの詳細：Zabbix サーバーのホスト名やポート番号を入力します。
5. プリインストールサマリー：設定内容を確認し、「次へ」をクリックします。
6. インストールの完了：インストールが完了したら、ログイン画面が表示されます。
7. ログイン

デフォルトの管理者アカウントでログインします：

   * ユーザー名：Admin
   * パスワード：zabbix
