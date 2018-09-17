Webサービスインストール
=======================

エージェント Web サービスのインストールを行います。

データ集計サービスの起動停止スクリプト /etc/init.d/sumupctl を登録します。

::

    sudo -E rex install_sumupctl

データ集計サービスのモニタースクリプトを cron に登録します。
以下 Rex コマンドで cron 登録をします。

::

	sudo -E rex run_monitor_sumup

Apacheインストール
------------------

Apache HTTP サーバのソースをダウンロードして、/usr/local の下にインストールします。管理用とデータ受信用の2つのインスタンスをインストールし、
それぞれ、/usr/local/apache-admin　と　/usr/local/apache-data のホームディレクトリにインストールします。

Apache バージョンは、2.2 系の最新をダウンロードサイトから検出してインストールします

.. note::

   セットアップスクリプトでApache 2.2系のダウンロードに失敗する場合があります。
   その場合は以下の手順で手動ダウンロードして、アーカイブを解凍した後に
   セットアップスクリプトを実行してください。

   ::

      cd /tmp/rex
      wget https://archive.apache.org/dist/httpd/httpd-2.2.29.tar.gz 
      tar xvf httpd-2.2.29.tar.gz
      cd ~/getperf

::

    sudo -E rex prepare_apache

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
