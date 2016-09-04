監視サーバのバックアップ
=============================

**稼働系MySQLデータのバックアップ**

稼働系でMySQLデータのバックアップをします。稼働系でMySQLに接続します。

::

   mysql -u root -p

バックアップ対象のデータ容量を確認します。
バックアップ時間はデータ容量に依存します。
データ容量からバックアップ時間の目安を確認します。

::

   select table_schema, sum(data_length+index_length) /1024 /1024 as MB 
   from information_schema.tables where table_schema = "zabbix";

.. note::

   既に稼働中の監視サーバでレプリケーションを構成する場合、MySQLの蓄積データが大きいと、
   バックアップ処理で長時間待たされる場合が有ります。
   MySQL 標準のバックアップコマンド mysqldump は実行中にDB全体にロックを掛ける為、その間の監視運用に影響が生じる場合が有ります。
   本制約の回避が必要な場合は、Percona社 XtraBackup などのオンラインバックアップツールを使用して下さい。
   XtraBackup のバックアップについては次のセクションで手順を記します。

全テーブルをロックします。

::

   flush tables with read lock;

バイナリログのステータスを表示します。

::

   show master status;

待機系のスレーブ設定で、File, Position を使用するので値を控えておきます。

::

   +-------------------+----------+--------------+------------------+
   | File              | Position | Binlog_Do_DB | Binlog_Ignore_DB |
   +-------------------+----------+--------------+------------------+
   | mysqld-bin.000002 |      107 |              |                  |
   +-------------------+----------+--------------+------------------+

上記端末は残したまま、別端末を追加で開き、ダンプを実行します。

::

   mysqldump -u root -p --all-databases --lock-all-tables --events \
   > mysql_dump.sql

元の端末に戻って、ロックを解除します。

::

   unlock tables;
   exit;

ダンプファイルを稼働系から待機系にコピーします。

::

   scp mysql_dump.sql 192.168.10.2:/tmp/

**MySQLバックアップデータのリストア**

稼働系から転送したダンプデータをインポートします。

::

   mysql -u root -p < /tmp/mysql_dump.sql

**XtraBackupでのデータバックアップ**

yumでインストールします。
稼働系、待機系の両方で必要になりますので順にインストールします。

::

   sudo -E rpm -Uhv http://www.percona.com/downloads/percona-release/percona-release-0.0-1.x86_64.rpm
   sudo -E yum install xtrabackup


任意の場所にバックアップを取得します。ここでは、/backup/xtrabackup/の下にバックアップします。

::

   sudo mkdir -p /backup/xtrabackup/
   sudo time innobackupex --user root --password mysql_password \
   /backup/xtrabackup/

completed OK!が出れば完了です。
メッセージにbinlogのファイル名とpositionも出力されますのでfilenameとpositionの値を控えておきます。

::

   innobackupex: MySQL binlog position: filename 'mysqld-bin.000001', position 310

バックアップ処理中の更新ログを適用します。
--apply-logオプションは、全コマンドで実行したバックアップディレクトリを指定します。

::

   sudo innobackupex --user root --password mysql_password \
   --apply-log /backup/xtrabackup/2016-08-28_11-15-12

バックアップディレクトリをアーカイブし、待機系にコピーします。

::

   cd /backup/
   tar cvf - xtrabackup/2016-08-28_11-15-12 | gzip > backup.tar.gz
   scp  backup.tar.gz root@192.168.10.2:/tmp/

**XtraBackupの場合のリストア**

XtraBackupを使用した場合の待機系リストア手順は以下の通りです。

.. note:: 以下のリストア作業はすべて、rootで実行してください。

MySQLを停止し、データディレクトリを退避して新たにデータディレクトリを作成します。

::

   /etc/init.d/mysqld stop
   mv /var/lib/mysql /var/lib/mysql.old
   mkdir /var/lib/mysql

バックアップファイルを解凍し、解凍してできたディレクトリを指定して、リストアを実行します。

::

   cd /tmp/
   tar xvf backup.tar.gz
   time innobackupex --copy-back /tmp/xtrabackup/2016-08-28_11-15-12

ディレクトリの権限をmysqlに変更してMySQLをスタートします。

::

   chown -R mysql:mysql /var/lib/mysql
   /etc/init.d/mysqld start

