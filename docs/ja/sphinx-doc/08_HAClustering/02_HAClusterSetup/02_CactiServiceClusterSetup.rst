CactiサービスノードのHA化
-------------------------

構成概要
^^^^^^^^

HA化ポリシー
~~~~~~~~~~~~

既設 Cacti サーバーから新規 Cacti サービスノードに移行をします。
Cacti サービスノードは VM 環境のシングルノードにするか、
オンプレ環境でマスター、スレーブ構成にするかを選択します。

VM 構成で仮想化インフラ側でHA機能を使用する場合は、
シングルノード構成とし、後述の既設の Cacti サイトからの移行を行います。
マスター、スレーブ構成にする場合は各ノードのサイト移行後に、
マスター、スレーブ間で同期設定を行います。

.. note::

   VM構成でノード障害が発生した場合、切り替わった別ノードで
   障害発生期間中のデータ集計を自動で再開します。
   オンプレ構成の場合、マスター、スレーブ構成でデータ集計を
   二重化し、ノード障害時にVIPでサービスの切り替えをします。

冗長化する機能
~~~~~~~~~~~~~~

オンプレのマスター、スレーブノード構成の場合、以下の機能を二重化します。

* 性能データのデータ集計
* Cactiによるグラフ表示

事前準備
^^^^^^^^

スタンドアロン構成での基本モジュールセットアップをします。
:doc:`../../03_Installation/index` の手順に従い、「MySQL, Cacti インストール」までを行います。

.. note::

   Webサービスは不要なため、「Web サービスインストール」の手順は省略してください。

既設の Cacti サイトからの移行
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

既設の Cacti サイト定義のバックアップ
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

現Cactiでサイト定義のバックアップをします。
既設の Cacti サイトのサイトホームに移動し、mysqldump コマンドを用いて、
Cacti リポジトリデータベースをダンプします。
以下手順では、サイトID が site1 、サイトホームが $HOME/work/site1 の手順を記します。

::

   cd ~/work/site1
   mysqldump -u root -p site1 > mysql.dmp

.. note::

   root パスワードは、~/getperf/config/getperf_site.json 設定ファイルの、
   GETPERF_CACTI_MYSQL_ROOT_PASSWD の値を入力します。

サイトホーム下のファイルをアーカイブします。
集計データ保存用ディレクトリの analysis, summary, storage を除いた全ファイルを
バックアップします。

::

   tar cvf - mysql.dmp lib script/ Rexfile node/ html/ view/ | gzip > /tmp/archive_site1.tar.gz

新規 Cacti サービスノードでのリストア
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

構築した Cacti サービスノードでサイト定義のリストアをします。
オンプレの場合、マスター、スレーブの両ノードでリストアをしてください。
バックアップしたサイトIDと同じ名前で、サイトの初期化を作成します。
既設のCactiサイトの Git リポジトリからサイトをクローンします。

::

   cat ~/work/site1/.git/config

