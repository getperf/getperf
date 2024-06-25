基本パッケージのインストール
============================

はじめに基本パッケージをインストールします。管理ユーザで **sudo -E yum**
コマンドでインストールします。-E は sudo ユーザの環境変数を読みこむオプションで、
前節で設定したプロキシー設定を有効にするために必要になります。

::

    sudo -E yum -y groupinstall "Development Tools"
    sudo -E yum -y install kernel-devel kernel-headers
    sudo -E yum -y install expat expat-devel libxml2-devel
    sudo -E yum -y install perl-XML-Parser perl-XML-Simple perl-Crypt-SSLeay perl-Net-SSH2
    sudo -E yum -y update

Getperf モジュールのダウンロードと解凍
--------------------------------------

git コマンドを使ってモジュールをダウンロードします。

::

    cd $HOME
    git clone https://github.com/getperf/getperf.git

Getperf のホームディレクトリを GETPERF_HOME 環境変数に設定します

::

    cd ~/getperf
    source script/profile.sh
    echo source $GETPERF_HOME/script/profile.sh >> ~/.bash_profile

Perlライブラリのインストール
----------------------------

Perlライブラリ管理ソフト cpanm を使用します。
cpanm をインストールし、cpanm --installdeps コマンドを用いて必要な Perl
ライブラリをインストールします

cpanm と、Perl ライブラリをインストールします

::

    cd $GETPERF_HOME
    sudo -E yum -y install perl-devel
    curl -L http://cpanmin.us | perl - --sudo App::cpanminus
    sudo -E cpanm --installdeps --notest .

.. note:: Perl ライブラリは /usr/share/perl5 など、 root 管理下のディレクトリにライブラリをインストールします。
    そのため、インストールコマンドは、全てsudo 権限で実行するか、--sudo オプションをつけて実行してください。

.. note:: cpanm コマンド実行時に 「Installing the dependencies failed:」のライブラリの依存エラーが出た場合は、
    yum のパッケージインストールでPerlライブラリを手動でインストールしてください。
    試行錯誤的な作業が必要となる場合がありますが、cpanm で以下のメッセージが出力されれば完了となります。

    ::

        --> Working on .
        Configuring Getperf-0.01 ... OK
        <== Installed dependencies for .. Finishing.


