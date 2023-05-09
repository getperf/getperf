Zabbixインストール
==================

.. note::

   Getperf 3.x から、Zabbix サーバ構成スクリプトやインストール手順の
   提供は廃止となりました。
   Zabbix サーバのインストールは個別に実施してください。
   Zabbix エージェントに関しては Cacti エージェントとバンドルさせてインストールする
   オプションを提供しています。その手順を以下に記します。


getperf\_zabbix.json 設定ファイルの編集
---------------------------------------

はじめに、getperf_zabbix.json 設定ファイルを編集します。

::

    cd $GETPERF_HOME
    vi config/getperf_zabbix.json

各設定項目を以下に記します。

.. -  ZABBIX_SERVER_VERSION

..    Zabbix の LTS(Long Term Support)　バージョンである 2.2 系を指定します。既定は、2.2.10 となりますが、マイナーリリースの更新がある場合は上位のバージョンを指定します。バージョンの確認は、以下開発サイトURLのZabbixソースのリストで確認してください。

..    http://www.zabbix.com/jp/download.php (Zabbixソースセクション)

.. .. figure:: ../image/zabbix_url_source.png
..    :align: center
..    :alt: Zabbix Source URL
..    :width: 640px

.. -  ZABBIX_AGENT_VERSION

..    エージェントは 上記 URL のコンパイル済みZabbixエージェントダウンロードからコンパイル済みバイナリをダウンロードします。ダウンロードリストに記載されているバージョンを指定してください。

.. -  DOWNLOAD_AGENT_PLATFORMS

..    Zabbix エージェントは各プラットフォームのバイナリをダウンロードしてインストールします。予め監視対象のプラットフォームのリストを記載します。プラットフォーム名は、`コンパイル済みZabbixエージェント <http://www.zabbix.com/jp/download.php>`_ からダウンロードファイルを選択し、ダウンロードファイル名のリリースバージョンの後ろのサフィックス名を記します。例えば、zabbix_agents_2.2.9.linux2_6.i386.tar.gzは、linux2_6.i386 がプラットフォーム名となります。

-  ZABBIX_SERVER_IP

   Zabbix エージェントの Server パラメータの指定で、Zabbix サーバの IP アドレス、
   ホスト名を指定します。カンマ区切りで複数指定が可能です。

-  ZABBIX_SERVER_ACTIVE_IP

   Zabbix エージェントの ServerActive パラメータの指定で、アクティブチェックで使用する
   Zabbix サーバの IP アドレス、ホスト名を指定します。カンマ区切りで複数指定が可能です。

-  ZABBIX_SERVER_PORT

   Zabbix エージェントの ListenPort パラメータを指定します。

-  ZABBIX_ADMIN_PASSWORD

   Zabbix Web コンソールの管理者ユーザのパスワードを記述します。セキュリティの観点から既定値を変更してください。

-  USE_ZABBIX_MULTI_SITE

   複数の監視サイトを構成し、それぞれの監視サイト毎に Zabbix の監視設定を変えたい場合は   1にしてください。1にした場合、インスタンス内で各監視サイト別にグループ、監視テンプレート、監視アイテムを分けて設定をします。

-  GETPERF_AGENT_USE_ZABBIX

   Zabbix を無効にしたい場合は 0 にしてください。

-  GETPERF_USE_ZABBIX_SEND

   Zabbix Sender を用いて、Cacti 集計データを Zabbix に転送する場合は 1 にしてください。


.. Zabbix インストール
.. -------------------

.. Zabbix サーバ一式のインストールと、エージェント一式のダウンロードをします。Zabbix サーバは開発元が提供するyumリポジトリからインストールをします。

.. .. note::

..    スクリプトの実行で以下の依存パッケージの解決エラーが発生した場合、
..    以下のZabbixサイトから手動インストールをしてください。

..    zabbix-server-mysql-1.8.22-1.el6.x86_64 (epel) 要求: libiksemel.so.3()(64bit)

..    ::

..       mkdir -p work/zabbix
..       cd work/zabbix/
..       wget https://repo.zabbix.com/non-supported/rhel/6/x86_64/iksemel-1.4-2.el6.x86_64.rpm
..       wget https://repo.zabbix.com/non-supported/rhel/6/x86_64/iksemel-devel-1.4-2.el6.x86_64.rpm
..       wget https://repo.zabbix.com/non-supported/rhel/6/x86_64/iksemel-utils-1.4-2.el6.x86_64.rpm
..       sudo -E yum localinstall *.rpm



