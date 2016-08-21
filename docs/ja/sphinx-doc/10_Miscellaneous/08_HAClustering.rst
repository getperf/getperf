監視サーバのHA化
=============================

以下の要件を満たすように、監視サーバのHA化をします。

- 夜間、休日中のHW障害を対処するため、HA構成を組み、フェイルオーバーを自動化する。
- 障害発生時は監視機能の復旧を優先する。
- 障害発生中データロスの発生は許容するが、最小限にとどめるようにする。
- データの保護はディスクのミラーリングやバックアップなど別の仕組みで実現する。
- 既存の監視サーバ構成をベースにし、新たに待機系ノードの追加によりHA構成を組めるようにする。

システム構成
-----------------------------

監視サーバのHA構成を下図に記します。

.. figure:: ../image/ha_clustering_base.png
   :align: center
   :alt: HA Clustering

- 1対1の稼働・待機の構成となり、監視対象との接続はVIP(仮想IP)の切り替えで制御します。
- クラスタリングソフト `MHA <https://code.google.com/p/mysql-master-ha/>`_ を使用し、稼働系のフェイルオーバー操作を自動化します。
- MHAは MySQL のクラスタリングソフトとなりますが、拡張スクリプトの拡張により、Zabbix,Cacti インスタンスを合せて系切替を制御します。

用途を Zabbix、Cacti　の2つに分け、稼働系2ノード、待機系2ノードの4ノード構成でも実装可能です。
目安として2ノード構成の場合は、100台までの監視対象をサポートし、4ノード構成の場合は、500台までの監視対象をサポートします。

.. note::

	- 稼働系の障害が発生時のフェイルオーバー処理の自動化のみをサポートします。
	- 待機系の障害発生時、フェイルオーバー実行後の切り戻し作業は手動で行う必要があります。
	- HA化により追加された構成要素に対しての監視仕様を定義し、別途、監視が必要になります。詳細はHA環境の監視設定を参照してください。

構成要素
-----------------------------

HA構成の構成要素は下図になります。

.. figure:: ../image/2node_ha_clustering.png
   :align: center
   :alt: 2 node HA Clustering

- Zabbix Server

	ZabbixはSNMP統計の情報採取など能動的な動作をするため、クラスター内で排他的に動作する様、制御が必要になります。
	待機系のZabbixはコールドスタンバイ構成として、インスタンスは停止させておきます。
	フェイルオーバー実行時に旧稼働系を停止し、待機系を起動します。

- MySQL

	MySQLレプリケーションを用いて、マスター、スレーブ構成のDBレプリケーション構成を組み、データを二重化します。
	稼働系のフェイルオーバー時はスレーブをマスターに昇格します。
	フェイルオーバー後の復旧は切り戻し作業が必要となり、手動でDBレプリケーション構成を再構成する必要があります。
	詳細は切り戻し手順を参照して下さい。

- Apache(PHP)

	Apache は受動的な動作となるため、ホットスタンバイ構成としてインスタンスは両ノードで起動させておき、VIP の付け替えでサービスを切り替えます。
	クライアントは VIP を宛先として接続します。

- Getperf Webサービス

	Apache と同様に、受動的な動作となるため、待機系の Web Service はホットスタンバイ構成にします。

- RRDtool

	時系列データベース RRDtool はクラスタリング機能をサポートしておらず、各ノードのローカルディスクにデータを蓄積します。
	本制約のため、稼働系を特定ノードに固定し、フェイルオーバー後は切り戻しをする運用とします。
	障害発生期間中は、データの欠落が発生します。

- MHA

	待機系ノードに MHA モニタリングサービスを起動し、各ノードの監視をします。
	MHA は稼働ノードの障害(Ping応答とMySQL接続応答なし)を検知した場合、自動でフェイルオーバーを実行し、VIPの付け替え、MySQLスレーブからマスターへの昇格、各構成要素のインスタンスの起動／停止を行います。
	フェイルオーバー実行後、MHA モニタリングサービスは終了します。監視の再開には、切り戻し作業を実行後、MHA モニタリングサービスの再起動を行う必要が有ります。

その他構成要素として、監視サーバ内でGetperfエージェントにてリモート採取の設定をした場合、Zabbixと同様に排他制御が必要になります。
エージェントの設定ファイルで稼働ノードのチェックを追加し、稼働系のみで情報採取を実行するように制御します。

各要素のHA動作をまとめると下表となります。

.. list-table::
   :widths: 25 30 45
   :header-rows: 1

   * - 構成要素
     - HA構成時の動作
     - フェイルオーバー時処理
   * - Zabbix Server
     - 稼働系のみ起動
     - MHAでインスタンスの起動/停止を制御
   * - MySQL
     - DBレプリケーションでデータを二重化
     - MHAでスレーブの昇格
   * - Apache(PHP)
     - 両系で起動
     - VIPの付け替え
   * - Getperf Webサービス
     - 両系で起動
     - VIPの付け替え
   * - RRDtool
     - 何もしない
     - 何もしないため、データロス発生

