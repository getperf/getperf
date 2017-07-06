ZabbixのHA化
------------

構成概要
^^^^^^^^

HA化ポリシー
~~~~~~~~~~~~

既設のZabbixサーバの IPをVIPに変更する

MHAでMySQLデータベースの冗長化をする

オンプレ。マスター・スレーブ構成

冗長化する機能
~~~~~~~~~~~~~~

MySQL
Zabbix

事前準備
^^^^^^^^

スタンドアロン構成での基本モジュールセットアップ

マスター、スレーブノードの接続設定

**root の ssh 公開鍵の配布**

MHA のリモート操作用にノード間で root の ssh 接続許可設定をします。
稼働系、待機系の順で各ノードに ssh 公開鍵の配布をします。

::

   sudo ssh-keygen -t rsa -f /root/.ssh/id_rsa -q -N ""
   sudo ssh-copy-id -i /root/.ssh/id_rsa.pub root@192.168.10.1
   sudo ssh-copy-id -i /root/.ssh/id_rsa.pub root@192.168.10.2

**MySQL 監視用のユーザ作成**

MySQL Ping監視用ユーザを作成します。稼働系、待機系の順で実行します。

::

   mysql -u root -p

MySQL コンソールから監視用ユーザ mha と、レプリケーション用ユーザ repl を作成します。

::

   grant all privileges on *.* to mha@'%' identified by 'mha';
   grant replication slave on *.* to repl@'%' identified by 'repl';
   grant all privileges on *.* to repl with grant option;
   flush privileges;
   exit


CactiサービスノードのZABBIX宛先を VIP に設定

::

   vi ~/getperf/config/getperf_zabbix.json

::

   "ZABBIX_SERVER_IP":          "192.168.10.51",

マスターノードの物理IPとVIPのネットワーク切替
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

マスターノードの既設IPをVIPに変更し、新たに物理IPを追加します。
ネットワークスクリプトを編集して、ネットワークの再起動で設定を反映します。
以下設定を想定した手順を記します。

* NIC デバイス名は eth0 とします
* 既設IP、VIP の変更アドレスは 192.168.10.51 とします
* 新IP として追加するアドレスは 192.168.10.52 とします

ネットワークスクリプトの編集

* ifcfg-eth0

   eth0 デバイスの既設 IP を変更します。
   ifcfg-eth0 ファイルをバックアップして以下の編集をします。

   ::

      cd /etc/sysconfig/network-scripts
      sudo cp ifcfg-eth0 ifcfg-eth0.bak
      sudo vi ifcfg-eth0

   以下の IPADDR の箇所を新 IP に変更します。

   ::

      IPADDR=192.168.10.52

* ifcfg-eth0:1

   新たに eth0:1 を追加して、VIP を追加します。
   ifcfg-eth0 ファイルをコピーして以下の編集をします。

   ::

      sudo cp ifcfg-eth0 ifcfg-eth0.bak
      sudo vi ifcfg-eth0

   以下の、DEVICE と IPADDR の箇所を VIP に変更します。

   ::

      DEVICE="eth0:1"
      IPADDR=192.168.10.51

* 70-persistent-net

   OS再起動後も、eth0:1 の設定を反映させるため、以下の設定をします。

   ::

      cd /etc/udev/rules.d/
      sudo cp -p 70-persistent-net.rules 70-persistent-net.rules.org
      sudo vi 70-persistent-net.rules
      # eth0 の行をコピーして、行を追加し、追加した行の NAME の箇所を、
      # NAME="eth0:1" に変更します

上記変更後、ネットワークサービス再起動します。

::

   sudo /etc/init.d/network restart

ip addr コマンドでアドレスが変更されていることを確認します。

::

   ip addr
   1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN
       link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
       inet 127.0.0.1/8 scope host lo
       inet6 ::1/128 scope host
          valid_lft forever preferred_lft forever
   2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP qlen 1000
       link/ether 00:0c:29:06:ac:37 brd ff:ff:ff:ff:ff:ff
       inet 192.168.10.52/24 brd 192.168.10.255 scope global eth0
       inet 192.168.10.51/24 scope global secondary eth0
       inet6 fe80::20c:29ff:fe06:ac37/64 scope link
          valid_lft forever preferred_lft forever


