Rsync セットアップ
==================

エージェントの採取データを Cacti サイトにデータ転送（フォワード）する設定をします。

1. RSync サービスを用いて監視エージェントからのデータを受信できる様にします。
2. 同サーバにて RSync コマンドを用いて、データを受信し、グラフ用データの集計が
   できるようにします。

.. note::

    HA構成にする場合に、本設定のデータ受信の処理を 2台のサーバで冗長化します。
    詳細は、 :doc:`../../08_HAClustering/index` を確認してください。

また、確認用にLinux監視テンプレートを用いて、監視サーバ自身の監視設定を行います。

1. 監視サーバ上に Cacti 監視エージェントをセットアップして自身を監視します。
2. テスト用の監視サイトを作成し、Rsync を用いて監視エージェントからのデータ転送を設定します。


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

集計モジュールと互換性維持のため、 Perl 環境管理ツール plenv を使用して、 
Perl 5.16.3 をインストールします。

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

この後、RSync の設定を行います。設定は Cacti 監視サイトを構築し、
構築したディレクトリ下でデータ受信ができるように設定します。
ここでは、自身の Linux サーバの監視サイトを構築してデータ受信ができるよう設定します。


