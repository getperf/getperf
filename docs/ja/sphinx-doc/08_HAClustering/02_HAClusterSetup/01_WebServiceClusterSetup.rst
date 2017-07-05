Cacti受信ノードのHA化
---------------------

構成概要
^^^^^^^^

HA化ポリシー
~~~~~~~~~~~~

Cacti 受信ノードをHA化します。
マスター／スレーブの 2台構成で、VIP をサービス用IPとし、
稼働系ノードに VIP を付加することにより、
ホットスタンバイ型のHA構成を組みます。

* 新たにスレーブノードを追加し、マスター／スレーブ構成にします。
* keepalived をもちいて Apache 受信用の VIP を冗長化します。
* 既設のCacitサーバの IP を VIP に変更します。

冗長化する機能
~~~~~~~~~~~~~~

以下の機能を二重化します。

* Apache/Tomcat でエージェントから性能データzipを受信するWebサービス機能
* RSyncで受信データをCacitサービスノードに転送する機能

事前準備
^^^^^^^^

スレーブノードの基本モジュールセットアップ
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

スレーブノードをセットアップします。
:doc:`../../03_Installation/index` の手順に従い、「Webサービスインストール」までを行います。
次項の RSync の動作確認用に、スレーブノードにエージェントをインストールし、
設定したWebサービスで zip 受信ができるようにしてください。

マスターノード、スレーブノードでRSync送信ができるようにする
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

:doc:`../../09_ChangeManagement/03_PotingOldVersion` の手順に従い、
マスターノード、スレーブノードの各ノードで、
RSync で受信データをサービスノードに送信できるようにします。

RSync　をインストールします。

::

   sudo -E yum -y install rsync xinetd

Web サービスの保存先の以下のパスを指定して、 RSync の受信設定をします。

::

   ${GETPERF_HOME}/t/staging_data/{サイトID}

例えば、サイトIDが site1 の場合の保存先は、
/home/psadmin/getperf/t/staging_data/site1 となり、
本パスを指定して /etc/rsyncd.conf を編集します。

::

   sudo vi /etc/rsyncd.conf

以下の行を追加します。

::

   [archive_site1]
   path =  /home/psadmin/getperf/t/staging_data/site1
   hosts allow = *
   hosts deny = *
   list = true
   uid = psadmin
   gid = psadmin
   read only = false
   dont compress = *.gz *.tgz *.zip *.pdf *.sit *.sitx *.lzh *.bz2 *.jpg *.gif *.png

1行目はRSync 受信を一意にする IDで、「archive_{サイトID}」とします。
2行目がWebサービスの保存先パスを指定します。

RSync を起動して動作確認をします。

::

   sudo /etc/rc.d/init.d/xinetd restart

サービスノードから rsync コマンドを用いて、 RSync 疎通を確認します。

::

   mkdir /tmp/rsync_test
   rsync -av --delete rsync://192.168.10.41/archive_site1 /tmp/rsync_test

RSync の疎通確認ができたら、RSync サイト同期を確認します。
本処理は RSync からZib ファイルを受信して、データの解凍、集計、RRDtoolグラフデータ
登録までを行います。

::

   cd {サイトディレクトリ}
   ${GETPERF_HOME}/script/sitesync -t 1 \
   rsync://{旧監視サーバアドレス}/archive_{サイトキー}

.. note:: 実行オプション -t は実行回数の指定で、同期を1回行います。

~/work/site1 の下のサイトを同期する場合は以下のコマンドを実行します。

::

   cd /home/psadmin/work/site1
   ${GETPERF_HOME}/script/sitesync -t 1 \
   rsync://192.168.10.41/archive_site1

スレーブノードの Apache をVIPでサービス受信できるようにする
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

スレーブノードの Apacheの受信IPをVIPに設定変更します。

.. note::

   本設定後、スレーブノードの WEB サービスは VIP からの受信のみの受付する動作となり、
   既設 IP での受信を行いません。
   前述のRSync動作確認で、既設IP 宛のエージェントを起動している場合、
   getperfctl stop コマンドでエージェントを停止してください。

Getperf 設定ファイル getperf_site.json の IP 設定を編集します。

::

   cd ~/getperf
   vi config/getperf_site.json

以下の行のIPアドレスの箇所を VIP に変更してください。

