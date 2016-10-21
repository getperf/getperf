JavaVM監視設定
==============

* Linux, Windows サーバ上で稼働する JavaVM インスタンスのヒープメモリ使用率、GC統計情報を採取します。
* Java 1.5 以上をサポートします。
* [jstat API](https://docs.oracle.com/javase/jp/6/technotes/tools/share/jstat.html) を使用して情報採取をします。

監視仕様は以下の通りです。

   +------------------------+------------------------------------------+
   | Key                    | Description                              |
   +========================+==========================================+
   | **パフォーマンス統計** | **Cacti JavaVMグラフ**                   |
   +------------------------+------------------------------------------+
   | jstat                  | Javaヒープ使用量 / GC 回数 / GC ビジー率 |
   +------------------------+------------------------------------------+

.. note::

   JavaVM監視は標準テンプレートではないため、監視サイトにテンプレートをインストールしていない場合は、
   次のセクションでテンプレートのインストールをしてください。
   すでにインストール済みの場合はスキップしてエージェント設定に進んでください。

Jvmstatテンプレートのインストール
---------------------------------

Jvmstat テンプレートのビルド
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

以降の作業は監視サーバ側で行います。
ある作業ディレクトリに移動して Git Hub からプロジェクトをクローンします。

::

   cd ~/work
   git clone https://github.com/getperf/t_Jvmstat.git

プロジェクトディレクトリに移動して、--template オプション付きでサイトの初期化をします。

::

   cd t_Jvmstat
   initsite --template .

Cacti グラフテンプレート作成スクリプトを順に実行します。

::

   ./script/create_graph_template__Jvmstat.sh

Cacti グラフテンプレートをファイルにエクスポートします。

::

   cacti-cli --export Jvmstat

集計スクリプト、グラフ登録ルール、Cactiグラフテンプレートエクスポートファイル一式をアーカイブします。

::

   mkdir -p $GETPERF_HOME/var/template/archive
   sumup --export=Jvmstat --archive=$GETPERF_HOME/var/template/archive/config-Jvmstat.tar.gz

Jvmstat テンプレートのインポート
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

前述で作成した $GETPERF_HOME/var/template/archive/config-Jvmstat.tar.gz がJvmstatテンプレートのアーカイブとなり、
サイトホームディレクトリ下に解凍して使用します。

::

   cd {モニタリングサイトホーム}
   tar xvf $GETPERF_HOME/var/template/archive/config-Jvmstat.tar.gz

Cacti グラフテンプレートをインポートします。

::

   cacti-cli --import Jvmstat

インポートした集計スクリプトを反映するため、集計デーモンを再起動します。

::

   sumup restart

jstatmコンパイル
~~~~~~~~~~~~~~~~

jvmstat API を用いた、Java アプリを使用します。Java 実行環境に応じて、Javaアプリをコンパイルしてください。

::

    cd lib/agent/Jvmstat/src/jstat
    ant

BUILD SUCCESSFUL と出力されればOKです。
作成したjarファイル、スクリプトを、エージェントの script の下にコピーします。

::

   cp -r dest/* ../../script/

コンパイルの詳細は、jstatm ソースディレクトリ下の README.md を参照してください。

エージェント設定
----------------

Linux セットアップ
~~~~~~~~~~~~~~~~~~

以下のエージェント採取設定ファイルを監視対象サーバにコピーして、エージェントを再起動してください。

::

   cd {サイトホーム}/lib/agent/Jvmstat/
   scp -rp * {監視対象サーバユーザ}@{監視対象サーバ}@~/ptune/

採取スクリプトjstatm.sh 内の JAVA_HOME 環境変数の設定を編集します。実行環境に合わせてパスをしてください。

script/jstatm.sh　スクリプト内の以下の行を編集します。

::

   grep JAVA_HOME= ~/ptune/script/jstatm.sh
   JAVA_HOME=/usr/lib/jvm/java; export JAVA_HOME

jstatm.sh の起動確認をします。

::

   cd ~/ptune/script
   jstatm.sh -h

"usage: ..."と出力されればOKです。

.. note:: jstatm.sh は tools.jar を参照します。$JAVA_HOME/lib に tools.jar があることを確認してください。

設定を反映するためエージェントを再起動します。

::

   ~/ptune/bin/getperfctl stop
   ~/ptune/bin/getperfctl start

起動後、~/ptune/log/Jvmstat/下に採取データが保存されいるか、~/ptune/_log/getperf.log にエラーがないかを確認します。
問題なければ採取が完了するまでしばらく待ちます。
実行周期は5分間となるため、5分間後に監視サーバ側のカスタマイズ作業を行います。

.. note::

   * 監視対象のJavaインスタンスの実行ユーザとエージェントの実行ユーザは同一にする必要が有ります。
   * また、監視対象のJavaインスタンスとjstatmのJavaバージョンも同じにする必要があります。

Windows セットアップ
~~~~~~~~~~~~~~~~~~~~

Linux と同様に、{サイトホーム}/lib/agent/Jvmstat/　下のファイル一式を、エージェントの c:\ptune下にコピーしてください。
script/jstatm.bat　スクリプト内の以下の行を編集します。

::

   grep JAVA_HOME= ~/ptune/script/jstatm.bat
   set JAVA_HOME=C:\jdk1.7.0_79

設定を反映するためエージェントを再起動します。

::

   c:\ptune\bin\getperfctl stop
   c:\ptune\bin\getperfctl start

起動後、c:/ptune/log/Jvmstat/下に採取データが保存されいるか、c:/ptune/_log/getperf.log にエラーがないかを確認します。
問題なければ採取が完了するまでしばらく待ちます。Linux と同様に実行周期は5分間となります。

.. note::

   監視対象のJavaインスタンスはサービス起動とし、システムユーザの実行ユーザにする必要があります。また、Javaバージョンは同じにする必要があります。

データ集計のカスタマイズ
------------------------

以降の作業は監視サーバ側で行います。
監視サーバに psadmin ユーザでssh接続し、サイトホームディレクトリに移動します。

::

   cd {サイトホーム}


上記エージェントセットアップ後、データ集計が実行されると、サイトホームディレクトリの lib/Getperf/Command/Master/ の下に Jvmstat.pm ファイルが生成されます。
本ファイルは監視対象のJava VM インスタンスのマスター定義ファイルで、Java VMインスタンス の用途を記述します。
同ディレクトリ下の Jvmstat.pm_sample を例にカスタマイズしてください。
カスタマイズ内容の動作確認は、sumup -l コマンドを使用します。

::

   sumup -l analysis/{監視対象サーバ}/Jvmstat/

実行後、node/Jvmstat/{監視対象サーバ}/device/jstat.json にノード定義ファイルが生成されます。

::

   cat node/Jvmstat/{監視対象サーバ}/device/jstat.json

以下は監視サーバのTomcatサーブレットエンジンのJavaインスタンスのノード定義となります。

.. code-block:: javascript

   {
      "device_texts" : [
         "Apache Tomcat - /usr/local/tomcat-data",
         "Apache Tomcat - /usr/local/tomcat-admin"
      ],
      "devices" : [
         "tomcat.UsrLocalTomcatData",
         "tomcat.UsrLocalTomcatAdmin"
      ],
      "rrd" : "Jvmstat/ostrich/device/jstat__*.rrd"
   }

グラフ登録
----------

上記エージェントセットアップ後、データ集計が実行されると、サイトホームディレクトリの node の下にノード定義ファイルが出力されます。
出力されたファイル若しくはディレクトリを指定してcacti-cli を実行します。

::

   cacti-cli node/Jvmstat/{監視対象サーバ}/ --node-dir {ノードディレクトリ}
