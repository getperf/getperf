監視サーバのバージョンアップ
============================

全体の流れ
----------

1. getperf.tar.gz のダウンロード、解凍
2. config/getperf.json の更新
3. tomcat モジュールの更新
4. PHP モジュールの更新
5. Perl モジュールの更新
6. サービス再起動
7. 動作確認

構成ファイルバックアップ
------------------------

各監視サーバにpsadminユーザでssh接続。
$HOME/getperf/conf の下の構成ファイルを一旦バックアップします。

::

   cd ~/getperf
   tar cvf - conf | gzip > ~/work/conf_backup.tar.gz

GitHubサイトから getperf-master.zip ファイルをダウンロードします。
Getperf モジュールホームの $HOME/getperf に zip を展開して上書更新します。

::

   (事前に $HOME 下に getperf-master.zip　をダウンロード)
   cd ~
   unzip getperf-master.zip
   cd getperf-master
   cp -r * ../getperf

.. note::

   git clone コマンドでクローンを作成している場合は、git pullで最新モジュールをチェックアウトしてください。

   ::

      cd ~/getperf
      git pull

config/getperf.json の更新
--------------------------

.. note:: Changes.txt に getperf.json の更新指示の記載がない場合は以下手順は不要です。

configファイル作成スクリプトにて全ファイルをまとめて上書きします。

::

   cre_config.pl

変更箇所は基に戻す必要があるので事前に確認します。変更箇所は以下の通りです。

* zabbix IPアドレス

::

   cd ~/getperf/config
   vi getperf_zabbix.json

Zabbix が別サーバの場合は、ZABBIX_SERVER_IP を設定します。

::

   "ZABBIX_SERVER_IP":          "10.37.64.213",

Tomcat モジュールの更新
-----------------------

.. note:: Changes.txt に Webサービスに関する変更がない場合は以下手順は不要です。

RexコマンドでTomcat本体、Webコンテナライブラリ、Webサービスの順にアップデートします。

::

   sudo -E rex prepare_tomcat
   sudo -E rex prepare_tomcat_lib
   sudo -E rex prepare_ws

更新が終わったらサービスを再起動。

::

   sudo rex restart_ws_admin
   sudo rex restart_ws_data

**注意** :  restart_ws_data(データ送受信用Webサービス) で再起動に失敗する場合があります。
その場合は以下の手順で手動再起動してください。

::

   sudo /etc/init.d/tomcat-data stop
   (10秒ほど暫くしてから)
   sudo /etc/init.d/tomcat-data start
   sudo /etc/init.d/apache2-data stop
   sudo /etc/init.d/apache2-data start

Webブラウザから以下の管理用Webページが表示されることを確認。

::

   http://{サーバIPアドレス}:57000/axis2/     # 管理用
   http://{サーバIPアドレス}:58000/axis2/     # データ総樹脂9ン用

200番のHTTPコードが返ってくればOK

PHP, Perl モジュールの更新
--------------------------

**PHPモジュール**

::

   cd ~/getperf
   sudo -E rex prepare_composer

確認は  cacti-cli -h として、ヘルプが出れば OK

**Perl モジュール**

::

   sudo -E cpanm --installdeps .

集計サービス再起動
------------------

以下で各サイトの集計サービスを再起動します。

::

   sudo -E /etc/init.d/sumupctl restart

.. note:: サイト毎に再起動する場合は以下の手順となります。

   上記サーバ構成で記した、サイトホームディレクトリに移動します。

   ::

      cd {サイトホーム}

   sumup コマンドで再起動

   ::

      sumup stop
      sumup start

   メッセージにエラーが出なければOK。

動作確認
---------

暫くしてから、Cactiサイトで最新データのグラフが表示されていることを確認します。

