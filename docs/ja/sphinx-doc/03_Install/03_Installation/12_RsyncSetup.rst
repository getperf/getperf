Rsync セットアップ
==================

エージェントの採取データをサイトにデータ転送（フォワード）する仕組みを設定します。

1. 監視サーバ上に Cacti 監視エージェントをセットアップして自身を監視します。
2. テスト用の監視サイトを作成し、Rsync を用いて監視エージェントからのデータ転送を設定します。
3. データ転送されたテスト用監視サイトで監視グラフ登録をします。


事前準備
--------

RSync のインストール
^^^^^^^^^^^^^^^^^

RSync の関連パッケージをインストールします。

::

    sudo -E yum -y install rsync xinetd  rsync-daemon

Git 環境設定
^^^^^^^^^^

以下のコマンドを実行して Git の環境設定をします。
メールアドレス、ユーザ名は環境に合わせて設定してください。

::

   # デフォルトブランチを main にします
   git config --global init.defaultBranch main

   # メールアドレスを設定します
   git config --global user.email "管理者のメールアドレス"
   # 指定が不要な場合は以下を設定してください
   git config --global user.email "you@example.com"

   # ユーザ名を設定します
   git config --global user.name "管理者名"
   # 指定が不要な場合は以下を設定してください
   git config --global user.name "Your Name"

Perl 5.16.3 環境構築
^^^^^^^^^^^^^^^^^^

集計モジュールと互換性を維持するため、 Perl 環境管理ツール plenv を使用して、 
Perl 5.16.3 を $HOME/.plenv 下にインストールします。

Perl 管理ツール plenv インストール

::

    git clone https://github.com/tokuhirom/plenv.git ~/.plenv
    git clone https://github.com/tokuhirom/Perl-Build.git ~/.plenv/plugins/perl-build/
    echo 'export PATH="$HOME/.plenv/bin:$PATH"' >> ~/.bash_profile
    echo 'eval "$(plenv init -)"' >> ~/.bash_profile
    exec $SHELL -l

Perl v5.16.3のインストールと有効化

::

    plenv install 5.16.3
    plenv global 5.16.3
    plenv local 5.16.3

cpanm と、Perl ライブラリをインストールします

::

    PLENV_INSTALL_CPANM="-v" plenv install-cpanm
    cd $GETPERF_HOME
    cpanm --installdeps --notest .

MySQL Perl ライブラリをインストールします

::

    cpanm DBD::mysql


Cacti 監視サイト作成
-----------------

以下のスクリプトで監視用サイトを作成します。

::

   initsite -f {サイトディレクトリ}

ここでは ~/site/の下に、 site1 という監視サイトを作成します。

::

   mkdir $HOME/site
   cd $HOME/site

   initsite -f site1

以下のメッセージを確認し、 Web ブラウザから、記述の URL で Cacti にアクセスできるか確認します。
ユーザ admin, パスワード admin でログインします。

::

    URL for Cacti monitoring will be following .

    http://{サーバIPアドレス}/site1

また、以下メッセージの site key と access key は後のエージェントセットアップで使用しますので、メモしてください。

::

    The site key is "site1" .
    The access key is "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" .

エージェントセットアップ
------------------------

エージェントのセットアップを行い、作成した監視サイトと連携します。

エージェントモジュールは、以下の getperf2 版を使用します。

::

    getperf2-linux-2.18.0.tar.gz 

エージェントコンパイルで作成したモジュールを $HOME の下に解凍します。

::

   # 事前に /tmp の下に getperf2-linux-2.18.0.tar.gz を保存
   cd $HOME
   tar xvf /tmp/getperf2-linux-2.18.0.tar.gz

別環境の Cacti サイトから エージェントモジュールをダウンロードした場合、ルート証明書が異なる場合があります。
その場合、以下のパスのルート証明書に上書きします。

::

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

サイトの転送データ保存ディレクトリを rsync で同期が取れる様に設定します。
rsyncd.conf ファイルを以下例の様に編集します。

::

    # 既存のサンプル設定ファイルを移動
    sudo mv /etc/rsyncd.conf /etc/rsyncd.conf_org
    # 新規に設定ファイルを開く
    sudo vi /etc/rsyncd.conf

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


rsync 設定後、 rsync デーモンを起動します。

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
移動したサイトホーム下に移動し、データ集計、データ登録を行います。

::

    cd {サイトディレクトリ}
    ${GETPERF_HOME}/script/sitesync \
    rsync://{旧監視サーバアドレス}/archive_{サイトキー}

例で作成した監視サイト site1 の場合、以下を実行します。

::

    cd $HOME/site/site1
    sitesync rsync://localhost/archive_site1

実行すると、analysis 下に旧サイトの収集ファイルが保存されます。

::

    ls analysis/{監視対象}

.. note:: 

    sitesync コマンドはサイトホームディレクトリに移動してから実行してください。

cronで定期起動
--------------

上記で、sitesyncスクリプトの同作確認ができたら、cron よる定期起動の設定をします。
cron 定期実行スクリプトのサンプルをサイトにコピーして編集します。

::

    cd $HOME/site/site1
    cp ~/getperf/script/cron_sumup.sh.sample script/cron_sumup.sh
    vi script/cron_sumup.sh

::

    (
    cd /home/psadmin/site/site1
    $SYTESYNC rsync://localhost/archive_site1      $OPT 1> /dev/null 2> /dev/null
    )

上記記述を環境に合わせて修正します。

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

ユーザ/パスワードに admin/admin を入力してログインしてください。
