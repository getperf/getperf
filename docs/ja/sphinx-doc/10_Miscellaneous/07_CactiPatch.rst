Cacti-0.8.8c以降のバージョンと IE の互換性対応
=======================================

Cacti-0.8.8c から、ツリーメニュー表示用ライブラリが変更となり、
IEとの相性の問題でCacti のメニューレイアウトが崩れる問題が発生します。本件は以下対応で解消されます。

* IE11 を使用する
* Cacti スクリプトに後述のパッチを適用する

Cacti パッチ適用
--------------

Cacti サイト の Cacti ホームディレクトリに移動します。

::

	cd {サイトホーム}/html/cacti

以下2つのスクリプト内の <meta http-equiv="X-UA-Compatible" content="edge"> の記述を変更します。
content="edge" を、content="IE=11" に変えます。

::

	sed -i -e "s/content=\"edge\"/content=\"IE=11\"/g" include/top_header.php
	sed -i -e "s/content=\"edge\"/content=\"IE=11\"/g" include/top_graph_header.php