.. ::

..     sudo -E rex prepare_zabbix

.. エージェントは、設定ファイルに指定したプラットフォームのバイナリを{GETPERF_HOME}/module/getperf-agent/var/zabbix
.. の下にダウンロードします。各ダウンロードファイルのMD5　チェックサム結果がインストールメッセージに出力されるので、上述の開発元ダウンロードサイトのURL の MD5 記述と同じであることを確認してください。

.. .. note::

..   -  MySQL データベース作成エラーについて

..      yum でインストールされた、Zabbix サーバと、getperf_zabbix.json で記載したバージョンが異なる場合に MySQL
..      データベースの作成に失敗する場合が有ります。その場合は以下のインストールディレクトリからバージョンの確認をします。

..      ::

..          ls /usr/share/doc/| grep zabbix
..          zabbix-2.2.10
..          zabbix-server-mysql-2.2.10

..      getperf_zabbix.json の ZABBIX_SERVER_VERSION　に正しいバージョンを指定してください。以下例では2.2.10を指定します。     設定後、以下のコマンドを手動で作成中のデータベース (zabbix)を削除し、インストールスクリプトを再実行することで、データベースの再作成を行います。

..      ::

..          mysqladmin -u root -p drop zabbix
..          sudo script/deploy-zabbix.pl

..      mysql　の root パスワードは config/getperf_site.json の GETPERF_CACTI_MYSQL_ROOT_PASSWD となります。

.. Zabbix の動作確認
.. -----------------

.. インストールが成功すると、 Zabbix サーバプロセスが自動起動されます。以下の確認をします。

.. -  'ps -ef | grep zabbix_server' を実行してプロセスの起動を確認します
.. -  'tail -f /var/log/zabbix/zabbix_server.log' を実行してログを確認します
.. -  Webブラウザから 'http://{監視サーバアドレス}/zabbix/' を開いて管理コンソールログイン画面を確認します
.. -  管理コンソールログイン画面から、ユーザ admin、パスワードは ZABBIX_ADMIN_PASSWORD　を入力してログインします

.. これで Zabbix のインストール作業は完了です。この後の Zabbix の監視設定は、管理コマンド zabbix-cli
.. を用いて行います。zabbix-cli については後述します。

Zabbix エージェントモジュールのダウンロード
-------------------------------------------

以下のパスに Zabbix エージェントモジュールのダウンロードファイルを保存します。
本パスに保存することで、この後のエージェントのコンパイル作業で、各 OS 環境にて
エージェントセットアップを行った差異に対象 OS の Zabbix エージェントをバンドルして、
パッケージングしたモジュールを作成します。

::

   {Getperfホーム}/module/getperf-agent/var/zabbix/

Zabbix エージェントは以下の URL からダウンロードします。

::

   https://www.zabbix.com/jp/download_agents

使用する Zabbix バージョン、エージェントをインストールする対象 OS 、アーキテクチャに合せてダウンロードしてください。

例として、 Zabbix 5.0.34 で、 Linux, Windows の 64ビット版をダウンロードする場合は以下のコマンドを実行します。

::

   # ダウンロードディレクトリに移動
   cd ~/getperf/module/getperf-agent/var/zabbix/
   # Zabbix ダウンロードサイトから確認した、アーカイブ保存URLを指定して、各プラットフォームの Zabbix エージェントをダウンロード
   #  Zabbix 5.0.34 で、 Linux, Windows の 64ビット版をダウンロードする場合は以下のコマンドを実行
   wget https://cdn.zabbix.com/zabbix/binaries/stable/5.0/5.0.34/zabbix_agent-5.0.34-linux-2.6-amd64-static.tar.gz
   wget https://cdn.zabbix.com/zabbix/binaries/stable/5.0/5.0.34/zabbix_agent-5.0.34-linux-3.0-amd64-static.tar.gz
   wget https://cdn.zabbix.com/zabbix/binaries/stable/5.0/5.0.34/zabbix_agent-5.0.34-windows-amd64.zip


この後の作業について
--------------------

以上でベースとなる監視サーバのインストール作業は完了です。
この後の作業は監視対象となるエージェント側のインストールの事前作業となり、監視対象と同じ OS プラットフォーム上で、
エージェントのコンパイルをします。

* エージェントのコンパイル
