PHP 設定
---------

sudo yum install php-json

rex prepare_composer



.. MySQL インストール
.. =========================

.. .. Cacti の インストール
.. .. ---------------------

.. .. epel-release および cactiをインストールします。バージョン：cacti 1.2.23（2023/05/10時点の最新）

.. .. ::

.. ..    sudo -E yum install epel-release
.. ..    sudo -E yum install cacti


.. DBサーバ、phpのインストール
.. ---------------------------

.. 下記コマンドを実行しインストールします。バージョン：PHP 7.2.24、MariaDB 10.3.35（2023/05/10時点の 最新）

.. ::

..     sudo -E yum install mariadb-server
..     sudo -E yum install php

.. MariaDB と httpd を起動し、自動起動を有効化します。

.. ::

..     systemctl start mariadb
..     systemctl enable mariadb
..     systemctl start httpd
..     systemctl enable httpd

.. php の設定を変更します。

.. ::

..     vi /etc/php.ini
..     (省略)
..     max_execution_time = 60
..     (省略)
..     memory_limit = 800M
..     (省略)
..     date.timezone = “Asia/Tokyo”

.. 変更後、httpdをリロードします。

.. ::

..     systemctl reload httpd


.. Apache の設定
.. -------------

.. httpd のバージョンを確認します。

.. ::

..     yum info httpd

.. バージョン確認後、以下の設定を行います。

.. ::

..     vi /etc/httpd/conf.d/cacti.conf
..     # httpd 2.4
..     #Require host localhost
..     Require all granted         #追加

.. httpd を reload します。

.. ::

..     systemctl reload httpd


.. MariaDBの設定
.. -------------

.. アクセス権関連の設定スクリプトを実行します。

.. ::

..     mysql_secure_installation
..     Set root password? [Y/n]　※エンター
..     New password:　※パスワードを設定 ⇒ root
..     Remove anonymous users? [Y/n]　※エンター
..     Disallow root login remotely? [Y/n]　※エンター
..     Remove test database and access to it? [Y/n]　※エンター
..     Reload privilege tables now? [Y/n]　※エンター

.. 文字コードを UTF8 に変更します。

.. ::

..     sudo vi /etc/my.cnf
..     （中略）
..     [mysqld]
..     character-set-server=utf8mb4
..     collation-server=utf8mb4_unicode_ci

.. DBを再起動します。

.. ::

..     systemctl restart mariadb

.. データベースとユーザを作成します。

.. ::

..     mysql -u root -p
..     Enter password:　※MariaDBのrootパスワードを入力
..     MariaDB [(none)]> create database cacti;
..     MariaDB [(none)]> GRANT ALL PRIVILEGES ON cacti.* TO cactiuser@localhost identified by 'P@ssw0rd';
..     MariaDB [(none)]> exit

.. 作成したユーザ名とパスワードを config.php に設定します。

.. ::

..     sudo vi /usr/share/cacti/include/config.php

..     $database_username = 'cactiuser';
..     $database_password = 'P@ssw0rd';

.. 文字コードを変更します。

.. ::

..     mysql -u root -p
..     MariaDB [(none)]> ALTER DATABASE cacti CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
..     MariaDB [(none)]> exit

.. Cacti が提供している SQL 文を読み込み実行します。

.. ::

..     mysql -u cactiuser -p cacti < /usr/share/doc/cacti/cacti.sql


タイムゾーンの設定
------------------

MySQL8だと色々怒られるので、アカウント管理の設定を変更


sudo vi /etc/my.cnf

```
[mysqld]
default_password_lifetime=0
validate_password.length=4
validate_password.mixed_case_count=0
validate_password.number_count=0
validate_password.special_char_count=0
validate_password.policy=LOW
default_authentication_plugin=mysql_native_password
```

MySQLを起動。

sudo service mysqld restart

MySQL のパスワード変更

