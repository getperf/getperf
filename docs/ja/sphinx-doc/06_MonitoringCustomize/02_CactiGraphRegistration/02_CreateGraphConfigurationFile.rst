グラフ定義ファイル
======================

はじめにグラフ定義ファイルの作成を行います。
ここでは既に作成済みのグラフ定義ファイルを基に定義内容の確認のみ行います。
グラフ定義ファイルの場所は、
lib/graph/{domain}/{metric}.json　の形式となり、試しにデフォルトでインストールされている Linux/loadavg.json ファイルを開いて確認します。

::

   vi lib/graph/Linux/loadavg.json

.. code-block:: javascript

   {
     "host_template": "Linux",
     "host_title": "Linux - <node>",
     "priority": 1,
     "graphs": [
       {
         "graph_template": "Linux - CPU Load Average",
         "graph_tree": "/HW/<node_path>/CPU/Load",
         "graph_title": "Linux - <node> - CPU Load Average",
         "graph_items": ["load1m","load5m","load15m"],
         "graph_item_texts": ["1min","5min","15min"],
         "vertical_label": "count",
         "upper_limit": 10,
         "unit_exponent_value": 1,
         "datasource_title": "Linux - <node> - CPU Load Average"
       }
     ]
   }

シングルグラフのグラフテンプレートパターンで、loadavg メトリックの項目 load1m, load5m, load15m を凡例としたグラフを構成します。
各要素の定義を次節に記します。

マクロ定義
----------

グラフ定義はという記述でマクロを定義します。
これは、グラフテンプレートを実体のグラフに登録する際の実名前に置換するのに使用します。

- <node>

   ノード定義のノード名。サーバ名などの実体の名前に置換します。

.. note::

   ノード定義ファイルで 'node_alias' という定義を設定すると、'node_alias' の値で置換します。

   ::

      more node/SNMPNetwork/192.168.100.1/info/model.json
      {
         "node_alias" : "CL-NY-A0203-LEAFPX01"
      }

- <node_path>

   ノード情報の node_path 要素が、階層ディレクトリの記述の場合、ディレクトリ部分を置換します。
   ディレクトリがない場合は空白文字に置換します。

- <device>

   デバイス定義 node/{ドメイン}/{ノード名}/device/{メトリック}.json 内リストのデバイス名に置換します。

グラフ定義の各要素
------------------

グラフ定義ファイルの各要素の記述方法を以下に記します

- host_template

   ホストテンプレート名となり、通常はドメイン名と同じにします。

- host_title

   Cacti のデバイス名の定義となり、対象ノードで構成される複数グラフを括った名前となり、通常は"{ドメイン名}　- <node>"とします。

- priority

   複数のメトリックをまとめて登録する場合に、どの順番でグラフ登録をするかの優先度となり、低いものから順にグラフ登録をします。
   Cacti　ツリーメニューはグラフ登録した順に上から配置されるため、ツリーメニューの配置に合わせて優先度を設定します。

- graphs

   配列の形式で複数のグラフを定義します。graphs 内セクションの各定義は以下の通りです。

graphs セクション

- graph_template

   グラフテンプレート名となります。

- graph_tree

   グラフツリーの定義で '/' で区切ってメニューの階層を定義します。グラフツリーはマクロを使用します。
   ノード構成情報に node_path 要素が存在する場合、 は node_path 要素のディレクトリ部分、 はファイル名部分に置換します。

- graph_items

   グラフの凡例で配列の形式で定義します。凡例は RRDtool のrrdファイルのデータソース名定義と同じ名前にする必要が有ります。

- graph_item_texts

   グラフ凡例の表示名となります。

- vertical_label

   グラフY軸の説明テキストとなります。

- upper_limit

   グラフY軸の上限値を設定します。設定しない場合は自動調整(オートスケール)となります。

- graph_title

   グラフ実体のタイトル名定義となり、マクロにより実体のグラフのタイトル名に置換します。
   グラフタイトルはサイト内で一意の名前にする必要が有ります。

- datasource_title

   データソース実体のタイトルとなり、graph_title と同様に一意の名前にする必要が有ります。

- chart_style

   グラフレイアウトのスタイルで、折れ線グラフの場合、　line1, line2, line3 を指定します。
   名前の数値は線の太さを表し、line3 が最も太い線となります。
   積み上げグラフの場合、stack を指定します。デフォルトは line1 です。

- total_data_source

   グラフ凡例の合計値線を追加します。合計値の計算式として、"Total All Data Sources" などの CDEF 関数名を指定します。

- legend_type

   凡例の表示パターンはデフォルトでカレント、平均、最大値を表示しますが、本表示を変えたい場合に以下指定をします。
   show_average(平均値のみの表示)、show_current(カレント値のみの表示)、show_maximum(最大値のみ表示)、minimum(凡例を表示しない)。

- graph_item_cols

   凡例の表示で1行当りに改行する指標数を指定します。指定しない場合はデフォルトで1指標ごとに改行します。

- color_scheme

   配色定義ファイル指定します。cacti-cli コマンドの配色定義ファイルの指定よりも本値が優先されます。

デバイス付きグラフの記述方法
----------------------------

グラフ定義は前述の各要素を順に記載しますが、デバイス付きのグラフパターンで記述が異なる個所が有ります。
デバイス付きのグラフパターンでの相違点を以下に記します。

-  シングルデバイスグラフの場合

   1つのデバイスにつき1つのグラフを追加し、複数のグラフを追加する構成となります。
   graph_title と datasource_title に <device> マクロを追加します。これは複数デバイスのグラフで一意性を持たせるためです。
   場合によっては、graph_tree に　<device> マクロを追加して、デバイス毎にメニューを作成することも可能です。

   記述例 lib/graph/Linux/iostat.json

   ::

      {
        "graph_template": "HW - Disk IO/sec",
        "graph_items": ["r_s", "w_s"],
        "graph_tree": "/HW/<node_path>/DiskIO/<node>/<device>",
        "graph_title": "HW - <node> - Disk IO/s - <device>",
        "datasource_title": "HW - <node> - Disk IO/s - <device>"
      }

-  マルチデバイスグラフの場合

   1つのグラフに複数デバイスの凡例を追加する場合に使用します。デバイスの凡例数の最大値を指定し、その数分のグラフテンプレートが作成されます。

   記述例 lib/graph/Linux/iostat.json

   ::

      {
        "graph_template": "HW - Disk Busy% - <devn> cols",
        "graph_type": "multi",
        "legend_max": 15,
        "graph_items": ["pct"],
        "graph_tree": "/HW/<node_path>/DiskIO/",
        "graph_title": "HW - <node> - Disk Busy%",
        "datasource_title": "HW - <node> - Disk Busy% - <device>"
      }

   -  graph_template の末尾に "- <devn> cols" を追加します。
   -  graph_type : "multi" を追加します。
   -  legend_max に1つのグラフに登録するデバイス数を最大値を指定します。指定数以上のデバイスを登録する場合は、新たに 2 つ目の以降のグラフが登録されます。
   -  テンプレートの作成コマンドで、legend_max で指定した数分のグラフテンプレートが生成されます。上記の例では、"HW - Disk Busy% - 1 cols" ～ "HW - Disk Busy% - 15 cols" の15個のグラフテンプレートが生成されます。
   -  graph_items は 1項目の指定とし、複数項目の指定はしないでください。
   -  datasource_title のみ <device> マクロを追加してください。 graph_titele には <device> マクロを追加しないで下さい。

