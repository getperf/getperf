基本パッケージのインストール
============================

はじめに基本パッケージをインストールします。管理ユーザで **sudo -E yum**
コマンドでインストールします。-E は sudo ユーザの環境変数を読みこむオプションで、前節で設定したプロキシー設定を有効にするために必要になります。

::

    sudo -E yum -y groupinstall "Development Tools"
    sudo -E yum -y install kernel-devel kernel-headers
    sudo -E yum -y install libssh2-devel expat expat-devel libxml2-devel
    sudo -E yum -y install perl-XML-Parser perl-XML-Simple perl-Crypt-SSLeay perl-Net-SSH2
    sudo -E yum -y update

Getperf モジュールのダウンロードと解凍
======================================

Getperf モジュールをダウンロードし、ホームディレクトリの下に解凍します ※
暫定公開版

::

    (Download 'getperf.tar.gz' from the provisional site)
    cd $HOME
    tar xvf getperf.tar.gz

**注意事項**

    Getperf のインストールは 'getperf.tar.gz'
    のモジュール一式をダウンロードして行いますが、まだ限定公開のライセンスとなるため、正式なダウンロードサイトが存在しません。ダウンロードモジュールが必要な場合は `モジュールのダウンロード <docs/ja/docs/../docs/faq.md>`_ の問い合わせ先から入手してください

Perlライブラリのインストール
============================

Perlライブラリ管理ソフト cpanm を使用します。
cpanm　をインストールし、cpanm --installdeps コマンドを用いて必要な Perl
ライブラリをインストールします

Getperf のホームディレクトリを GETPERF_HOME 環境変数に設定します

::

    cd ~/getperf
    source script/profile.sh
    echo source $GETPERF_HOME/script/profile.sh >> ~/.bash_profile

cpanm と、Perl ライブラリをインストールします

::

    sudo -E yum -y install perl-devel
    curl -L http://cpanmin.us | perl - --sudo App::cpanminus
    cd $GETPERF_HOME
    sudo -E cpanm --installdeps --notest .

.. note::

  -  Perl ライブラリのroot管理下への配置について

    /usr/share/perl5　など、 root 管理下のディレクトリにライブラリをインストールします。
    そのため、インストールコマンドは、全てsudo 権限で実行するか、--sudo　オプションをつけて実行してください。

  -  cpanm コマンドエラーについて

    cpanm コマンド実行時に 「Installing the dependencies failed:」のライブラリの依存エラーが出た場合は、
    前述のyumのパッケージインストールでPerlライブラリを手動でインストールしてください。
    試行錯誤的な作業が必要となる場合がありますが、cpanm で以下のメッセージが出力されれば完了となります。

    ::

        --> Working on .
        Configuring Getperf-0.01 ... OK
        <== Installed dependencies for .. Finishing.
