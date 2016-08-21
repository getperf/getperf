Linux 監視
==========

監視対象がLinuxの場合、セットアップは Linux のOS一般ユーザでインストールパッケージを解凍して行います。
インストールパッケージは前章で説明した `エージェントコンパイル <../03_Installation/10_AgentCompile.html>`_ で作成したパッケージで監視対象のOS　メジャーバージョン、アーキテクチャ(32bit,64bitなど)に合わせてパッケージをダウンロードします。ここでは、CentOS6 の 64bit 環境でのエージェントセットアップ手順を記します。

Getperf エージェントセットアップ
--------------------------------

監視対象サーバに一般ユーザでログインします。集計サーバのダウンロードサイトから対象プラットフォームを選択してモジュールをダウンロードします。

::

    wget http://{監視サーバアドレス}/docs/download/getperf-zabbix-Build4-CentOS6-x86_64.tar.gz

パッケージを解凍します。

::

    tar xvf getperf-zabbix-Build4-CentOS6-x86_64.tar.gz

エージェント管理コマンドの getperfctl を使用して、監視サーバとの疎通確認をします。
監視サーバとの通信はクライアント認証型の HTTPS 通信をするため、そのセットアップとして、 クライアント証明書の発行、ダウンロードをします。 getperfctl　setup コマンドで実行します。

::

    ~/ptune/bin/getperfctl setup

実行後、コンソールメッセージが出力され、 'サイトキーを入力して下さい'、'アクセスキーを入力して下さい'　のメッセージは前節で作成したサイトのサイトキー、アクセスキーを入力してください。更新しますかの確認で y を入力して設定を完了します。

以下の通り実行オプションにサイトキーとアクセスコードを付けることも可能です。複数台のセットアップの場合は、本オプションを使用してください。

::

    ~/ptune/bin/getperfctl setup --key={サイトキー} --pass={アクセスキー}

'構成ファイル [network] を更新しました' と出力されたら、HTTPS の設定は完了です。以下コマンドでデーモンを起動してください。

::

    ~/ptune/bin/getperfctl start

サービス起動確認。該当プロセスが存在するか確認します。

::

    ps -ef | grep _getperf

Zabbix エージェントセットアップ
-------------------------------

Zabbix エージェント設定ファイル作成スクリプトを実行します。

::

    ~/ptune/script/zabbix/update_config.sh

本スクリプトは ptune ディレクトリの下に　zabbix_agentd.conf　ファイルを生成します。zabbix_agentd.conf　ファイルは最終行に、監視サーバのアドレスと自身のホスト名を登録します。

以下コマンドで Zabbix エージェントを起動します。

::

    ~/ptune/bin/zabbixagent start

サービス起動確認。該当プロセスが存在するか確認します。

::

    ps -ef | grep zabbix_agent

OS起動時の自動起動設定
----------------------

OS起動時の自動起動設定を行います。本手順は root　ユーザでの実行が必要となります。上記手順で Getperf エージェントと Zabbix　エージェントは起動済みのため、本手順は保留として、この後の設定を継続することも可能です。
root　での作業権限がない場合は以下の作業をシステムオーナに依頼してください。

::

    su - root
    perl (ptune ホームディレクトリ)/bin/install.pl --all

設定内容を確認して、y を入力してください。

.. note::

    Getperf エージェントのみを起動する場合は以下をしてください。

    ::

        perl (ptune ホームディレクトリ)/bin/install.pl --module=getperf

以上でエージェント設定は完了です。この後は集計サーバ側の設定を行います。

.. note::

    手動でのエージェントの起動、停止について

    以下のスクリプトで各エージェントの起動、停止が可能です。インストールで使用したOSユーザで実行してください。

    Getperf エージェントの起動/停止

    ::

        ~/ptune/bin/getperfctl stop     # 停止する場合
        ~/ptune/bin/getperfctl start    # 起動する場合

    Zabbix エージェントの起動/停止

    ::

        ~/ptune/bin/zabbixagent stop    # 停止する場合
        ~/ptune/bin/zabbixagent start   # 起動する場合
