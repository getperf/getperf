Getperf 管理コマンドについて
============================

Getperf
は管理ユーザ用に幾つかのコマンドを用意しています。本章ではこれらコマンドの使用方法を説明します。

-  サイトの初期化(initsite)
-  サイトデータ集計(sumup)
-  監視対象のリモート操作(nodeconfig)

Cactiのグラフ登録コマンド cacti-cli については :doc:`../06_MonitoringCustomize/02_CactiGraphRegistration/index` にて、
Zabbixの監視登録コマンド zabbix-cli については :doc:`../06_MonitoringCustomize/03_ZabbixRegistration/index` にて説明します。

サイトの初期化(initsite)
===========================

使用方法
--------

指定したディレクトリに監視サイトを作成します。ディレクトリは未作成の状態で実行する必要があります。指定したディレクトリの末端のディレクトリがサイトキーとなり、一意のサイトを示すキー情報になります。

::

  Usage : initsite {site_dir}
          [--update] [--drop] [--template] [--force] [--disable-git-clone] [--mysql-passwd=s]
          [--addsite="AAA,BBB"]

  initsite ~/work/site1

処理フロー
----------

サイト初期化は以下の処理を行います。

1. ディレクトリ作成

  指定したディレクトリの下に以下のファイル、ディレクトリを作成します。

  ===================== ======================================
  パス                    用途
  ===================== ======================================
  Rexfile               監視対象操作用のRexスクリプト 
  analysis              受信データディレクトリ
  html                  Cacitサイトホーム 
  lib                   集計定義、グラフ定義ディレクトリ 
  node                  ノード定義ディレクトリ
  script                監視対象操作用スクリプトディレクトリ 
  storage               蓄積データディレクトリ
  summary               集計データディレクトリ
  view                  ビュー定義ディレクトリ
  ===================== ======================================

  .. note::

    既にパスが存在する場合は処理をスキップします。

2. 集計定義作成

   集計定義を lib/Getperf の下に、グラフ定義を lib/graph の下にコピーします。コピーする集計定義、グラフ定義は Linux, Windows のリソース監視用のテンプレート名のディレクトリの下にコピーします。

3. Cacti用DB作成

   MySQL に Cacti リポジトリデータベースを作成します。データベース名はサイトキーとなります。Linux, Windows のリソース監視テンプレートを登録したデータベースをインポートします。既に存在する場合はスキップします。

4. Cacti用Apache設定

   Apache HTTPサーバにCactiサイトホームをリンクします。URL は 'http://{監視サーバアドレス}/{サイトキー}' となります。

5. Gitリポジトリ作成

   Gitリポジトリを作成します。別のサーバに作成したサイトの複製をする場合、以下の git clone コマンドを実行します。

   ::

       git clone ssh://{管理ユーザ}@{監視サーバアドレス}/{GETPERF_HOME}/var/site/{サイトキー}.git

6. サイト情報出力

  初期化したサイトのサイトキー、パスワード、Cacti URL、git clone コマンドを表示します。

オプション
----------

--update
~~~~~~~~

git clone でコピーしたサイトで Cacti 用 MySQL データベース、Webサーバ、Webサービスの登録をします。実行後、 コピーしたサイトの Cacti コンソールへのアクセスが可能となります。

--template
~~~~~~~~~~

git clone でコピーしたテンプレート用サイトで --update と同様の処理を行います。--addsite オプションのサイトの追加処理を行いません。

--force
~~~~~~~

既定の処理は既にファイルがある場合はスキップする処理となりますが、--force オプションを付けるとスキップせずに上書きします。

.. note::

  既存のCacti 用 MySQL データベースがある場合は削除し、再作成します。バックアップをするなど注意してください。

--disable-git-clone
~~~~~~~~~~~~~~~~~~~

Git リポジトリを作成しません。

--mysql-passwd=s
~~~~~~~~~~~~~~~~

Cacti 用 MySQL データベースのパスワードを指定します。

--addsite
~~~~~~~~~

監視サイト作成時にサイトキーを複数追加します。--addsite で指定された値が追加するサイトキーのリストとなります。既設の複数の監視サイトを新たに1つのサイトにまとめて構築する場合に使用します。

--drop
~~~~~~

指定したサイトを削除します。
