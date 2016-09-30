監視サーバのバックアップ
========================

バックアップ環境とシナリオ
--------------------------

* 稼働系から待機系に監視データのバックアップをします。
* 日次で、稼働系のZabbix,Cacti,Getperf データのフルバックアップをします。
* 世代管理はせずに直近の1日前のデータをバックアップします。
* 以降に手順を記します。例として稼働系を 192.168.10.2、待機系を 192.168.10.3 として手順を記します。
* 以下例ではバックアップの保存先を待機系の /data/backup としています。
* バックアップ対象は以下の通りです。

   +---------+---------------------------------------------------+
   | Zabbix  | Zabbix 用 MySQL リポジトリ                        |
   +---------+---------------------------------------------------+
   | Cacti   | Cacti 用 MySQL リポジトリ                         |
   +---------+---------------------------------------------------+
   | Getperf | Getperf Gitベアリポジトリ($GETPERF_HOME/var/site) |
   +---------+---------------------------------------------------+
   |         | Getperf SSL管理ディレクトリ(/etc/getperf)         |
   +---------+---------------------------------------------------+

.. note:: 稼働系、待機系は前述のHA構成を前提とし、待機系の切り替えができる状態にします。

MySQLデータ容量の調査
---------------------

稼働系でMySQLデータのバックアップをします。稼働系でMySQLに接続します。

::

   mysql -u root -p

バックアップ対象のデータ容量を確認します。
バックアップ時間はデータ容量に依存します。
データ容量からバックアップ時間の目安を確認します。

::

   select table_schema, sum(data_length+index_length) /1024 /1024 as MB 
   from information_schema.tables where table_schema = "zabbix";

既に稼働中の監視サーバでレプリケーションを構成する場合、MySQLの蓄積データが大きいと、
バックアップ、リストア処理で長時間待たされる場合が有ります。
本制約の回避が必要な場合は、Percona社 XtraBackup などのオンラインバックアップツールを検討して下さい。
以下では MySQL 標準の mysqldump コマンドによるバックアップ手順を記します。
XtraBackup のバックアップについては後のセクションで手順を記します。

バックアップ設定
----------------

**待機系のバックアップディレクトリ作成**

待機系にバックアップ用ディレクトリを作成します。
前述のデータ容量が保存できる領域が必要になります。

::

   ssh -l psadmin 192.168.10.3   # 待機系に接続
   sudo mkdir -p /backup/data

**稼働系、待機系間のssh接続許可設定**

バックアップはrootで実行します。
稼働系から待機系にrootでssh接続できるよう公開鍵を登録します。

::

   ssh -l psadmin 192.168.10.2   # 稼働系に接続
   sudo su -
   ssh-copy-id -i .ssh/id_rsa.pub 192.168.10.3
   exit

**バックアップスクリプト編集**

稼働系で実行します。
以下の箇所を編集します。

::

   vi $GETPERF_HOME/script/backup-getperf.sh


.. code-block:: bash

   TARGET_HOST="192.168.10.3"           # target server ip
   GETPERF_HOME="/home/psadmin/getperf" # Getperf Home Directory
   PASS=mysqlpasswd                     # MySQL root パスワード

手動で実行します。

::

   sudo $GETPERF_HOME/script/backup-getperf.sh

**cronによるスケジュール設定**

cronでsudoした場合に「you must have a tty to run sudo」のメッセージが実行できない制約があるため、
/etc/sudoersから該当行を以下のようにコメントアウトします。

::

   vi /etc/sudoers
   #Defaults    requiretty

cronでスケジュールを設定します。以下例では毎日 3:15AM にバックアップを実行します。

::

   EDITOR=vi
   crontab -E
   15 3 * * * sudo -E /home/psadmin/getperf/script/backup-getperf.sh > /dev/null 2>&1

待機系でのリストア
------------------

**MySQLバックアップデータのリストア**

稼働系からMySQLダンプデータをインポートします。

::

   mysql -u root -p < /backup/data/mysql_dump.sql

**Getperfサイトのリストア**

Getperf の Git ベアリポジトリをリストアします。

::

   cd $GETPERF_HOME
   tar xvf /backup/data/getperf_var_site.tar.gz

リストアした、$GETPERF/var/siteの下に各サイトホームのGit ベアリポジトリが復元されます。
各サイトごとにリストアをします。git clone でベアリポジトリを指定してサイトを復元します。
以下例では 'site1' というサイトの復元例を記します。

::

   cd $HOME
   git clone $GETPERF_HOME/var/site/site1.git

以下のコマンドで復元したサイトの初期化をします。

::

   initsite --update ./site1

サイト集計デーモンの再起動をします。

::

   (cd ./site1; sumup restart)

以上でサイトの復元は完了です。上記手順を各サイトごとに実行します。

**SSL証明書のリストア**

以下コマンドでSSL証明書をリストアします。psadmin ユーザで実行してください。

::

   cd /
   tar xvf getperf_etc.tar.gz

パックアップデータからの復元は以上です。次に、以下の待機系の系切り替え作業を行います。
本手順の詳細は前節のサーバのHA化を参照してください。

* VIPの活性化
* Zabbixサーバの起動

XtraBackupでのデータバックアップ
--------------------------------

.. note:: MySQL標準のバックアップコマンド mysqldump を使用せずに、Percona製XtraBackupによるバックアップ手順を記します。

yumで Percona 製 XtraBackup をインストールします。
稼働系、待機系の両方で必要になりますので順にインストールします。

::

   sudo -E rpm -Uhv http://www.percona.com/downloads/percona-release/percona-release-0.0-1.x86_64.rpm
   sudo -E yum install xtrabackup

稼働系でバックアップスクリプトを編集します。

::

   vi $GETPERF_HOME/script/backup-getperf.sh

以下の、mysqldumpコマンドの箇所をコメントアウトして、innobackupexコマンドの箇所のコメントを外します。

.. code-block:: bash

   # mysqldump command for MySQL Backup
   # (
   #  time mysqldump --user=${USER} --password=${PASS} \
   #      --single-transaction --all-databases --quick --routines \
   #      | ssh $TARGET_HOST 'cat > /backup/data/mysqldump.dmp'
   # )

   # Percona XtraBackup command for MySQL Backup
   (
      time innobackupex /var/lib/mysql/ --user ${USER} --password ${PASS} --stream=tar \
         | ssh $TARGET_HOST 'cat - > /backup/data/xtrabackup.tar'
   )

手動で実行します。

::

   sudo $GETPERF_HOME/script/backup-getperf.sh

cron の設定をします。
手順は mysqldump と同様です。

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

