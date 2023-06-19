Rsync セットアップ
==================

エージェントの採取データをサイトにデータ転送（フォワード）する仕組みを設定します。

1. 監視サーバ上に Cacti 監視エージェントをセットアップして自身を監視します。
2. テスト用の監視サイトを作成し、Rsync を用いて監視エージェントからのデータ転送を設定します。
3. データ転送されたテスト用監視サイトで監視グラフ登録をします。


事前準備
--------

RSync の関連パッケージをインストールします。

::

    sudo -E yum -y install rsync xinetd  rsync-daemon

以下のコマンドを実行して git の環境設定をします。

::

   git config --global init.defaultBranch main
   # git config --global user.email "you@example.com"
   git config --global user.email "管理者のメールアドレス"
   # git config --global user.name "Your Name"
   git config --global user.name "管理者名"

監視サイト作成
--------------

以下のスクリプトで監視用サイトを作成します。

::

   initsite -f {サイトディレクトリ}

ここでは例として、~/site/の下に、 site1 という監視サイトを作成します。

::

   mkdir $HOME/site
   cd $HOME/site

   initsite -f site1

エージェントセットアップ
------------------------


エージェントのセットアップを行い、作成した監視サイトと連携します。

エージェントコンパイルで作成したモジュールを $HOME の下に解凍します。

::

   # 事前に /tmp の下に getperf-zabbix-BuildXX-XXXX-x86_64.tar.gz を保存
   cd $HOME
   tar xvf /tmp/getperf-zabbix-BuildXX-XXXX-x86_64.tar.gz

エージェントのセットアップコマンドを実行します。

::

   cd ptune/bin/
   ./getperfctl setup

前節の監視サイト作成で実行したコンソールに表示された、サイトキー、
アクセスキーを入力して、セットアップを完了させます。

エージェントを起動します。

::

   ./getperfctl start

サービス起動スクリプトを設定します。

::

   sudo ./install.pl

rsync 設定
----------

サイトの転送データ保存ディレクトリを rsync で同期が取れる様に設定します。
rsyncd.conf ファイルを以下例の様に編集します。

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

上記の先頭部分は登録したサイトキーに合せて設定します。
以下、{サイトキー}の箇所を、作成したサイトキーに合せて設定してください。

::

    # 名前(サイトキー)
    [archive_{サイトキー}]
    # 転送データの保存ディレクトリ
    path =  /home/psadmin/getperf/t/staging_data/{サイトキー}/


rsync 設定後、xinetd を再起動して、rsync デーモンを起動します。

::

   sudo systemctl start rsyncd
   sudo systemctl enable rsyncd

以下のコマンドで rsync の疎通確認をします。

::

   rsync -av --delete \
   rsync://{旧監視サーバアドレス}/archive_{サイトキー} \
   ./tmp

site1 での確認する場合、以下を実行します。

::

   mkdir -p $HOME/work/rsynctest
   cd $HOME/work/rsynctest
   rsync -av --delete \
   rsync://localhost/archive_site1 \
   ./tmp


サイト同期スクリプト(sitesync)動作確認
--------------------------------------

上記 rsync コマンドの疎通確認ができたら監視サイトディレクトリで
sitesync コマンドの動作確認をします。
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

.. note:: 

    sitesync コマンドはサイトホームディレクトリに移動してから実行
    してください。

cronで定期起動
--------------

上記で、sitesyncスクリプトの同作確認ができたら、cron よる定期起動
の設定をします。

::

   0,5,10,15,20,25,30,35,40,45,50,55 * * * * (cd {サイトディレクトリ}; {GETPERFホームディレクトリ}/script/sitesync rsync://{監視サーバアドレス}/archive_{サイトキー} > /dev/null 2>&1) &

例で作成した監視サイト site1 の場合、以下を実行します。

::

   0,5,10,15,20,25,30,35,40,45,50,55 * * * * (cd /home/psadmin/site/site1; /home/psadmin/getperf/script/sitesync rsync://localhost/archive_site1 > /dev/null 2>&1) &

Cacti 監視グラフ登録
--------------------

この後の作業は、グラフ設定となります。

cacti-cli コマンドで Linux 用監視グラフテンプレートを作成します。

::

    cd $HOME/site/site1
    cacti-cli -f -g lib/graph/Linux/diskutil.json
    cacti-cli -f -g lib/graph/Linux/iostat.json
    cacti-cli -f -g lib/graph/Linux/loadavg.json
    cacti-cli -f -g lib/graph/Linux/memfree.json
    cacti-cli -f -g lib/graph/Linux/netDev.json
    cacti-cli -f -g lib/graph/Linux/vmstat.json


続けて、 以下コマンドで監視対象ホストのノード定義ディレクトリを指定して
グラフ登録します。

::

    cacti-cli -f node/Linux/{監視サーバホスト名}/

監視サイトの Cacti URL を参照して、グラフが登録されていることを確認します。

::

    httpd://{監視サーバIPアドレス}/{サイトキー}/


上記例の場合は以下URLになります。

::

    httpd://{監視サーバIPアドレス}/site1/

