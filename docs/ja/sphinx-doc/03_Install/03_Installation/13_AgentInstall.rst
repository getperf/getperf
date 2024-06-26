Cacti 監視サイトの構築
======================

監視サーバ自身の Cacti 監視サイトを構築します。

Cacti 監視サイト作成
-----------------

以下のスクリプトで監視用サイトを作成します。

::

   initsite -f {サイトディレクトリ}

ここでは {ホーム}/site/ の下に、 site1 という監視サイトを作成します。

::

   mkdir $HOME/site
   cd $HOME/site

   initsite -f site1

以下のメッセージを確認し、 Web ブラウザから、記述の URL で Cacti にアクセスできるか確認します。
ユーザ admin, パスワード admin でログインします。

::

    <中略>
    URL for Cacti monitoring will be following .

    http://{サーバIPアドレス}/site1

また、以下メッセージの site key と access key は後のエージェントセットアップで使用しますので、メモしてください。

::

    <中略>
    The site key is "site1" .
    The access key is "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" .

エージェントセットアップ
------------------------

エージェントのセットアップを行います。エージェントモジュールは、以下の getperf2 を
使用します。
エージェントモジュールは監視用ダウンロードサイトなどから入手してください。
入手出来ない場合は、 :doc:`../04_Getperf2Agent/index` を参照して、
エージェントのビルドを行います。


::

    getperf2-linux-2.x.x.tar.gz 

エージェントモジュールを $HOME の下に解凍します。

::

   # 事前に /tmp の下に getperf2-linux-2.18.0.tar.gz を保存
   cd $HOME
   tar xvf /tmp/getperf2-linux-2.18.0.tar.gz

別環境の Cacti サイト用エージェントモジュールをダウンロードした場合、
ルート証明書が異なる場合があります。その場合、以下のパスのルート証明書
を自身の証明書に上書きしてください。

::

    # diff で証明書の差異を確認
    diff /etc/getperf/ssl/ca/ca.crt ~/ptune/network/ca.crt
    # 証明書が異なる場合は、以下で証明書を上書きコピー
    cp /etc/getperf/ssl/ca/ca.crt ~/ptune/network/ca.crt

エージェントのセットアップコマンドを実行します。

::

   cd $HOME/ptune/bin/
   ./getperfctl setup --url https://{監視サーバIP}:57443/

前節の監視サイト作成で実行したコンソールに表示された、サイトキー、アクセスキーを入力して、セットアップを完了させます。

エージェントを起動します。

::

   ./getperfctl start

サービス起動スクリプトを設定します。

::

   sudo ./install.pl

rsync 設定
----------

エージェントの監視データ保存ディレクトリを rsync を用いて、集計サイトに転送できる
様に設定します。rsyncd.conf ファイルを以下に編集します。

::

    # 既存の rsync 設定ファイルを移動
    sudo mv /etc/rsyncd.conf /etc/rsyncd.conf_org
    # 新規に設定ファイルを開く
    sudo vi /etc/rsyncd.conf

以下のテキストを新規に追加して保存。

::

    # 名前(サイトキー)
    [archive_site1]
    # 転送データの保存ディレクトリ
    path =  /home/psadmin/getperf/t/staging_data/site1/
    hosts allow = *
    hosts deny = *
    list = true
    uid = psadmin
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


rsync デーモンを起動します。

::

   sudo systemctl start rsyncd
   sudo systemctl enable rsyncd

以下のコマンドで rsync の疎通確認をします。

::

   rsync -av --delete \
   rsync://{旧監視サーバアドレス}/archive_{サイトキー} \
   ./tmp

site1 の場合、以下を実行します。

::

   mkdir -p $HOME/work/rsynctest
   cd $HOME/work/rsynctest
   rsync -av --delete rsync://localhost/archive_site1 ./tmp


サイト同期スクリプト(sitesync)動作確認
--------------------------------------

上記 rsync コマンドの疎通確認ができたら監視サイトディレクトリで
sitesync コマンドの動作確認をします。
移動したサイトホーム下に移動し、グラフデータ集計、登録を行います。

::

    cd {サイトディレクトリ}
    ${GETPERF_HOME}/script/sitesync \
    rsync://{旧監視サーバアドレス}/archive_{サイトキー}

例で作成した監視サイト site1 の場合、以下を実行します。

::

    cd $HOME/site/site1
    sitesync rsync://localhost/archive_site1

.. note:: 

    sitesync コマンドはサイトホームディレクトリに移動してから実行してください。

実行すると、analysis 下にエージェントの転送データが保存されます。

::

    ls analysis/{監視対象}/Linux/
    ls analysis/{監視対象}/Linux/{現在日付(YYYYMMDD)}
    ls analysis/{監視対象}/Linux/{現在日付(YYYYMMDD)}/{現在時刻(HHMMSS)}

.. note::

    監視対象は自身のホスト名になります。現在日時、現在時刻は ls で確認した
    ものを指定してください

cronで定期起動
--------------

上記で、sitesyncスクリプトの同作確認ができたら、cron よる定期起動の設定をします。
cron 定期実行スクリプトのサンプルをサイトにコピーして編集します。

::

    cd $HOME/site/site1
    cp ~/getperf/script/cron_sumup.sh.sample script/cron_sumup.sh
    vi script/cron_sumup.sh

以下の行を編集します。

::

    (
    cd /home/psadmin/site/site1
    $SYTESYNC rsync://localhost/archive_site1      $OPT 1> /dev/null 2> /dev/null
    )

.. note::

    上記は自サーバの site1 サイトの設定となり、別サイトの場合は環境に合わせて修正します。

    ::

        (
        cd {作成したサイトディレクトリ}
        $SYTESYNC rsync://{作成したRSyncURL}      $OPT 1> /dev/null 2> /dev/null
        )

Cron の設定をします。

::

    EDITOR=vi crontab -e

5分周期で 集計スクリプトを定期実行する設定をします。

.. note::

    Perl5.16.3環境での cron 設定

    cron の設定で、インストールパスを有効にするため、コマンド先頭行に以下の設定を追加します。
    各cron の実行コマンドの先頭に、「source /home/psadmin/.bash_profile && 」を追加します。


::

   0,5,10,15,20,25,30,35,40,45,50,55 * * * * (source /home/psadmin/.bash_profile && {サイトディレクトリ}/script/cron_sumup.sh > /dev/null 2>&1) &
   # 上記例の場合
   0,5,10,15,20,25,30,35,40,45,50,55 * * * * (source /home/psadmin/.bash_profile && /home/psadmin/site/site1/script/cron_sumup.sh > /dev/null 2>&1) &

Cacti 監視グラフ登録
--------------------

この後の作業は、グラフ設定となります。

以下コマンドで監視対象ホストのノード定義ディレクトリを指定してグラフ登録します。

::

    cd ~/site/site1/
    cacti-cli -f node/Linux/{監視サーバホスト名}/

監視サイトの Cacti URL を参照して、グラフが登録されていることを確認します。

::

    httpd://{監視サーバIPアドレス}/{サイトキー}/


上記例の場合は以下URLになります。

::

    httpd://{監視サーバIPアドレス}/site1/

ユーザ/パスワードに admin/admin を入力してログインしてください。