::

   "GETPERF_SSL_COMMON_NAME_INTER_CA": "getperf_inter_192.168.10.41",
   "GETPERF_WS_SERVER_NAME": "192.168.10.41",
   "GETPERF_WS_ADMIN_SERVER":   "192.168.10.41",
   "GETPERF_WS_DATA_SERVER":    "192.168.10.41",

Web サービスの中間認証局とサーバの証明書を更新します。

::

   rex create_inter_ca  # 中間認証局の証明書更新
   rex server_cert      # サーバーの証明書更新

証明書のCN(Common Name)が変更されていることを確認します。

::

   grep CN /etc/getperf/ssl/*/*.crt
   /etc/getperf/ssl/inter/ca.crt:        Issuer: CN=getperf_ca_192.168.10.1
   /etc/getperf/ssl/inter/ca.crt:        Subject: CN=getperf_inter_192.168.10.41
   /etc/getperf/ssl/server/server.crt:        Issuer: CN=getperf_inter_192.168.10.41
   /etc/getperf/ssl/server/server.crt:        Subject: CN=192.168.10.41

Webサービス再起動をします。

::

   rex restart_ws_data
   rex restart_ws_admin

Webブラウザから以下URLにアクセスし、Webサービス起動を確認します。

::

   http://{サーバIP}:57000/axis2
   http://{サーバIP}:58000/axis2


マスターノードの物理IPとVIPのネットワーク切替
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

マスターノードの既設IPをVIPに変更し、新たに物理IPを追加します。
ネットワークスクリプトを編集して、ネットワークの再起動で設定を反映します。
以下設定を想定した手順を記します。

* NIC デバイス名は eth0 とします
* 既設IP、VIP の変更アドレスは 192.168.10.41 とします
* 新IP として追加するアドレスは 192.168.10.42 とします

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

      IPADDR=192.168.10.42

* ifcfg-eth0:1

   新たに eth0:1 を追加して、VIP を追加します。
   ifcfg-eth0 ファイルをコピーして以下の編集をします。

   ::

      sudo cp ifcfg-eth0 ifcfg-eth0.bak
      sudo vi ifcfg-eth0

   以下の、DEVICE と IPADDR の箇所を VIP に変更します。

   ::

      DEVICE="eth0:1"
      IPADDR=192.168.10.41

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
       inet 192.168.10.42/24 brd 192.168.10.255 scope global eth0
       inet 192.168.10.41/24 scope global secondary eth0
       inet6 fe80::20c:29ff:fe06:ac37/64 scope link
          valid_lft forever preferred_lft forever

keepalivedによる VIP 切替設定
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Cacti 受信ノードの VIP をマスターノード、スレーブノード間で冗長化します。

* keepalived を用いて、VIP の冗長化設定をします
* 各ノードのWebサービスのレスポンスコード(200 OK)で死活監視をします。
* 監視スクリプトとして、$GETPERF_HOME/script/check_getperf_ws.sh を使用します。

Web サービス死活監視スクリプトの動作確認をします。
マスタノード、スレーブノードともに終了コードが 0 であることを確認します。

::

   cd ~/getperf/script
   sh -x sh -x check_getperf_ws.sh
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
      router_id LVS_GETPERF_WS
   }

   vrrp_script check_getperf_ws {
     script       "/home/psadmin/getperf/script/check_getperf_ws.sh"
     interval 2   # check every 2 seconds
     fall 3       # require 3 failures for KO
     rise 2       # require 2 successes for OK
   }

   vrrp_instance VirtualInstance1 {
       state BACKUP        # マスターノードは MASTER に変更
       interface eth0      # VIPを追加する NIC名
       virtual_router_id 1 # 一意にするID
       priority 100
       advert_int 5
       nopreempt
       authentication {
           auth_type PASS
           auth_pass passwd
       }
       virtual_ipaddress {
           192.168.10.41/24 # VIPアドレス
       }
       track_script {
         check_getperf_ws
       }
   }

keepalived を起動します。

::

   sudo service keepalived start

システムログから keepalived 起動を確認します。

::

   sudo tail -f /var/log/messages
   Jul  5 07:40:06 rama1 Keepalived_vrrp[15465]: VRRP_Instance(VirtualInstance1) Sending gratuitous ARPs on eth0 for 192.168.10.41

keepalived 自動起動設定をします。

::

   sudo chkconfig keepalived on