HA導入手順
-----------------------------

`MHA <https://code.google.com/p/mysql-master-ha/>`_ を用いたHAクラスター導入手順を記します。
ここでは、2ノード構成でのHAクラスター導入手順を記します。本手順は以下のサーバ構成情報を基にしています。
IPアドレスは適宜環境に合わせて変更してください。

.. list-table:: 
   :widths: 33 33 33
   :header-rows: 1

   * - 項目
     - 稼働系
     - 待機系
   * - 仮想IP(VIP)
     - 192.168.10.10(eth0:1)
     - 同左
   * - 物理IP
     - 192.168.10.1(eth0)
     - 192.168.10.2(eth0)
   * - HAソフト構成
     - MHA node
     - MHA node+manager
   * - MySQL構成
     - MySQL マスター
     - MySQL スレーブ
   * - HAサービス定義
     - Zabbix, Apache, Getperf
     - 同左


root の ssh 公開鍵の配布(稼働系、待機系の順に実施)
^^^^^^^^^^^^^^^^^^^^^^^^^^^

MHA のリモート操作用にノード間で root の ssh 接続許可設定をします。
稼働系、待機系の順で各ノードに ssh 公開鍵の配布をします。

::

	sudo ssh-keygen -t rsa -f /root/.ssh/id_rsa -q -N ""
	sudo ssh-copy-id -i /root/.ssh/id_rsa.pub root@192.168.10.1
	sudo ssh-copy-id -i /root/.ssh/id_rsa.pub root@192.168.10.2

MySQL 監視用のユーザ作成(稼働系、待機系の順に実施)
^^^^^^^^^^^^^^^^^^^^^^^^^^^

MySQL Ping監視用ユーザを作成します。稼働系、待機系の順で実行します。

::

	mysql -u root -p

MySQL コンソールから以下を実行します。

::

	grant all privileges on *.* to mha@'%' identified by 'mhapassword';

同様にMySQLコンソールから、レプリケーションユーザを作成します。

::

	grant replication slave on *.* to repl@'%' identified by 'replpassword';
	flush privileges;
	exit

MySQL 設定ファイル編集(稼働系、待機系の順に実施)
^^^^^^^^^^^^^^^^^^^^^^^^^^^

MySQL 設定ファイルにレプリケーション設定を追加します。稼働系、待機系の順で実行します。

::

	sudo vi /etc/my.cnf

先頭行の[mysqld]の後ろに以下を追加します。server-id は、稼働系を 101、待機系を 102　にしてください。

::

	[mysqld]
	#バイナリログの出力
	log-bin=mysqld-bin
	#server-idは一意になるように設定する
	# 101:稼働系, 102:待機系
	server-id=101
	# バイナリログ保存期間
	expire_logs_days = 7

設定を反映するため、 mysqld を再起動します。

::

	sudo /etc/init.d/mysqld restart

MySQLレプリケーション設定(稼働系で実施)
^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. note::

	既に稼働中の監視サーバでレプリケーションを構成する場合、MySQLの蓄積データが大きいと、
	バックアップ処理で長時間待たされる場合が有ります。
	MySQL 標準のバックアップコマンド mysqldump は実行中にDB全体にロックを掛ける為、その間の監視運用に影響が生じる場合が有ります。
	本制約の回避が必要な場合は、Percona社 XtraBackup などのオンラインバックアップツールを使用して下さい。

稼働系、待機系でMySQLのデータ同期を、レプケーション設定をします。
初めに MySQL データのロックとバイナリログ情報の確認をします。

::

	mysql -u root -p

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

	mysqldump -u root -p --all-databases --lock-all-tables --events > mysql_dump.sql

元の端末に戻って、ロックを解除します。

::

	unlock tables;
	exit;

ダンプファイルを稼働系から待機系にコピーします。

::

	scp mysql_dump.sql 192.168.10.2:/tmp/

MySQLレプリケーション設定(待機系で実施)
^^^^^^^^^^^^^^^^^^^^^^^^^^^

待機系で、MySQLレプリケーションのスレーブ設定をします。

稼働系から転送したダンプデータをインポートします。

::

	mysql -u root -p < /tmp/mysql_dump.sql

MySQLコンソールに接続し、MySQL レプリケーションのスレーブ設定をします。

::

	mysql -u root -p

稼働系で確認した、バイナリログの File, Position を指定して change master to コマンドを実行します。

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
となり、Last_Error　にエラーメッセージが出力がされていない事を確認します。

MySQLレプリケーション　動作確認
^^^^^^^^^^^^^^^^^^^^^^^^^^^

単純なDB更新作業で、レプリケーションの動作を確認します。
上記で特にエラーなど問題が発生していない場合は、省略しても構いません。

稼働系でテスト用のデータベースを作成します。

