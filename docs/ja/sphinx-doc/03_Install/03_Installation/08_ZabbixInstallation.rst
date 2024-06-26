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

.. note::

    以下設定は監視エージェントのビルド作業で必要な内容となります。
    既にビルド済みの監視エージェントを使用する場合は、本設定はスキップしてください。
    詳細は、 :doc:`../04_Getperf2Agent/index` を参照してください。

getperf_zabbix.json 設定ファイルを編集します。

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
