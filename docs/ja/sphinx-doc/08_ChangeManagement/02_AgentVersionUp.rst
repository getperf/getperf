エージェントのバージョンアップ
==============================

エージェントのバージョン管理はビルド番号をベースにしています。
エージェントのセットアップコマンドで、監視サーバから新バージョンをダウンロードする機能があります。
その手順は以下の通りです。

事前準備
--------

監視サーバに最新のコンパイル済みエージェントパッケージを用意します。

`エージェントコンパイル手順 <docs/ja/docs/03_Installation/10_AgentCompile.md>`_ に従って、各プラットフォームの最新のエージェントモジュールを用意してください。
アップデートファイルは$GETPERF_HOME/var/argent/updateの下に配布します。

**例: CentOS6(64bit版)のアップデートファイルの確認**

::

   cd $GETPERF_HOME
   find var/docs/agent/update/CentOS6-x86_64/ -type f
   var/agent/update/CentOS6-x86_64/2/5/getperf-bin-CentOS6-x86_64-5.zip
   var/agent/update/CentOS6-x86_64/2/4/getperf-bin-CentOS6-x86_64-4.zip

.. note:: エージェントモジュールは各プラットフォーム、アーキテクチャごとに用意する必要が有ります。

エージェントのバージョンアップ手順
----------------------------------

以降の作業はエージェント側で実施します。
一旦、エージェントを停止します。

::

   ~/ptune/bin/getperfctl stop

現バージョンを確認します。1行目のタイトルでビルド番号を確認します。
例 : GETPERF Agent v2.7.3 (build 4)

::

   ~/ptune/bin/getperfctl -v

セットアップコマンドを実行します。

::

    ~/ptune/bin/getperfctl setup

最新のビルドがある場合は以下のアップデートのメッセージが表示されます。

::

    最新のgetperfが存在します[現ビルド : 4 < 5]
    モジュールをアップデートしますか(y/n) ?:

'y'を入力して最新モジュールをダウンロードし、出力されたメッセージの手順に従いモジュールを解凍します。

::

    cd ~/ptune
    unzip ~/ptune/_wk/getperf-bin-CentOS6-x86_64-5.zip

getperfctl -v でビルド番号が更新されていることを確認したら、エージェントを開始します。

::

    ~/ptune/bin/getperfctl start

