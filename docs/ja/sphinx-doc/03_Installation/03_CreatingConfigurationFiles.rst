設定ファイルの作成
==================

設定ファイルの自動生成スクリプト cre_config.pl を実行します。

::

    cd $GETPERF_HOME
    perl script/cre_config.pl

$GETPERF_HOME/conf の下に設定ファイルを生成します。詳細は `設定ファイルの定義 <docs/ja/docs/11_Appendix/01_Configuration.md>`_ を参照してください。

1. getperf_site.json : Getperf のメイン設定ファイル
2. getperf_cacti.json : 監視ソフト Cacti の設定ファイル
3. getperf_rrd.json : 時系列データベース RRDtool の設定ファイル
4. getperf_zabbix.json : 監視ソフト Zabbix の設定ファイル
5. getperf_influx.json : 時系列データベース InfluxDB の設定ファイル

5　は問題分析用ツールでデフォルトは無効となっています。必要な場合は設定ファイルの値を有効にしてください。
有効にすると、既定の RRDtool に加え、 InfluxDB にもデータ蓄積を行います。

getperf_site.json
------------------

Getperf　のベース設定と、各種インストールソフトウェアのプロパティを設定します。

::

    vi config/getperf_site.json

Getperf　ホームディレクトリ、ログ出力設定をします。セキュリティの観点から、"GETPERF_CACTI_MYSQL_ROOT_PASSWD"　の　MySQL　のルートパスワードを変更してください。

::

    "GETPERF_CACTI_MYSQL_ROOT_PASSWD": "XXX",

getperf_cacti.json
-------------------

グラフモニタリングツール Cacti の配置、バージョンの設定をします。原則、Getperf　モジュールは Cacti　の最新バージョンとの組合せでモジュールを構成します。Cacti　はダウングレードの機能がないため、既定値より下位のバージョンを指定することはできません。既定値より下位バージョンのCactiが必要な場合は `古い Cacti バージョンのインストール <docs/ja/docs/10_Miscellaneous/08_CactiOldVersion.md>`_ を参照してください。

getperf_rrd.json
-----------------

時系列データベース RRDtool　のリ保存期間、集計期間の設定をします。
保存期間はデフォルトで以下となり、変更が必要な場合は編集してください。

-  直近の詳細が2分間隔のサンプリングで1日間保持
-  直近1週間が15分間隔のサンプリングで8日間保持
-  直近の1カ月が60分間隔のサンプリングで31日間保持
-  それ以上は1日のサンプリングで730日間保持

getperf_zabbix.json
--------------------

オープンソースの統合監視ソフト Zabbix　の設定をします。

::

    vi config/getperf_zabbix.json

本ソフトのインストールはオプションで、デフォルトは有効となります。無効にする場合は、"GETPERF_AGENT_USE_ZABBIX" を 0　にしてください。

::

    "GETPERF_AGENT_USE_ZABBIX": 1

また、有効にする場合はセキュリティの観点から、 Zabbix　Web コンソールの管理者ユーザ admin のパスワード　"ZABBIX_ADMIN_PASSWORD" を変更してください。

::

    "ZABBIX_ADMIN_PASSWORD":     "getperf",

既定値の場合は、admin/getperf でログインします。

getperf_influx.json
-------------------

時系列データベース InfluxDB　の設定をします。

::

    vi config/getperf_influx.json

本ソフトのインストールはオプションで、デフォルトは無効となります。有効にする場合は、"GETPERF_USE_INFLUXDB"　を 1　にしてください。InfluxDB は α リリースの状態となります。

::

	"GETPERF_USE_INFLUXDB": 1
