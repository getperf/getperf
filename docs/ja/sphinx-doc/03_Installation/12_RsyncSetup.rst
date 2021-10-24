Rsync セットアップ
==================

機能概要
--------

エージェントの採取データをサイトにデータ転送（フォワード）する仕組みを用意します。

rsync のインストール
~~~~~~~~~~~~~~~~~~~~

::

    sudo -E yum -y install rsync xinetd

.. note::

    RHEL8 の場合、

        sudo -E yum -y install rsync-daemon

サイト作成
~~~~~~~~~~

以下のスクリプトで監視用サイトを作成します。

::

   initsite -f {サイトディレクトリ}

ここでは例として、~/site/の下に、 site1 という監視サイトを作成します。

::

   mkdir $HOME/site
   cd $HOME/site

   initsite -f site1

エージェントセットアップ
~~~~~~~~~~~~~~~~~~~~~~~~

エージェントのセットアップを行い、作成した監視サイト
との連携をします。

エージェントコンパイルで作成したモジュール 
getperf-Build10-CentOS7-x86_64.tar.gz を $HOME の下に解凍します。

::

   # 事前に /tmp の下に getperf-Build10-CentOS7-x86_64.tar.gz を保存
   cd $HOME
   tar xvf /tmp/getperf-Build10-CentOS7-x86_64.tar.gz

エージェントのセットアップを行います。

::

   cd ptune/bin/
   ./getperfctl setup

上記サイト作成スクリプト実行で表示された、サイトキーを入力します。

エージェントを起動します。

::

   ./getperfctl start

サービス起動スクリプトを設定します。

::

   sudo ./install.pl

rsync 設定
~~~~~~~~~~

サイトの転送データ保存ディレクトリを rsync で同期が取れる様に
設定します。rsyncd.conf ファイルを以下例の様に編集します。

::

   sudo vi /etc/rsyncd.conf

::

    # 名前(サイトキー)
    [archive_site1]
    # 転送データの保存ディレクトリ
    path =  /home/psadmin/getperf/t/staging_data/site1/
    # 転送先許可IPアドレス(新サーバから疎通できるようにする)
    hosts allow = *
    hosts deny = *
    list = true
    # 転送データのオーナー
    uid = psadmin
    # 転送データのオーナーグループ
    gid = psadmin
    read only = false 
    dont compress = *.gz *.tgz *.zip *.pdf *.sit *.sitx *.lzh *.bz2 *.jpg *.gif *.png

rsync 起動
~~~~~~~~~~

rsync 設定後、xinetd を再起動して、rsync デーモンを起動します。

::

   sudo systemctl start rsyncd
   sudo systemctl enable rsyncd

rsync疎通確認
~~~~~~~~~~~~~

以下のコマンドで rsync の疎通確認をします。

::

   rsync -av --delete \
   rsync://{旧監視サーバアドレス}/archive_{サイトキー} \
   ./tmp

作成した監視サイト site1 での確認する場合、以下を実行します。

::

   mkdir -p $HOME/work/rsynctest
   cd $HOME/work/rsynctest
   rsync -av --delete \
   rsync://localhost/archive_site1 \
   ./tmp

.. note:: 旧監視サーバ側でSELinuxが有効だと以下の権限エラーが発生します

   ::

       Oct  3 12:28:57 xxx rsyncd[4073]: rsync: chroot /home/pscommon/perfstat/_bk failed: Permission denied (13)

サイト同期スクリプト(sitesync)動作確認
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

上記 rsync コマンドの疎通確認ができたら監視サイトディレクトリで sitesync コマンド単体の動作確認をします。
移動したサイトホーム下に移動し、データ集計、データ登録を行います。

::

    cd {サイトディレクトリ}
    ${GETPERF_HOME}/script/sitesync \
    rsync://{旧監視サーバアドレス}/archive_{サイトキー}

例で作成した監視サイト site1 の場合、以下を実行します。

::

    cd $HOME/site/site1
    sitesync rsync://localhost/archive_site1

正しく実行すると、analysis 下に旧サイトの収集ファイルが保存されます。
この後のデータ集計以降の処理は従来と同じです。

::

    ls analysis/{監視対象}

.. note:: sitesync コマンドはサイトホームディレクトリに移動してから実行してください。

cronで定期起動
--------------

上記で、sitesyncスクリプトの同作確認ができたら、cron による定期起動の設定をします。

::

   0,5,10,15,20,25,30,35,40,45,50,55 * * * * (cd {サイトディレクトリ}; {GETPERFホームディレクトリ}/script/sitesync rsync://{旧監視サーバアドレス}/archive_{サイトキー} > /dev/null 2>&1) &

例で作成した監視サイト site1 の場合、以下を実行します。

::

   0,5,10,15,20,25,30,35,40,45,50,55 * * * * (cd /home/psadmin/site/site1; /home/psadmin/getperf/script/sitesync rsync://localhost/archive_site1 > /dev/null 2>&1) &

この後の作業は、グラフ設定となります。