::

   [core]
           repositoryformatversion = 0
           filemode = true
           bare = false
           logallrefupdates = true
   [remote "origin"]
           fetch = +refs/heads/*:refs/remotes/origin/*
           url = ssh://psadmin@alpaca2.rama//home/psadmin/getperf/var/site/site1.git

::

   cd work
   git clone ssh://psadmin@192.168.10.32//home/psadmin/getperf/var/site/site1.git

::

   cd site1
   initsite --update -f .

.. note::

   '-f'オプションで既に作成済みサイトも強制的に再作成する設定で実行します。

作成したサイトホームに移動して、バックアップしたアーカイブファイルをコピーします。

::

   cd ~/site1
   scp psadmin@{既設CactiサーバIP}:/tmp/archive_site1.tar.gz .

コピーしたアーカイブファイルを解凍します。

::

   tar xvf archive_site1.tar.gz

MySQL ダンプファイルをリストアします。

::

   mysql -u root -p site1 < mysql.dmp

RSyncによるデータ集計セットアップ
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

手動でデータ集計動作を確認します。
Cacti 受信ノードから Zip 性能データを受信し、リストアしたサイトホーム下で
データ集計を行います。
はじめにサービスノードから rsync コマンドを用いて、 RSync 疎通を確認します。

::

   mkdir /tmp/rsync_test
   rsync -av --delete rsync://192.168.10.41/archive_site1 /tmp/rsync_test

以下のコマンドでデータ集計を実行します。

::

   cd ~/site1
   ${GETPERF_HOME}/script/sitesync -t 1 \
   rsync://192.168.10.41/archive_site1

RSync によるデータ同期スケジュール設定をします。
RSyncスクリプトを編集して、上記データ集計コマンドを登録します。

.. note:: ＜手順確認中＞

cron で定期起動の設定をします。

上記で、sitesyncスクリプトの同作確認ができたら、cron による定期起動の設定をします。

::

   0,5,10,15,20,25,30,35,40,45,50,55 * * * * (cd {サイトホーム}; {GETPERFホームディレクトリ}/script/sitesync rsync://{旧監視サーバアドレス}/archive_{サイトキー} > /dev/null 2>&1) &

Webブラウザから移行した Cacti サイトに接続し、グラフ表示がされていることを確認します。

::

   http://{新CactiサービスノードIP}/site1

.. note::

   後述のグラフデータのバックアップリストアをしていないため、
   直近のグラフデータのみの表示となります。

RRDtool グラフデータのバックアップリストア
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

RSyncコマンドを用いて、RRDtool グラフデータファイルをバックアップリストアします。
{サイトホーム}/storage 下の RRDtool ファイルを既設　Cactiからサービスノードにコピーします。

新Cactiサービスノード上でrsyncコマンドを実行します。
はじめに-nオプション(予行演習モード)で全転送サイズを確認します。

::

   rsync -avn psadmin@{既設CactiサーバIP}:~/site1/storage/ ~/site1/storage/
   <中略>
   sent 211 bytes  received 1747 bytes  559.43 bytes/sec
   total size is 1029252168  speedup is 525665.05 (DRY RUN)

最後行の total size が全転送サイズとなります。
本値をソース、ターゲット間の転送速度で割って、リストアの所要時間を見積もります。

以下のコマンドでバックアップリストアを実行します。

::

   rsync -av --delete psadmin@{既設CactiサーバIP}:~/site1/storage/ ~/site1/storage/

マスター、スレーブ構成の同期設定
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Cactiリポジトリデータベースの同期設定
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

MySQLデータレプリケーション設定をします。

**MySQL 監視用のユーザ作成**

MySQL Ping監視用ユーザを作成します。マスターノード、スレーブノードの順で実行します。

::

   mysql -u root -p

MySQL コンソールからレプリケーション用ユーザ repl を作成します。

::

   grant replication slave on *.* to repl@'%' identified by 'repl';
   grant all privileges on *.* to repl with grant option;
   flush privileges;
   exit

**MySQL 設定ファイル編集**

MySQL 設定ファイルにレプリケーション設定を追加します。
マスターノード、スレーブノードの順で実行します。

::

   sudo vi /etc/my.cnf

先頭行に以下を追加します。
server-id は、マスターノードを 101、スレーブノードを 102　にしてください。

::

   [mysqld]
   #バイナリログの出力
   log-bin=mysqld-bin
   #server-idは一意になるように設定する
   # 101:マスターノード, 102:スレーブノード
   server-id=101
   # バイナリログ保存期間
   expire_logs_days = 7

設定を反映するため、 mysqld を再起動します。

::

   sudo /etc/init.d/mysqld restart

**マスターノードMySQLデータのバックアップ**

マスターノードでMySQLデータのバックアップをします。マスターノードでMySQLに接続します。

::

   mysqldump --all-databases -u root -p --master-data --single-transaction --routines \
   > mysql_dump.sql


バックアップが完了したファイルから、CHANGE MASTER TOが含まれる行をgrepして、メモしておきます。

::

   cat mysql_dump.sql | grep -i "CHANGE MASTER TO" | more

::

   CHANGE MASTER TO MASTER_LOG_FILE='mysqld-bin.000001', MASTER_LOG_POS=3443;

ダンプファイルをマスターノードからスレーブノードにコピーします。

::

   scp mysql_dump.sql 192.168.10.32:/tmp/

**MySQLバックアップデータのリストア**

マスターノードから転送したダンプデータをインポートします。

::

   mysql -u root -p < /tmp/mysql_dump.sql

**MySQLレプリケーション設定**

スレーブノードで、MySQLレプリケーションのスレーブ設定をします。
MySQLコンソールに接続し、MySQL レプリケーションのスレーブ設定をします。

::

   mysql -u root -p

change master to コマンドでレプリケーションの開始位置を指定します。
マスターノードで確認した、バイナリログの File, Position を指定します。

::

   change master to
        master_host='192.168.10.1',    # マスターサーバーのIP
        master_user='repl',           # レプリケーション用ID
        master_password='repl',       # レプリケーション用IDのパスワード
        master_log_file='mysqld-bin.000002',    # マスターサーバーで確認した File 値
        master_log_pos=107;    # マスターサーバーで確認した Position 値

レプリケーションを開始します。

::

   start slave;

ステータスを確認します。

::

   show slave status \G

上記結果で、Slave_IO_Running と Slave_SQL_Running が Yes
となり、Last_Error　にエラーメッセージが出力がされていなければOKです。

keepalivedによるVIP 切替設定
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Cacti 受信ノードの VIP をマスターノード、スレーブノード間で冗長化します。

* keepalived を用いて、VIP の冗長化設定をします
* 各ノードの Cacti サイトのレスポンスコード(200 OK)で死活監視をします。
* 監視スクリプトとして、$GETPERF_HOME/script/check_getperf_cacti.sh を使用します。

Web サービス死活監視スクリプトの動作確認をします。
マスタノード、スレーブノードともに終了コードが 0 であることを確認します。

::

   cd ~/getperf/script
   sh -x check_getperf_cacti.sh
   echo $?

各ノードにkeepalived をインストールします。
マスターノード、スレーブノードの順にインストールしてください。

::

   sudo -E yum -y install keepalived ipvsadm

keepalived の VIP 冗長化設定をします。
設定ファイル keepalived.conf をバックアップして編集します。

::

   sudo cp /etc/keepalived/keepalived.conf{,.orig}
   sudo vi /etc/keepalived/keepalived.conf

以下の行を追加します。コメントを記載した行を適宜変更します。

::

   ! Configuration File for keepalived

   global_defs {
      router_id LVS_GETPERF_CACTI
   }

   vrrp_script check_getperf_cacti {
     script       "/home/psadmin/getperf/script/check_getperf_cacti.sh"
     interval 2   # check every 2 seconds
     fall 3       # require 3 failures for KO
     rise 2       # require 2 successes for OK
   }

   vrrp_instance VirtualInstance1 {
       state BACKUP        # マスターノードは MASTER に変更
       interface eth0      # VIPを追加する NIC名
       virtual_router_id 2 # 一意にするID、Cacti受信ノードや他の設定と重複しないこと
       priority 100
       advert_int 5
       nopreempt
       authentication {
           auth_type PASS
           auth_pass passwd
       }
       virtual_ipaddress {
           192.168.10.51/24 # VIPアドレス
       }
       track_script {
         check_getperf_cacti
       }
   }

keepalived を起動します。

::

   sudo service keepalived restart

システムログから keepalived 起動を確認します。

::

   sudo tail -f /var/log/messages
   Jul  5 07:40:06 rama1 Keepalived_vrrp[15465]: VRRP_Instance(VirtualInstance1) Sending gratuitous ARPs on eth0 for 192.168.10.41

keepalived 自動起動設定をします。

::

   sudo chkconfig keepalived on

