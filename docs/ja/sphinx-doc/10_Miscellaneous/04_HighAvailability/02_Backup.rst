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

Zabbix バックアップ検証
=======================

リファレンス
-------------

* (Percona XtraBackupの圧縮メモ)[https://yoku0825.blogspot.jp/2014/05/percona-xtrabackup.html]


ToDo
--------

* Percona XtraBackup インストール
* MySQLパラメータ調整
* テスト

XtraBackupインストール
---------------------------

稼働系、待機系の順で実施します。
Percona社からダウンロードしたrpmファイルをy2iobsv01bからコピーします。

    cd /tmp
    scp psadmin@10.152.32.104:/home/psadmin/getperf/var/agent/misc/percona-xtrabackup-24-2.4.4-1.el6.x86_64.rpm .

yum localinstallでインストールします。

    sudo -E yum localinstall percona-xtrabackup-24-2.4.4-1.el6.x86_64.rpm

インストールされたか、ヘルプを表示してみます。

    innobackupex --help

その他にpbzip2圧縮ツールをインストール

    sudo -E yum --enablerepo=epel install pbzip2

パラメータ調整
---------------------------

MySQLで必要なパラメータはlog-bin,innodb_buffer_pool_sizeとなります。
/etc/my.cnfを見てみます。

    vi /etc/my.cnf

    innodb_buffer_pool_size = 2147483648

    #バイナリログの出力
    log-bin=mysqld-bin
    #server-idは一意になるように設定する
    # 101:マスター, 102:スレーブ
    server-id=101
    expire_logs_days = 7

設定されていたので調整は保留。
ディスク容量確認。

    cd /var/lib/mysql
    du -h -s .
    5.9G    .

    ls -l /var/lib/|grep mysql
    lrwxrwxrwx   1 root     root       22  8月  3 19:03 2016 mysql -> /home2/mysql/mysqldata

    df -h
                           23G  6.0G   16G  28% /home2
    /dev/sdb1              40G   14G   24G  37% /data

SSH公開鍵コピー

    cd /root
    ssh-copy-id -i .ssh/id_rsa.pub root@133.116.134.203


/data/tmp 作成。

    mkdir -p /data/tmp

**ターゲット側**

/data/tmp 作成。

    mkdir -p /data/tmp


テスト
-------------------------------

すべてrootで実行する。
1行目の 'innobackupex /var/lib/mysql' はソース側で、
2-4行目の tar 解凍、innobackupex --apply-log はターゲット側で実行する。

ソース側は事前に以下環境変数を読み込み。

ターゲット側はテストの度に/data/tmp/xtrabackupを削除

    cd /data/tmp
    rm -rf xtrabackup

**tarボールストリーム圧縮なし**

    time innobackupex /var/lib/mysql $BK_OPTS --stream=tar | ssh $TARGET "cat - > /data/tmp/xtrabackup.tar"
    real    1m25.276s

    ls -lh xtrabackup*
    -rw-r--r--. 1 root root 4.0G  9月  9 11:24 2016 xtrabackup.tar

    mkdir xtrabackup
    time tar ixf xtrabackup.tar -C xtrabackup
    real    0m18.506s

    time innobackupex --apply-log xtrabackup
    real    0m4.670s

**tarボールgzip圧縮**

    time innobackupex /var/lib/mysql $BK_OPTS --stream=tar | gzip -c | ssh $TARGET "cat - > /data/tmp/xtrabackup.tar.gz"
    real    5m9.941s

    ls -lh xtrabackup*
    -rw-r--r--. 1 root root 1003M  9月  9 11:32 2016 xtrabackup.tar.gz

    mkdir xtrabackup
    time tar ixf xtrabackup.tar.gz -C xtrabackup
    real    0m37.041s

    time innobackupex --apply-log xtrabackup
    real    0m4.547s

**tarボールpbzip2圧縮(8並列)**

    time innobackupex /var/lib/mysql $BK_OPTS --stream=tar | pbzip2 -p8 -c | ssh $TARGET "cat - > /data/tmp/xtrabackup.tar.bz2"
    real    2m35.366s

    ls -lh xtrabackup*
    -rw-r--r--. 1 root root  692M  9月  9 11:49 2016 xtrabackup.tar.bz2

    mkdir xtrabackup
    time pbzip2 -p8 -dc xtrabackup.tar.bz2 | tar ix -C xtrabackup
    real    0m58.871s

    time innobackupex --apply-log xtrabackup
    real    0m5.285s

**xbstream圧縮なし(1並列)**

    time innobackupex /var/lib/mysql $BK_OPTS --stream=xbstream | ssh $TARGET "cat - > /data/tmp/xtrabackup.xb"
    real    1m29.292s

    ll -h xtrabackup.*
    -rw-r--r--. 1 root root  4.0G  9月  9 11:54 2016 xtrabackup.xb

    mkdir xtrabackup
    time xbstream -x -C xtrabackup < xtrabackup.xb
    real    0m27.646s

    time innobackupex --apply-log xtrabackup
    real    0m4.508s

**xbstream圧縮あり(1並列)**

    time innobackupex /var/lib/mysql $BK_OPTS --stream=xbstream --compress | ssh $TARGET "cat - > /data/tmp/xtrabackup.xb"
    real    1m19.387s

    ll -h xtrabackup.*
    -rw-r--r--. 1 root root  1.4G  9月  9 11:57 2016 xtrabackup.xb

    mkdir xtrabackup
    time xbstream -x -C xtrabackup < xtrabackup.xb
    real    0m13.288s

    time innobackupex --decompress xtrabackup/

    Percona社製 qpress コマンドがないエラー発生(リストア側処理は以降、保留)

        160909 11:59:01 [01] decompressing ./site1/poller_item.frm.qp
        sh: qpress: コマンドが見つかりません
        Error: thread 0 failed.

    time innobackupex --apply-log xtrabackup


**xbstream圧縮あり(8並列)**

    time innobackupex /var/lib/mysql $BK_OPTS --stream=xbstream --compress --parallel=8 | ssh $TARGET "cat - > /data/tmp/xtrabackup.xb"
    real    1m15.403s

    ll -h xtrabackup.*
    -rw-r--r--. 1 root root  1.4G  9月  9 12:06 2016 xtrabackup.xb

    time xbstream -x -C xtrabackup < xtrabackup.xb
    real    0m13.023s

    以下は保留

    $ time innobackupex --decompress --parallel=8 xtrabackup/

    $ time innobackupex --apply-log xtrabackup

リストアテスト
-------------------------------

XtraBackup でリストア作業手順の確認

**事前準備**

作業は全て root で行います。
各種サービスの停止します。

    /etc/init.d/zabbix-server stop
    /etc/init.d/httpd stop
    /etc/init.d/mysqld stop

**データリストア**

/data/tmp/に上記手順で取得したバックアップがある前提で以下を実行します

    cd /data/tmp/
    rm -rf xtrabackup
    tar xvf xtrabackup.tar

## 解凍処理

    mkdir xtrabackup
    time tar ixf xtrabackup.tar -C xtrabackup

するとMySQLのデータディレクトリ配下のファイルが展開されます。

次にリストアです。
事前にmysqlを停止して、mysqlのデータディレクトリ（今回の場合だと/var/lib/mysql）を退避もしくは削除しておく必要があります。

    mv /var/lib/mysql /var/lib/mysql.bak

## WAL(Write Ahead Log)を適用

    innobackupex --user=root --apply-log xtrabackup/

## リストア開始

    innobackupex --copy-back xtrabackup/

# 起動

    chown -R mysql:mysql /var/lib/mysql
    /etc/init.d/mysqld start

以上でリストア完了です。

mysqldump でのバックアップ
------------------------------

    time mysql--single-transaction

    time mysqldump --user root --password Passw0rd --single-transaction --flush-logs --master-data=2 --all-databases --extended-insert --quick --routines | ssh $TARGET 'cat > /data/tmp/mysqldump.dmp'

    > market_dump.sql 2> market_dump.err &

mysqldump -udb_user db_name -pdb_pass | gzip | ssh example.com 'cat > ~/db_name.dump.sql.gz'

   time mysqldump --user root --password Passw0rd --single-transaction --flush-logs --master-data=2 --all-databases --extended-insert --quick --routines | ssh $TARGET 'cat > /data/tmp/mysqldump.dmp'


