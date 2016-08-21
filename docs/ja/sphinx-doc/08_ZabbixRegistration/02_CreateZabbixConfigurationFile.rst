Zabbix定義ファイル作成
======================

はじめに、以下のドメイン定義ファイル、アイテム定義ファイル、.hostsファイルを作成します。ここでは、既存の Oracle 監視テンプレートの Zabbix 定義ファイルを用いて各ファイルの説明をします。

.. note::

   以下説明で使用するファイルの確認をする場合は事前にサイトを初期化して、Oracleテンプレートをインポートする必要が有ります。Oracle テンプレートは ... からダウンロードしてください。テンプレートのインポート手順は、:doc:`../05_AdminCommand/02_SiteDataAggregation` を参照してください。

マクロ定義
----------

各定義ファイルは以下のマクロがあります。zabbix-cli コマンド実行時に値を置換します。

* <node>　: ノード名に置換します。ドメイン定義ファイルで使用します。
* <device> : アイテム名に置換します。アイテムはリスト形式となり、本マクロは配列の場合に使用します。アイテム定義ファイルで使用します。
* <device.key>,<device.value> : 同様にアイテム定義ファイル用でハッシュ形式のリストの場合に使用します。<device.key>がハッシュキー、<device.value>がハッシュ値でリストを置換します。

ドメイン定義ファイルの作成
--------------------

Zabbix のホスト登録定義となり、以下は Oracle ドメインのホスト定義例となります。

::

   cat lib/zabbix/Oracle.json
   {
           "is_physical_device" : 0,
           "host_groups" : [ "Oracle" ],
           "host_name" : "<node>",
           "host_visible_name" : "Oracle - <node>",
           "templates" : [ "Template Oracle" ]
   }

* is_physical_device <必須>

	対象ノードが物理デバイスでZabbixエージェント監視の場合は 1 とし、Zabbix　エージェントレス監視の場合は 0 とします。

* host_groups <必須>

   Zabbix ホストが属する Zabbix ホストグループ名リスト。

* host_name <必須>

   Zabbix ホスト名。通常は、"<node>"とする。

* host_visible_name <オプション>

   Zabbix ホストの表示名。

* templates <オプション>

   Zabbix ホストが属する Zabbix テンプレート名リスト。

アイテム定義ファイルの作成
--------------------

Zabbix のアイテム登録定義となり、以下は Oracle 表領域監視アイテムの定義例となります。

::

   cat lib/zabbix/Oracle/ora_tbs.json
   [
      {
         "item_name": "adm.oracle.tbs.usage.<device>",
         "type": "Zabbix trapper",
         "key": "adm.oracle.tbs.usage.<device>",
         "value_type": "numeric float",
         "delay": 3600
      }
   ]

* item_name <必須>

   アイテム名。一意性が必要なため、アイテムが複数の場合は<device>マクロを追加します。

* type <必須>

   アイテムタイプ名。Zabbixエージェント監視の場合は "Zabbix agent" とし、Zabbix　エージェントレス監視の場合は "Zabbix trapper" とします。

* key <必須>

   キー名。item_nameと同様に、一意性が必要なため、<device>マクロを追加します。

* value_type <必須>

   値のフォーマット名。
   'numeric float', 'character', 'log', 'numeric unsigned', 'text' から選択します。

* delay <必須>

   採取インターバル(秒)。

.hosts ファイルの作成
---------------------

zabbix-cli は監視対象のIPアドレスをZabbixに登録します。DNSなどで監視対象の名前からIPアドレスを引き当てられない場合は、
.hosts ファイルに、IPアドレスの登録が必要となります。"IP 監視対象ノード名"の順で登録してください。

::

    cat .hosts
    XXX.XXX.XX.XX   {監視対象}

.. note::

   Zabbix エージェントレス監視の場合、本設定は不要です。

.. note::

   .hosts に記述する監視対象名はノード定義パスの監視対象ディレクトリ名と同じにしてください。ノード定義パスの監視対象ディレクトリ名は実際のホスト名から以下の変換をしています。

   -  大文字は小文字に変換
   -  ドメインのサフィックス部分を取り除く(.your-company.co.jpなど)

集計スクリプトのカスタマイズ
---------------------------------------

zabbix-cli はノードの付帯情報ファイルを読みこんで Zabbix アイテムを登録します。
集計スクリプトにZabbix のノード付帯情報ファイル作成のコードを追加します。
例として Oracle 表領域の集計スクリプトのノード付帯情報ファイル作成コードの一部を記します。

::

   cat lib/Getperf/Command/Site/Oracle/OraTbs.pm
   <中略>
      my %stats = ();
      my @tablespaces = keys %results;
      $stats{ora_tbs} = \@tablespaces;
      my $info_file = "info/ora_tbs__${instance}";
      $data_info->regist_node($instance, 'Oracle', $info_file, \%stats);
   <中略>

上記はOracle表領域使用率を Zabbix 用のノード付帯情報に追加しています。
%stats 連想配列のキーを 'ora_tbs' としてノード付帯情報ファイルを生成します。
本スクリプトを実行すると、以下の様なノード付帯情報ファイルが生成されます。

::

   cat node/Oracle/orcl/info/ora_tbs__orcl.json
   {
      "ora_tbs" : [
         "SYSAUX",
         "UNDOTBS1",
         "USERS",
         "SYSTEM"
      ]
   }

このjsonファイルのキーがアイテムキーとなり、アイテム定義ファイルの参照パスは、lib/zabbix/Oracle/ora_tbs.json となります。zabbix-cli は本パスからアイテム定義を読み込み、そのルールに従い、Zabbix にアイテムの登録をします。
