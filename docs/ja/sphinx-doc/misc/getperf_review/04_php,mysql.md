PHP 設定
---------

sudo yum install php-json

rex prepare_composer



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
    SELECT @@global.time_zone;


cactiuser が Timezone テーブルにアクセスできるよう権限を付与します。

::

    MariaDB [(none)]> GRANT SELECT ON mysql.time_zone_name TO 'cactiuser'@'localhost' IDENTIFIED BY 'P@ssw0rd';