スレーブノードをVIPで受信できるようにする
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

スレーブノードのZabbixのサービス停止

::

   sudo /etc/init.d/zabbix-server stop


Zabbixの受信IPをVIPに設定変更

Zabbix 本体の設定ファイルにVIP設定を追加します。

::

   sudo vi /etc/zabbix/zabbix_server.conf

以下の行をVIPに変更して追加します。

::

   SourceIP=192.168.10.51

**Zabbix エージェントのVIP変更**

Zabbix エージェントの設定をVIPを変更します。

::

   vi ~/ptune/zabbix_agentd.conf

以下の行のIPアドレスをVIPに変更します。

::

   <最終行>
   Server=192.168.10.51
   ServerActive=192.168.10.51


MySQLレプリケーションセットアップ
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

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

MHAセットアップ
^^^^^^^^^^^^^^^

MHAインストール

MHA拡張スクリプトセットアップ

MHA設定ファイルの編集

MHAサービス起動

フェイルオーバーテスト

**MHAインストール**

稼働系、待機系の順に実施します。
`MHA ダウンロードサイト <https://code.google.com/p/mysql-master-ha/wiki/Downloads?tm=2>`_ から最新版のモジュールをダウンロードします。ここでは以下モジュールをダウンロードします。

- MHA Manager 0.56 rpm RHEL6
- MHA Node 0.56 rpm RHEL6

稼働系で MHA Node をインストールします。

::

   sudo -E yum localinstall -y mha4mysql-node-0.56-0.el6.noarch.rpm

待機系で MHA Node と、MHA Manager をインストールします。

::

   sudo -E yum localinstall -y mha4mysql-node-0.56-0.el6.noarch.rpm
   sudo -E yum localinstall -y mha4mysql-manager-0.56-0.el6.noarch.rpm


**MHA拡張スクリプト配布**

待機系でMHA拡張スクリプトを配布します。配布するスクリプトは以下の2種です。

- master_ip_failover

   フェイルオーバー実行時の系切換え拡張スクリプト。MHA のソースコードに添付されたサンプルをベースに以下の機能を追加。

   - VIPの付け替え
   - Zabbixサーバの起動／停止
   - ptuneエージェントの再起動

- master_ip_online_change

   手動でスイッチオーバーをする際の系切替拡張スクリプト。master_ip_failoverと同様の機能を追加。

以下ディレクトリからスクリプトをコピーします。

::

   sudo -E cp $GETPERF_HOME/script/template/mha/master_ip_failover \
   /usr/bin/
   sudo -E chmod 755 /usr/bin/master_ip_failover
   sudo -E cp $GETPERF_HOME/script/template/mha/master_ip_online_change \
   /usr/bin/
   sudo -E chmod 755 /usr/bin/master_ip_online_change

**MHA設定ファイルの編集**

待機系で MHA 設定ファイル /etc/mha.conf を作成します。
$GETPERF_HOME/script/template/mha/ の下の、サンプル mha.conf.sample を参考に設定ファイルを編集してください。

::

   sudo cp $GETPERF_HOME/script/template/mha/mha.conf.sample /etc/mha.conf
   sudo vi /etc/mha.conf

IPアドレスとネットワークデバイスの箇所を環境に合わせて変更します。
編集後、以下のコマンドでMHAの動作確認をします。

::

   sudo masterha_check_ssh --conf=/etc/mha.conf    # ssh 疎通確認
   sudo masterha_check_repl --conf=/etc/mha.conf   # MySQL 疎通確認

**MHAデーモンの常駐化**

待機系でMHAデーモンの常駐設定をします。
起動設定は CentOSで標準インストールされている `upstart <http://upstart.ubuntu.com/>`_ を使用します。

::

   sudo vi /etc/init/mha.conf

::

   description     "MasterHA manager services"

   chdir /var/log/masterha
   exec /usr/bin/masterha_manager --conf=/etc/mha.conf >> /var/log/masterha/masterha_manager.log 2>&1
   pre-start exec /usr/bin/masterha_check_repl --conf=/etc/mha.conf
   post-stop exec /usr/bin/masterha_stop --conf=/etc/mha.conf

設定を反映します。

::

   sudo initctl reload-configuration
   sudo initctl list | grep mha

MHAログディレクトリを作成します。

