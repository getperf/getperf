Getconfig インベントリ収集ログの同期
====================================

機能概要
--------

Cacti 受信サーバからインベントリ収集用のzipログファイルの転送、解凍を行います。

.. note::

   事前に sitesync でCacti受信サーバからzip転送でき、
   Cacti エージェントでインベントリ収集用の zip ログファイルを定期保存している
   環境を準備します


監視サーバ側設定
----------------

rsync疎通確認
~~~~~~~~~~~~~

新監視サーバ側で rsync の疎通確認をします。
以下は、旧監視サーバの転送データを新監視サーバの/tmpディレクトリ下にコピーします。

::

   rsync  -av --delete  --include '*Conf_*' --exclude '*' \
   rsync://{旧監視サーバアドレス}/archive_{サイトキー} \
   ./tmp

実行例

::

   rsync -av --delete  --include '*Conf_*' --exclude '*' \
      rsync://192.168.0.15/archive_site1 /tmp

サイト同期スクリプト(gsitesync)動作確認
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

上記 rsync コマンドの疎通確認ができたら新監視サーバのサイトホームディレクトリで sitesync コマンド単体の動作確認をします。
以下は、上記、rsyncによるデータ同期後、移動したサイトホーム下のデータ集計、データ登録を行います。

::

   cd {サイトディレクトリ}
   ${GETPERF_HOME}/script/gsitesync \
    --store=./inventory --purge \
   rsync://{旧監視サーバアドレス}/archive_{サイトキー} 

実行例

::

   cd ~/work/site1
   gsitesync --store=./inventory --purge rsync://192.168.0.15/archive_site1

実行すると、./inventory 下にインベントリ収集用のログファイルが保存されます。

::

    ls inventory/{サーバ名}/{プラットフォーム}

cronで定期起動
--------------

上記で、sitesyncスクリプトの同作確認ができたら、cron による定期起動の設定をします。

バッチスクリプトを作成します。

::

   cd {サイトディレクトリ}
   vi script/cron_gsitesync.sh

以下スクリプトをコピーします。SITE_HOME、RSYNC_URLを環境に合わせて修正してください。

::

   #!/bin/sh
   # 解凍先のサイトホームディレクトリ。事前に initsite でサイトの初期化が必要
   SITE_HOME=$HOME/work/site1
   # 転送元の rsync URL
   RSYNC_URL=rsync://192.168.0.15/archive_site1
   GETPERF_HOME=$HOME/getperf
   (
   cd $SITE_HOME
   $GETPERF_HOME/script/gsitesync --store=./inventory --purge $RSYNC_URL
   )

実行権限を付与します。

::

   chmod a+x script/cron_gsitesync.sh

cron の定期起動設定をします。

::

   EDITOR=vi crontab -e

::

   0 * * * * ({サイトディレクトリ}/script/cron_gsitesync.sh > /dev/null 2>&1) &

例：

::

   0 * * * * (/home/psadmin/work/site1/script/cron_gsitesync.sh > /dev/null 2>&1) &
