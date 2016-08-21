Graphiteインストール(オプション)
================================

getperf_graphite.json 設定ファイルの編集
-----------------------------------------

オープンソースの時系列データベース Graphite　のインストールをします。本ソフトウェアはオプションとなりデフォルトは無効となっています。
はじめに、getperf_graphite.json　設定ファイルを編集して有効化します。

::

    cd $GETPERF_HOME
    vi config/getperf_graphite.json

Graphite　のインストール機能はまだαリリースとなり、仕様が変更される可能性が有ります。特に指定の希望がなければ、以下の項目のみ値の編集をします。

-  GRAPHITE_DB_PASS

   MySQL 管理のイベント用データベースのパスワード。セキュリティの観点から既定値を変更してください。

-  GETPERF\_USE\_GRAPHITE

   1 に変更して Graphite を有効化します。

Graphite インストール
---------------------

Graphite サーバ一式のインストールします。EPEL リポジトリからインストールをします。

::

    sudo -E rex prepare_graphite

Graphite のデータ登録用デーモンプロセス carbon-cache を起動します。

::

    sudo service carbon-cache restart
    sudo chkconfig carbon-cache on

Graphite 設定
-----------------

必要に応じて蓄積データのリテンションの設定を行います。

::

    sudo vi /etc/carbon/storage-schemas.conf 

以下の例は 5秒のインターバルを8日間、 5分を 90日間、 60分を 5年分保持する設定となります。

::

    [default_1min_for_1day]
    pattern = .*
    retentions = 5s:8d,5m:90d,60m:5y

設定を反映させるため、 carbon-cache を再起動します。

::

    sudo service carbon-cache restart

Graphite の動作確認
-------------------

以下の確認でインストール後の動作確認をします。

-  'ps -ef \ grep carbon' でデーモンプロセスが起動していることを確認します。
-  'sudo tail -f /var/log/carbon/console.log' でログを確認します。
-  Web ブラウザから 'http://{サーバアドレス}:8081/' を開いて管理コンソール画面を確認します。

以上で、Graphite のインストールは完了です。