::

	mysql -u root -p -e 'create database test_db;'
	mysql -u root -p -e 'show databases;'

待機系でデータベースが作成されていることを確認します。

::

	mysql -u root -p -e 'show databases;'

確認できたら、稼働系で作成したテスト用データベースを削除します。

::

	mysql -u root -p -e 'drop database test_db;'

MHAインストール(稼働系、待機系の順に実施)
^^^^^^^^^^^^^^^^^^^^^^^^^^^

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


MHA拡張スクリプト配布(待機系で実施)
^^^^^^^^^^^^^^^^^^^^^^^^^^^

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

	sudo -E cp $GETPERF_HOME/script/template/mha/master_ip_failover /usr/bin/
	sudo -E chmod 755 /usr/bin/master_ip_failover
	sudo -E cp $GETPERF_HOME/script/template/mha/master_ip_online_change /usr/bin/
	sudo -E chmod 755 /usr/bin/master_ip_online_change

MHA設定ファイルの編集(待機系で実施)
^^^^^^^^^^^^^^^^^^^^^^^^^^^

待機系で MHA 設定ファイル /etc/mha.conf を作成します。
$GETPERF_HOME/script/template/mha/ の下の、サンプル mha.conf.sample を参考に設定ファイルを編集してください。

::

	sudo cp $GETPERF_HOME/script/template/mha/mha.conf.sample /etc/mha.conf
	sudo vi /etc/mha.conf

IPアドレスとネットワークデバイスの箇所を環境に合わせて変更します。
編集後、以下のコマンドで動作確認をします。

::

	sudo masterha_check_ssh --conf=/etc/mha.conf 	# 各ノードへの ssh 疎通確認
	sudo masterha_check_repl --conf=/etc/mha.conf 	# 各ノードへの MySQL 疎通確認

MHAデーモンの常駐化(待機系で実施)
^^^^^^^^^^^^^^^^^^^^^^^^^^^

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

停止するときは、以下のコマンドを実行します。

::

	sudo initctl stop mha

フェイルオーバーテスト
^^^^^^^^^^^^^^^^^^^^^^^^^^^

ここでは、簡単に稼働系でMySQLをkillしてフェイルオーバー動作を確認します。

待機系でMHAログを確認します。

::

	sudo tail -f /var/log/masterha/masterha_manager.log

別端末で稼働系を開き、MySQL をkill します。

::

	sudo pkill mysql

ログからフェイルオーバーが処理されていることを確認します。以下確認コマンドで状態を確認します。

::

	sudo masterha_check_ssh --conf=/etc/mha.conf
	sudo masterha_check_repl --conf=/etc/mha.conf

フェイルオーバー後の切り戻し手順
-----------------------------

フェイルオーバー発生後は、手動で旧稼働系を復帰させ、切り戻し作業を行い、監視を再開します。
その手順を以下に記します。前提条件として、旧稼働系は以下の状態にします。

- 旧稼働系でOSが起動ができる状態にする。
- 以下のサービスは停止した状態にする。
	- MySQL
	- Zabbix Server

旧稼働系をスレーブとして復帰
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

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
	exit;

旧待機系で動作確認をします。

::

	sudo masterha_check_ssh --conf=/etc/mha.conf
	sudo masterha_check_repl --conf=/etc/mha.conf

.. note::

	スレーブで不整合エラーが出る場合の対処

	::

		mysql -u root -p
		STOP SLAVE; SET GLOBAL SQL_SLAVE_SKIP_COUNTER=1; START SLAVE;
		show slave status;

系の切り戻し(旧待機系で実施)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

旧待機系で切り戻しを実行します。
フェイルオーバー後に生成されるフラグファイルを削除します。

::

	sudo rm -f /tmp/mha/mha.failover.complete

手動切り戻しスクリプトを実行します。IPアドレスは旧稼働系のIPアドレスを指定します。

::

	sudo masterha_master_switch --master_state=alive \
	--conf=/etc/mha.conf \
	--new_master_host=192.168.10.1  --orig_master_is_new_slave

再度確認して、基に戻っていることを確認します。

::

	sudo masterha_check_repl --conf=/etc/mha.conf

旧稼働系でデーモンを再起動します。

::

	sudo initctl start mha

HA構成の監視設定
-------------------------

MHAの監視は稼働系ノードのMySQLなど一部に限られるため、外部の監視サーバから各ノードを包括的に監視する必要があります。
主な監視指標は以下の通りです。

VIPポート監視をします。

* VIPポートの監視
	* Apache(80)
	* Getperf Webサービス(57000,58000)
	* Zabbix(10050)

Zabbix エージェントを使用して各ノードで以下の監視をします。

* 稼働系
	* Linux標準テンプレート
	* プロセスの死活監視(MySQL)
* 待機系
	* Linux標準テンプレート
	* プロセスの死活監視(MHA, MySQL)
	* ログ監視(MHA)
		* /var/log/masterha/masterha_manager.log

