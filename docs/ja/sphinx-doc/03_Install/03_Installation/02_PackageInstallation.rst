基本パッケージのインストール
============================

はじめに基本パッケージをインストールします。管理ユーザで **sudo -E yum**
コマンドでインストールします。-E は sudo ユーザの環境変数を読みこむオプションで、
前節で設定したプロキシー設定を有効にするために必要になります。

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
    sudo -E yum -y install perl-XML-Parser perl-XML-Simple perl-Crypt-SSLeay perl-Net-SSH2
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
    yum のパッケージインストールでPerlライブラリを手動でインストールしてください。
    試行錯誤的な作業が必要となる場合がありますが、cpanm で以下のメッセージが出力されれば完了となります。

    ::

        --> Working on .
        Configuring Getperf-0.01 ... OK
        <== Installed dependencies for .. Finishing.


Perl5.16.3のインストール
------------------------

Cacti 集計サーバの場合、互換性を維持するために Perl 5.16.3 をインストールします。
Perl 5.16.x を$HOME/.plenv 下にインストールします。

Perl v5.16.3 インストール

::

    git clone https://github.com/tokuhirom/plenv.git ~/.plenv
    git clone https://github.com/tokuhirom/Perl-Build.git ~/.plenv/plugins/perl-build/
    echo 'export PATH="$HOME/.plenv/bin:$PATH"' >> ~/.bash_profile
    echo 'eval "$(plenv init -)"' >> ~/.bash_profile
    exec $SHELL -l

v5.16.3の有効化

::

    plenv install 5.16.3
    plenv global 5.16.3
    plenv local 5.16.3

cpanm と、Perl ライブラリをインストールします

::

    PLENV_INSTALL_CPANM="-v" plenv install-cpanm
    cd $GETPERF_HOME
    cpanm --installdeps --notest .


.. note::

    Perl5.16.3環境での cron 設定

    cron の設定で、インストールパスを有効にするため、コマンド先頭行に以下の設定を追加します。
    各cron の実行コマンドの先頭に、「ource /home/psadmin/.bash_profile && 」を追加します。

    設定例は以下の通りです。

    ::

        15 0 * * * (source /home/psadmin/.bash_profile && perl /home/psadmin/getperf/script/ssladmin.pl update_client_cert > /dev/null 2>&1) &
        0,5,10,15,20,25,30,35,40,45,50,55 * * * * (source /home/psadmin/.bash_profile && /home/psadmin/site/site1/script/cron_sumup.sh) &

