削除する

InfluxDBインストール(オプション)
================================

getperf_influx.json 設定ファイルの編集
-----------------------------------------

オープンソースの時系列データベース InfluxDB　のインストールをします。本ソフトウェアはオプションとなりデフォルトは無効となっています。
はじめに、getperf_graphite.json　設定ファイルを編集して有効化します。

::

    cd $GETPERF_HOME
    vi config/getperf_influx.json

InfluxDB　のインストール機能はまだαリリースとなり、仕様が変更される可能性が有ります。特に指定の希望がなければ、以下の項目のみ値の編集をします。

-  GETPERF\_USE\_INFLUXDB

   1 に変更して InfluxDB を有効化します。

InfluxDB インストール
---------------------

InfluxDB サーバ一式のインストールします。InfluxDB 開発サイトのリポジトリからインストールをします。

::

    sudo -E rex prepare_influxdb

インストールスクリプトが InfluxDB のデータ登録用デーモンプロセス influxd を起動します。

.. note::

  - yum コマンド実行時のエラー

    社内イントラ環境でプロキシー経由で yum コマンドを実行する場合、
    実行時にSSL の認証エラーが発生する場合があります。
    その場合は、yum コマンドを使用せずに、`InfluxDB ダウンロードサイト <https://influxdata.com/downloads/#influxdb>`_ から RPM をダウンロードしてインストールしてください。

    ::

		wget https://dl.influxdata.com/influxdb/releases/influxdb-0.13.0.x86_64.rpm
		sudo yum localinstall influxdb-0.13.0.x86_64.rpm

InfluxDB の動作確認
-------------------

以下の確認でインストール後の動作確認をします。

-  'ps -ef \ grep influxd' でデーモンプロセスが起動していることを確認します。
-  'sudo tail -f /var/log/influxdb/influxd.log' でログを確認します。
-  Web ブラウザから 'http://{サーバアドレス}:8083/' を開いて管理コンソール画面を確認します。

以上で、InfluxDB のインストールは完了です。
