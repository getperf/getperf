Webサービスインストール
=======================

エージェント Web サービスのインストールを行います。 はじめにyum を用いて gcc,JDK等の開発環境、Apache、PHP 
をインストールします。また、Javaプログラムのビルドツール Apache Antと、Gradleをインストールします

::

    sudo -E rex install_package

.. note::

   "The requested URL returned error: 404 Not Found" エラーが発生する場合、
110   yum リポジトリの競合が発生している可能性が有ります。その場合、
   sudo yum clean all を実行してから再度実行してみてください。

データ集計サービスの起動停止スクリプト /etc/init.d/sumupctl を登録します。

::

    sudo -E rex install_sumupctl

データ集計サービスのモニタースクリプトを cron に登録します。

.. note::

   前述のSSLの Cron 設定と同様に、Rex の不具合により、root の
   Cron 登録がない状態で Cron 登録コマンドを実行すると、エラーで登録に失敗します。
   ワークアラウンドとして事前に以下の手順で空の Cron を登録してください。

   ::

      sudo su -
      # root にスイッチユーザ

   ::

      EDITOR=vi crontab -e
      # 改行を追加して、Cron設定を終了する。

以下 Rex コマンドで cron 登録をします。

::

	sudo -E rex run_monitor_sumup

Apacheインストール
------------------

Apache HTTP サーバのソースをダウンロードして、/usr/local の下にインストールします。管理用とデータ受信用の2つのインスタンスをインストールし、
それぞれ、/usr/local/apache-admin　と　/usr/local/apache-data のホームディレクトリにインストールします。

::

    sudo -E rex prepare_apache

Apache バージョンは、2.2 系の最新をダウンロードサイトから検出してインストールします

Tomcatインストール
------------------

Tomcat Webコンテナをダウンロードして、/usr/local の下にインストールします。
Apache と同様に、管理用とデータ受信用で、それぞれ、/usr/local/tomcat-admin と
/usr/local/tomcat-data のホームディレクトにインストールします。

::

    sudo -E rex prepare_tomcat

Tomcat バージョンは 7.0 系の最新をダウンロードサイトから検出してインストールします

Webサービスインストール
-----------------------

Webサービスエンジンの Apache Axis2 をダウンロードして、Tomcat Web コンテナにデプロイ(インストール)します。

::

    rex prepare_tomcat_lib

デプロイ処理は最後に、Apache, Tomcat プロセスの再起動を行います。
サービス再起動時のサービス停止エラーが発生する場合がありますが、本エラーは無視して構いません。デプロイに成功すると、Web
ブラウザから Axis2 の管理画面へのアクセスが可能となります。

-  Axis2 管理用 http://{監視サーバのIPアドレス}:57000/axis2/
-  Axis2 データ受信用 http://{監視サーバのIPアドレス}:58000/axis2/

Axis2 管理画面のアクセスが確認できたら、Getperf Web サービスを Axis2 にデプロイします。

::

    rex prepare_ws

デプロイに成功すると、前述の Axis2 管理画面のメニューからWebサービスの確認ができます。
管理画面の Services メニューを選択し、GetperfService　を選択します。選択するとWSDL(Webサービスの定義情報)が表示されます。
