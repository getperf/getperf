基本パッケージのインストール
============================

はじめに基本パッケージをインストールします。管理ユーザで **sudo -E yum**
コマンドでインストールします。-E は sudo ユーザの環境変数を読みこむオプションで、前節で設定したプロキシー設定を有効にするために必要になります。

.. note::

    RHEL 環境の場合、サブスクリプション登録が必要になります。

    ::

        # サブスクリプション登録の確認
        sudo subscription-manager list

        # サブスクリプション登録。事前に Red Hatアカウントの登録が必要。
        sudo subscription-manager register

        # 登録後、利用なサブスクリプションリストを表示し、プールIDを確認
        sudo subscription-manager list --available

        # プールIDを指定してサブスクリプションを有効化
        sudo subscription-manager subscribe --pool={プールID}


::

    sudo -E yum -y groupinstall "Development Tools"
    sudo -E yum -y install kernel-devel kernel-headers
    sudo -E yum -y install expat expat-devel libxml2-devel
    sudo -E yum -y install perl-XML-Parser perl-XML-Simple
    sudo -E yum -y update

Getperf モジュールのダウンロードと解凍
--------------------------------------

git コマンドを使ってモジュールをダウンロードします。

::

    cd $HOME
    git clone https://github.com/getperf/getperf.git

Perlライブラリのインストール
----------------------------

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

.. note:: Perl ライブラリは /usr/share/perl5　など、 root 管理下のディレクトリにライブラリをインストールします。
    そのため、インストールコマンドは、全てsudo 権限で実行するか、--sudo　オプションをつけて実行してください。

.. note:: cpanm コマンド実行時に 「Installing the dependencies failed:」のライブラリの依存エラーが出た場合は、
    前述のyumのパッケージインストールでPerlライブラリを手動でインストールしてください。
    試行錯誤的な作業が必要となる場合がありますが、cpanm で以下のメッセージが出力されれば完了となります。

    ::

        --> Working on .
        Configuring Getperf-0.01 ... OK
        <== Installed dependencies for .. Finishing.