::

   sudo mkdir /var/log/masterha

MHAデーモンを起動します。

::

   sudo initctl start mha

起動を確認します。

::

   initctl list | grep mha
   ps auxf | grep mha
   sudo tail -f /var/log/masterha/masterha_manager.log

.. note:: 停止するときは、以下のコマンドを実行します。

   ::

      sudo initctl stop mha

**フェイルオーバーテスト**

ここでは、簡単に稼働系でMySQLをkillしてフェイルオーバー動作を確認します。
待機系でMHAログを確認します。

::

   sudo tail -f /var/log/masterha/masterha_manager.log

別端末で稼働系を開き、MySQL を kill します。

::

   sudo pkill mysql

フェイルオーバー後以下手順でサービスが引き継がれていることを確認します。

- MHAログからフェイルオーバーが処理されていること
- WebブラウザからVIPで Zabbix、Cacti のコンソールに接続できること
   - http://192.168.10.10/zabbix/
   - http://192.168.10.10/{サイトキー}/
- Getperf WebサービスのAxis2コンソールに接続できること
   - http://192.168.10.10:57000/axis2/
   - http://192.168.10.10:57000/axis2/
- 現稼働系(旧待機系)でZabbix サーバが起動されていること。以下のログから確認する
   - /var/log/zabbix/zabbix_server.log
- 現稼働系でMySQLが稼働されていること。以下のコマンドで確認する

   ::

      sudo masterha_check_ssh  --conf=/etc/mha.conf
      sudo masterha_check_repl --conf=/etc/mha.conf

フェイルオーバー後の切り戻し
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

フェイルオーバー発生後は、手動で旧稼働系を復帰させ、切り戻し作業を行います。
その手順を以下に記します。前提条件として、フェールオーバー後の旧稼働系は以下の状態となっていることとします。

- 旧稼働系でOSが起動ができる状態にする。
- 以下のサービスは停止した状態にする。
   - MySQL
   - Zabbix Server

**旧稼働系をスレーブとして復帰**

新稼働系でバイナリログチェックポイントを確認します。

::

   mysql -u root -p -e "show master status;"
   +-------------------+-----------+--------------+------------------+
   | File              | Position  | Binlog_Do_DB | Binlog_Ignore_DB |
   +-------------------+-----------+--------------+------------------+
   | mysqld-bin.000001 | 620812883 |              |                  |
   +-------------------+-----------+--------------+------------------+

旧稼働系をMySQLスレーブとして設定します。MySQLがダウンしている場合は起動します。

::

   sudo /etc/init.d/mysqld start

旧稼働系のMySQLに接続して、レプリケーション設定をします。

::

   mysql -u root -p

::

   SET GLOBAL read_only = 1;
   SET GLOBAL sql_slave_skip_counter = 1;
   change master to
       master_host='192.168.10.2',
       master_user='repl',
       master_password='repl',
       master_log_file='mysqld-bin.000001',
       master_log_pos=620812883;
   start slave;
   show slave status;
   exit;

旧待機系でMHAチェックコマンドを実行して、sshとレプリケーションの状態確認をします。

::

   sudo masterha_check_ssh --conf=/etc/mha.conf
   sudo masterha_check_repl --conf=/etc/mha.conf


**系の切り戻し**

旧待機系で切り戻しを実行します。
フェイルオーバー後に生成されるフラグファイルを削除します。

::

   sudo rm -f /tmp/mha/mha.failover.complete

手動切り戻しスクリプトを実行します。IPアドレスは旧稼働系のIPアドレスを指定します。

::

   sudo masterha_master_switch --master_state=alive \
   --conf=/etc/mha.conf \
   --new_master_host=192.168.10.1  --orig_master_is_new_slave

旧稼働系でデーモンを再起動します。

::

   sudo initctl start mha

元に戻っていることを確認します。

::

   sudo masterha_check_repl --conf=/etc/mha.conf

.. note:: スレーブで不整合エラーが出る場合の対処

   "show slave status;"で更新SQLのエラーが発生した場合は、以下のコマンドでエラーとなったSQLを順にスキップさせてください。

   ::

      mysql -u root -p
      STOP SLAVE; SET GLOBAL SQL_SLAVE_SKIP_COUNTER=1; START SLAVE;
      show slave status;
