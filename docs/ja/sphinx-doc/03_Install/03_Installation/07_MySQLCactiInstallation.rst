MySQL, Cacti 設定
======================


Cacti セットアップについて
--------------------------

Getperf 3.1 から Cacti は個別インストールするのではなく、
$GETPERF_HOME/var/cacti の下に Cacti モジュールをバンドルする構成に変更しました。
Cacti を個別インストールする必要はなく、 Cacti のインストールは後述の監視サイト
初期化コマンドで行います。


この後の作業は、以下の動作確認作業となります。

* エージェントのデータ採取
* Cactiサイトへのデータ転送
* グラフ用データ集計
* グラフ登録


実施する場合は :doc:`/03_Install/03_Installation/12_RsyncSetup` のページから進めてください。

