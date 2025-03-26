設定ファイルの作成
==================

設定ファイルの自動生成スクリプト cre_config.pl を実行します。

::

    cd $GETPERF_HOME
    perl script/cre_config.pl

$GETPERF_HOME/conf の下に設定ファイルを生成します。詳細は
:doc:`../../11_Appendix/01_Configuration`
を参照してください。

1. getperf_site.json : Getperf のメイン設定ファイル
2. getperf_rrd.json : 時系列データベース RRDtool の設定ファイル
3. getperf_zabbix.json : 監視ソフト Zabbix の設定ファイル

getperf_site.json
------------------

Getperf のベース設定と、各種インストールソフトウェアのプロパティを設定します。

::

    cd $GETPERF_HOME/config
    vi getperf_site.json

Getperf ホームディレクトリ、ログ出力設定をします。
"GETPERF_CACTI_MYSQL_ROOT_PASSWD" の MySQL のルートパスワードを設定してください。

::

    "GETPERF_CACTI_MYSQL_ROOT_PASSWD": "XXX",

監視対象が 100 台以上の環境の場合は、以下値の調整をしてください。
Web サービスの最大接続数の上限値で Tomcat スレッド数上限の 256 の範囲で
利用環境に合わせて修正してください。

::

    "GETPERF_WS_MAX_SERVERS": 130,

getperf_rrd.json
-----------------

時系列データベース RRDtool のリ保存期間、集計期間の設定をします。

::

    cd $GETPERF_HOME/config
    vi getperf_rrd.json

保存期間はデフォルトで以下となり、変更が必要な場合は編集してください。

-  直近の詳細が2分間隔のサンプリングで1日間保持
-  直近1週間が15分間隔のサンプリングで8日間保持
-  直近の1カ月が60分間隔のサンプリングで31日間保持
-  それ以上は1日のサンプリングで730日間保持

getperf_zabbix.json
--------------------

オープンソースの統合監視ソフト Zabbix の設定をします。

::

    cd $GETPERF_HOME/config
    vi getperf_zabbix.json

Zabbix サーバの接続情報を設定します

::

        "ZABBIX_SERVER_IP": "{ZabbixサーバIP}",
        "ZABBIX_ADMIN_PASSWORD": "{Zabbix Admin パスワード}",

.. note::

    Zabbix 登録スクリプト zabbix-cli は、上記接続情報で Zabbix に接続します。
    この後のCacti監視サイト構築後、サイトディレクトリに移動してから以下のコマンドで
    Zabbixとの接続を確認してください。
    監視対象のノード定義ディレクトリを指定して、Zabbix に接続し、
    ホスト登録情報を出力するコマンドになります。

    ::

        cd {サイトディレクトリ}
        zabbix-cli --info ./node/Linux/{ホスト名}/

    後述の確認用サイトでの確認手順は以下となります。

    ::

        cd ~/site/site1/
        zabbix-cli --info ./node/Linux/{自サーバホスト名}/

以下はオプションで、デフォルトは有効となります。以下パラメータを 0 にしてください。


オプションの zabbix_sender を有効にする場合のみ 1 を設定

::

      "GETPERF_USE_ZABBIX_SEND": 0,

旧 Cacti エージェントでエージェントモジュールに Zabbix エージェントを追加する場合のみ 1 を設定

::

      "GETPERF_AGENT_USE_ZABBIX": 0

その他の設定
------------

getperf_cacti.json(Cacti設定)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

生成された既定の getperf_cacti.json は、 Cacti-1.2.24 の設定となっています。
Cacti 0.8.8g を使用する場合は、以下の設定ファイルをコピーします。

::

   cd $GETPERF_HOME/config
   ls
   # 上記で確認した、getperf_cacti.json_0.8.8 のファイルを getperf_cacti.jsonにコピー
   cp getperf_cacti.json_0.8.8 getperf_cacti.json

グラフモニタリングツール Cacti の配置、バージョンの設定をします。
Getperf モジュールは Cacti の最新バージョンとの組合せでモジュールを構成します。
Cacti はダウングレードの機能がないため、既定値より下位のバージョンを指定することはできません。
既定値より下位バージョンのCactiが必要な場合は 
:doc:`../03_Installation.v2/23_DowngradeCacti12to08` を参照してください。