sudo tail -f /var/log/mysqld.log
2023-05-25T08:14:10.352205Z 6 [Note] [MY-010454] [Server] A temporary password is generated for root@localhost: r(dMMtQl2(df

mysql_secure_installation

getperf_site.json 設定ファイル更新で設定したパスワードを入力


MySQL に Timezone テーブルをロードします。

::

    mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql -u root -p mysql

設定ファイル(my.cnf)を編集しタイムゾーンを設定します。

::

    sudo vi /etc/my.cnf
    （中略）
    [mysqld]
    character-set-server=utf8mb4
    collation-server=utf8mb4_unicode_ci
    default-time-zone='Asia/Tokyo'   #追加

mariadb を再起動します。

::

   sudo systemctl restart mysqld

タイムゾーンの設定が「Asia/Tokyo」になっていることを確認します。

::

    mysql -u root -p
    MariaDB [(none)]> SELECT @@global.time_zone;
    +----------+
    | @@global.time_zone |
    +----------+
    | Asia/Tokyo |
    +----------+

cactiuser が Timezone テーブルにアクセスできるよう権限を付与します。

::

    MariaDB [(none)]> GRANT SELECT ON mysql.time_zone_name TO 'cactiuser'@'localhost' IDENTIFIED BY 'P@ssw0rd';


MariaDB の設定
--------------

MariaDB のパラメータを設定します。
cacti初回起動時の「Pre-installation Checks」中に示される推奨値に基づいて必要に応じて後で調整します。

::

    sudo vi /etc/my.cnf
    （中略）
    default-time-zone=’Asia/Tokyo’
    max_allowed_packet=16777216
    max_heap_table_size=248M
    tmp_table_size=248M
    join_buffer_size=7M
    innodb_file_per_table=ON
    innodb_buffer_pool_size=912M
    innodb_doublewrite=OFF
    innodb_flush_log_at_trx_commit=2
    innodb_flush_log_at_timeout=3
    innodb_read_io_threads=32
    innodb_write_io_threads=16
    innodb_io_capacity=5000
    innodb_io_capacity_max=10000

mariadb を再起動します。

::

    systemctl restart mariadb

.. cron設定
.. --------

.. コメントアウトされている部分を解除します。

.. ::

..     sudo vi /etc/cron.d/cacti
..     */5 * * * * apache /usr/bin/php /usr/share/cacti/poller.php > /dev/null 2>&1

.. crond を再起動します。

.. ::

..     systemctl reload crond


.. 事前準備
.. --------

.. firewalld と SELinux を停止します。

.. ::

..    systemctl stop firewalld
..    systemctl disable firewalld
..    setenforce 0

..    vi /etc/selinux/config
..    # SELINUX=disabled に変更します。

.. Cacti 初期設定
.. --------------

.. Cacti サイトにアクセスします。
.. http://IPアドレス/cacti/ をブラウザで開きます。

.. 初期ユーザ名とパスワードは「admin/admin」です。
.. 初回アクセス時、パスワードの変更が必要です。

.. * ライセンス同意画面にて、右下の「Accept GPL License Agrement」にチェックを付けて、「Select default theme」を「Japanese」にし、「開始」をクリックします。

.. * インストール開始時の Pre-installation Checks (構成チェック)にて、
  推奨値に基づき、/etc/my.cnf等のパラメータの設定変更を行います。
  変更後、httpdのリロード、必要に応じてOS再起動を行います。

.. * Installation Typeの選択画面では「New Primary Server」を選択します。

.. * パスの選択画面ではデフォルトで設定します。

.. * コミュニティ名やポート番号、ポーリングのインターバルの設定画面ではデフォルトで設定します。

.. * Network Range はネットワーク環境に合わせて設定します。

.. * テンプレートはデフォルト(全て選択)で設定します。

.. * Confirm Installation にチェックを付けて、インストールを開始します。

.. インストール完了後、Cacti にアクセスできるようになります。


.. note::

   Cacti 実体のインストールは後述の監視サイト初期化作業で行います。詳細は、 サイト初期化コマンド :doc:`../10_AdminCommand/01_SiteInitialization` を参照してください。


