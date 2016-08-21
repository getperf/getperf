Zabbix監視登録
==============

zabbix-cli 使用方法
-------------------

ノードパスを指定して、そのノード定義をZabbixリポジトリデータベースに登録します。

::

   Usage : zabbix-cli
     [--hosts={.hosts}] [--add|--rm|--info] {./node/{domain}/...}

Zabbixに以下の監視項目を登録します。

-  Zabbix ホストグループ
-  Zabbix テンプレート
-  Zabbix ホスト
-  Zabbix アイテム

ノードパスの指定方法
----------

zabbix-cli コマンドは以下のルールで指定したノードディレクトリ下の情報を Zabbix　に登録します。

引数の指定がノードディレクトリの場合
~~~~~~~~~~~~~~~~~~~~~~~~~~

::

   zabbix-cli --add ./node/{ドメイン}/{監視対象ノード}/

1. 引数に指定したパスのドメインのドメイン定義ファイルを読みこみます。
2. ドメイン定義ファイルのルールで Zabbix **ホスト** を検索します。登録済みの場合は何もせずに終了しますします。
3. ドメイン定義ファイルのルールで Zabbix **ホストグループ** を登録します。登録済みの場合は処理をスキップします。
4. ドメイン定義ファイルのルールで Zabbix **テンプレート** を登録します。登録済みの場合は処理をスキップします。
5. ホストを登録します。
6. 3,4 で登録したホストグループとテンプレートをホストに所属させます。
7. ./node/{ドメイン}/{監視対象ノード}/info 下のノード付帯情報ファイルを順に読込み、後述のアイテム登録をします。

引数の指定がノード付帯情報ファイルの場合
~~~~~~~~~~~~~~~~~~~~~~~~~~~

::

   zabbix-cli --add ./node/{ドメイン}/{監視対象ノード}/info/{ノード付帯情報}.json

1. はじめに上記ノードディレクトリの手順でノードの登録を行います。
2. json ファイルを読みこみ、json のキー情報を順に検索して、 3～5 の処理を行います。
3. json ファイルのキー名から、アイテム定義ファイルを検索して読みこみます。
4. アイテム定義ファイルのルールで Zabbixの **アイテム** を検索します。登録済みの場合は処理をスキップします。
5. アイテムを登録します。

オプション
---------------

--info {ノード定義パス}
~~~~~~~~~~~~~~~~~~~~~~~

上記で説明した手順を順に行い、 Zabbix の登録情報を出力します。実際の Zabbix への登録はしません。--add　オプションに変えることにより　Zabbix　へ登録します。

例として、Oracle 表領域ノード定義の Zabbix 登録情報を確認します。

::

   vi ./node/Oracle/orcl/info/ora_tbs__orcl.json
   cat ./node/Oracle/orcl/info/ora_tbs__orcl.json
   {
      "ora_tbs" : [
         "USERS",
         "SYSTEM"
      ]
   }

上記の "ora_tbs" がアイテム定義ファイルの検索キーとなり、値が登録するアイテムリストとなります。以下、コマンドを実行すると、Zabbix に登録する、ホスト、ホストグループ、テンプレート、インターフェース、アイテムの情報が出力されます。

::

   zabbix-cli --info ./node/Oracle/orcl/info/ora_tbs__orcl.json
   2016/06/02 09:28:45 [NOTICE] Regist Zabbix node Oracle/orcl
   host => {
     'interfaces' => [
       {
         'dns' => '',
         'useip' => 1,
         'ip' => '127.0.0.1',
         'type' => 1,
         'port' => '10050',
         'main' => 1
       }
     ],
     'ip' => '127.0.0.1',
     'host_name' => 'orcl',
     'is_physical_device' => 0,
     'host_visible_name' => 'Oracle - orcl',
     'host_groups' => [
       'Oracle'
     ],
     'templates' => [
       'Template Oracle'
     ]
   };
   items => [
     {
       'value_type' => 'numeric float',
       'delay' => 3600,
       'type' => 'Zabbix trapper',
       'item_name' => 'adm.oracle.tbs.usage.USERS',
       'key' => 'adm.oracle.tbs.usage.USERS'
     },
     {
       'value_type' => 'numeric float',
       'delay' => 3600,
       'type' => 'Zabbix trapper',
       'item_name' => 'adm.oracle.tbs.usage.SYSTEM',
       'key' => 'adm.oracle.tbs.usage.SYSTEM'
     }
   ];

.. note::

   上記は Zabbix エージェントレス監視の例で、その場合、IPアドレスはデフォルトで '127.0.0.1' になります。IPアドレスはZabbix ホスト登録の必須項目となり、名目上、本 IP で登録をしますが、実際、Zabbix は本 IP を使用しません。

--add {ノード定義パス}
~~~~~~~~~~~~~~~~~~~~~~

指定したノード定義パスを Zabbix へ登録します。

--rm {ノード定義パス}
~~~~~~~~~~~~~~~~~~~~~

指定したノード定義パスを削除します。

--hosts={.hosts}
~~~~~~~~~~~~~~~~~~~~~

.hostsファイルのパスを指定します。

ノードパスとマルチサイトの登録ルール
------------------------------------

以下の指定が有った場合、Zabbixドメイン定義の Zabbix ホストグループ、テンプレートに加え、
新たにノードパス、マルチサイトを指定したホストグループ、テンプレートが追加登録されます。

- ノード付帯情報ファイルにノードパス "node_path" の定義が有った場合。
- $GETPERF_HOME/conf/getperf_zabbix.json の USE_ZABBIX_MULTI_SIZE を 1 にして、 Zabbix のマルチサイトを有効にした場合。

以下にノードパス、マルチサイトの指定による追加例を記します。

例 : ノード付帯情報ファイルにノードパスを追加した場合

::

   vi node/Oracle/orcl/info/ora_tbs__orcl.json
   # node_path を追加します。以下例では "/abc" がノードディレクトリになります
   {
      "node_path" : "/abc/orcl",
      "ora_tbs" : [
         "USERS",
         "SYSTEM"
      ]
   }

   # ホストグループとテンプレートは以下となります。
   zabbix-cli --info ./node/Oracle/orcl/
   <中略>
   'host_groups' => [
    'Oracle',
    'Oracle - abc'
   ],
   'templates' => [
    'Template Oracle',
    'Template Oracle - abc'
   ]


例 : Zabbix のマルチサイトが有効の場合

getperf_zabbix.json の USE_ZABBIX_MULTI_SIZE を 1 にします。

::

   vi $GETPERF_HOME/config/getperf_zabbix.json
   # "USE_ZABBIX_MULTI_SIZE" を 1にします
   grep USE_ZABBIX_MULTI_SITE ~/getperf/config/getperf_zabbix.json
   "USE_ZABBIX_MULTI_SITE": 1,

   # groups と templates は以下となります。
   zabbix-cli --info ./node/Oracle/orcl/
   <中略>
   'host_groups' => [
    'Oracle',
    'Oracle - {サイトキー} - abc'
   ],
   'templates' => [
    'Template Oracle',
    'Template Oracle - {サイトキー} - abc'
   ]
