RRDtoolのデータ管理
===================

RRDtool管理コマンド
-------------------

RRDtoolのコマンド操作スクリプト(rrd-cli)を説明します。主な機能は以下の通りです。

* RRDファイル内の集計要素の追加/削除
* 既存のRRDファイルをソースに空のRRDファイルを作成

.. note::

    本スクリプトは RRDtool v1.5以上のみをサポートします。それ以前のバージョンではエラーは発生しませんが、
    正しく機能しません。RRDtool v1.5は前節の"RRDtoolチューニング"を参照してください。

使用方法
--------

::

    Usage : rrd-cli
            [--add-rra|--remove-rra] {rrd_paths} [--interval i] [--days i]
            --create {rrd_path} --from {rrd_path}

集計要素の追加/削除
~~~~~~~~~~~~~~~~~~~

RRDファイル内の集計要素の追加/削除をします。サイトホームディレクトリに移動し、storage ディレクトリ下の
RRDファイルを指定します。以下に例を記します。 

vmstat.rrd ファイルに5秒間隔の集計要素を8日間のリテンションで追加。

::

    rrd-cli --add-rra storage/Linux/{監視対象}/vmstat.rrd --interval 5 --days 8

5秒間隔の集計要素の削除。

::

    rrd-cli --remove-rra storage/Linux/{監視対象}/vmstat.rrd --interval 5

ワイルドカードを使用してまとめて追加が可能です。

::

    rrd-cli --add-rra storage/Linux/*/vmstat.rrd --interval 5

ディレクトリを指定するとその下の全てのRRDファイルを更新します。

::

    rrd-cli --add-rra storage/Linux/{監視対象}/ --interval 3600 --days 180

空のRRDファイル作成
~~~~~~~~~~~~~~~~~~~

既存のRRDファイルの定義を基に新たなRRDファイルを作成します。

::

    rrd-cli  rrd-cli --create storage/Linux/{監視対象}/device/iostat__sdb.rrd --from storage/Linux/{監視対象}/device/iostat__sda.rrd 

.. note::

    クラスター構成の場合、待機系のノードでまだディスクがマウントされていない場合、RRDファイルが作成されない
    場合はあります。その場合は、上記スクリプトで手動でRRDファイルを作成し、あらかじめ空のRRDファイルを作成します。

