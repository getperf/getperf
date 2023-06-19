PHP, MySQL, Cacti 設定
======================

PHP セットアップ
----------------

PHP のパッケージ管理ツール Composer を用いて関連ライブラリをインストールします。

事前に関連パッケージをインストールします。

::

    sudo -E yum install php-json

Rex コマンドで PHP 関連ライブラリをインストールします。

::

    rex prepare_composer

MySQL セットアップ
------------------

MySQL のアカウント管理の設定
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

MySQL のアカウント管理の設定を変更します。

::

    sudo vi /etc/my.cnf

[mysqld]の後に、以下のパラメータを追加します。

::

    [mysqld]
    default_password_lifetime=0
    # MySQL Yum リポジトリからインストールした場合は、以下のパスワード設定のコメントアウトを外してください
    #validate_password.length=4
    #validate_password.mixed_case_count=0
    #validate_password.number_count=0
    #validate_password.special_char_count=0
    #validate_password.policy=LOW
    default_authentication_plugin=mysql_native_password

設定を反映させるため、MySQLを再起動します。

::

    sudo service mysqld restart

root パスワードとセキュリティ設定
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

MySQL の root パスワード変更します。インストール直後は仮パスワードが設定
されているため、以下のMySQL ログを参照して仮パスワードを確認します。

::

    sudo tail -f /var/log/mysqld.log

以下メッセージの仮パスワードを確認します。

::

    2023-05-25T08:14:10.352205Z 6 [Note] [MY-010454] [Server] A temporary password is generated for root@localhost: r(dMMtQl2(df

上記で仮パスワードがない場合は以降のパスワード入力で ENTER を押してください。

MySQLのセキュリティ設定スクリプトを実行します。

::

    mysql_secure_installation

コンソールから、以下を入力してスクリプトを完了します。
パスワードは getperf_site.json 設定ファイル更新で設定したパスワードを入力します。

::

    mysql_secure_installation
    Set root password? [Y/n]　※エンター
    New password:　※パスワードを設定 ⇒ 設定ファイルの作成で編集した MySQLパスワードを指定
    Remove anonymous users? [Y/n]　※エンター
    Disallow root login remotely? [Y/n]　※エンター
    Remove test database and access to it? [Y/n]　※エンター
    Reload privilege tables now? [Y/n]　※エンター

MySQL Timezone, 文字コード設定
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

MySQL に Timezone テーブルをロードします。

::

    mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql -u root -p mysql

設定ファイル(my.cnf)を編集し、文字コードとタイムゾーンを設定します。

::

    sudo vi /etc/my.cnf

[mysqld]の後に、以下のパラメータを追加します。

::

    [mysqld]
    character-set-server=utf8mb4
    collation-server=utf8mb4_unicode_ci
    default-time-zone='Asia/Tokyo'

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

.. MySQL チューニングパラメータ設定
.. ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
.. 
.. MySQL チューニングパラメータを設定します。

.. ::

..     sudo vi /etc/my.cnf

.. [mysqld]の後に、以下のパラメータを追加します。

.. ::

..     [mysqld]
..     max_allowed_packet=16777216
..     max_heap_table_size=248M
..     tmp_table_size=248M
..     join_buffer_size=7M
..     innodb_file_per_table=ON
..     innodb_buffer_pool_size=912M
..     innodb_doublewrite=OFF
..     innodb_flush_log_at_trx_commit=2
..     innodb_flush_log_at_timeout=3
..     innodb_read_io_threads=32
..     innodb_write_io_threads=16
..     innodb_io_capacity=5000
..     innodb_io_capacity_max=10000

.. パラメータを反映させるため、MySQL を再起動します。

.. ::

..     systemctl restart mysqld

Perl MySQL ライブラリのインストール
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

以下コマンドで Perl MySQL ライブラリをインストールします。

::

    sudo -E cpanm DBD::mysql

Cacti セットアップについて
--------------------------

Getperf 3.1 から Cacti は個別インストールするのではなく、
$GETPERF_HOME/var/cacti の下に Cacti モジュールをバンドルする構成に変更しました。
Cacti を個別インストールする必要はなく、 Cacti のインストールは後述の監視サイト
初期化コマンドで行います。

詳細は、 サイト初期化コマンド :doc:`../10_AdminCommand/01_SiteInitialization` 
を参照してください。


