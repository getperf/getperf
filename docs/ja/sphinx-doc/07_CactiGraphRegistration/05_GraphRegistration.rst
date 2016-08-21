グラフ登録
==========

前節で作成したグラフテンプレート、グラフ定義ファイル、ノード定義ファイルを基に Cacti リポジトリデータベースにグラフ登録をします。

cacti-cli 使用方法
------------------

グラフ登録は、\ **cacti-cli {ノード定義パス}**\ のコマンドを使用します。
ノード定義パスはnode/{ドメイン}/{ノード}/{メトリック}.json
の形式となり、以下のルールでグラフ登録をします。

-  グラフ定義ファイル　lig/graph/{ドメイン}/{メトリック}.json を選択します
-  グラフ定義ファイルに定義されたグラフテンプレートを基に、グラフを作成します
-  ノード定義パスをディレクトリ指定した場合はその下の全ノード定義ファイルのグラフを登録します

以下に、Linux ドメインのサーバ ostrich　にグラフ登録する例を示します。


::

    # メトリックのグラフ登録をする場合は、node/{ドメイン}/{ノード}/{メトリック}.json を指定します。
    cacti-cli node/Linux/ostrich/vmstat.json

    # ノード下の全てのメトリックを登録する場合は、 node/{ドメイン}/{ノード} を指定します。
    cacti-cli node/Linux/ostrich/

    # ドメイン下の全てのノードを登録する場合は、node/{ドメイン}/ を指定します。
    cacti-cli node/Linux/

グラフ登録の処理は、既存グラフが存在する場合、デフォルトは何もせずに処理をスキップします。既存グラフを上書き更新する場合は
--force[-f] オプションを追加します。

::

    cacti-cli -f node/Linux/ostrich/vmstat.json

force
オプションは既存グラフを削除してから登録をするため、ツリーメニューの配置が同じレベルの一番後ろの位置に移動します。位置を移動させたくない場合は、--skip-tree
オプションを追加します。

::

    cacti-cli -f --skip-tree node/Linux/ostrich/vmstat.json

デバイス付のノード定義のグラフ登録
----------------------------------

デバイス付のノード定義の場合、ノード定義に定義されたデバイスリストの順にグラフ登録します。
例えば、以下例ではLinux の ディスクI/Oのノード定義で、devices タグのリストを順にグラフ登録をします。
登録するデバイスの順番を変えたり、絞り込みをしたい場合は、事前にノード定義のデバイスのリストを編集します。

::

    vi node/Linux/ostrich/device/iostat.json
    {
       "devices" : [
          "sda",
          "dm-0",
          "dm-1",
          "dm-2"
       ],
       "rrd" : "Linux/ostrich/device/iostat__*.rrd"
    }

グラフの登録は同様でノード定義ファイルを指定します。

::

    cacti-cli node/Linux/ostrich/device/iostat.json

デバイスリストをソートしたい場合は、実行オプションに　--device-sort {ソートオプション} を指定します。
ソートオプションは、以下から選択します(デフォルトは noneです)。

-  natural(自然ソート)
-  natural-reverse(自然ソート降順)
-  normal(英字ソート)
-  normal-reverse(英字ソート降順)
-  none(ソートしない)

::

    cacti-cli node/Linux/ostrich/device/iostat.json --device-sort natural 

ビュー定義について
------------------

全てのノードは _defalut ビューの下に保存され、そのパスは、view/\_default/{ドメイン}/{ノード}.json　となります。
以下例の様にドメインディレクトリを指定した場合、_defalut ビューの全ノードリストがグラフ登録対象となります。

::

    cacti-cli node/Linux/

ノードリストをソートしたい場合は、実行オプションに --view-sort {ソートオプション} を指定します。ソートオプションは、以下から選択します(デフォルトは timesamp です)。

-  natural(自然ソート)
-  natural-reverse(自然ソート降順)
-  normal(英字ソート)
-  normal-reverse(英字ソート降順)
-  timestamp(登録タイムスタンプの古い順)

::

    cacti-cli node/Linux/ --view-sort natural 

新たにビューを作成して、ノードの並び順や絞り込みをすることが可能です。以下例ではtest1というビューを作成し、Linux ドメインのノードリストを編集します

::

    mkdir view/test1
    cp -r view/_default/Linux/ view/test1/
    # view/test1/ 下の json ファイルを整理
    # 参照したいノードのみ残してそれ以外を削除する

作成したビューは --tenant {ビュー名} で指定します。
Cacti のツリーメニューに {ビュー名} というメニューが新たに追加され、指定したリストのツリーメニューが作成されます

::

    cacti-cli node/Linux/ --tenant test1

