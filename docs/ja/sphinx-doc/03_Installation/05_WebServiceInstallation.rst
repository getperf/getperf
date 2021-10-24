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
      wget https://archive.apache.org/dist/httpd/httpd-2.2.34.tar.gz
      tar xvf httpd-2.2.34.tar.gz

   Rexfile のバージョン指定を、 32 から 34 に変更

   ::

      cd ~/getperf
      vi Rexfile

   ::

      task "prepare_apache", sub {
        my $version = '2.2.34';
        my $module  = 'httpd-2.2.34';
        my $archive = "${module}.tar.gz";
        my $download = 'http://ftp.riken.jp/net/apache//httpd/httpd-2.2.34.tar.gz';

.. note::

   RHEL8 の場合、OpenSSL1.0 共有ライブラリをインストールする

   ::

      mkdir -p ~/work/sfw; cd ~/work/sfw
      wget https://ftp.openssl.org/source/old/1.0.2/openssl-1.0.2u.tar.gz
      https://www.openssl.org/source/openssl-1.1.1k.tar.gz
      tar xvfz openssl-1.0.2u.tar.gz
      cd openssl-1.0.2u
      ./config shared
      make
      sudo make install
      sudo vi /etc/ld.so.conf
      # 最終行に以下を追加
      /usr/local/ssl/lib

      sudo /sbin/ldconfig

   Rexfile のapache configure コマンドのオプションにsslホームを指定

   ::
   
      --with-ssl=/usr/local/ssl

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

.. note::

   Tomcat AJP の設定が有効にならないので手動で変える。
   通信暗号化が既定では有効のため、secretRequired を無効にします。
   "Define an AJP 1.3 Connector on port" のコメント行の後ろに
   以下を追加します。

   * tomcat-data

   ::

      vi /usr/local/tomcat-data/conf/server.xml

   ::

      <!-- Define an AJP 1.3 Connector on port 8009 -->
      <Connector protocol="AJP/1.3"
                 address="::1"
                 port="58009"
                 redirectPort="58443" secretRequired="false" />

   * tomcat-admin

   ::

      vi /usr/local/tomcat-admin/conf/server.xml

   ::

      <!-- Define an AJP 1.3 Connector on port 8009 -->
      <Connector protocol="AJP/1.3"
                 address="::1"
                 port="57009"
                 redirectPort="57443" secretRequired="false" />

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

.. note::

   2020/12 に以下の課題を解消しました。

   現在、デプロイした getperf-ws-1.0.0.jar は、Axis2 のサービス登録で
   エラーが発生します。
   別サイトから jarファイルをアップロードしてtomcatを再起動します。

   ::

      # 旧サイトから、getperf-ws-1.0.0.jar ファイルを/tmpにコピー
      cp /tmp/getperf-ws-1.0.0.jar \
      /usr/local/tomcat-data/webapps/axis2/WEB-INF/services/getperf-ws-1.0.0.jar
      cp /tmp/getperf-ws-1.0.0.jar \
      /usr/local/tomcat-admin/webapps/axis2/WEB-INF/services/getperf-ws-1.0.0.jar

   ::

      cd $HOME/getperf
      sudo rex restart_ws_admin
      sudo rex restart_ws_data
