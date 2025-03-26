Webサービスインストール
=======================

監視エージェント通信用 Web サービスのインストールを行います。

事前準備
--------

以下のコマンドで OpenSSL 関連パッケージをインストールします。

::

   sudo -E yum -y install openssl-devel redhat-lsb-core expat-devel

また、APR(Apache Portable Runtime) をインストールします。

::

   sudo -E yum -y install apr-devel apr-util  apr-util-devel

Apacheインストール
------------------

Apache HTTP サーバをソースからコンパイルして、/usr/local の下にインストールします。
管理用とデータ受信用の2つのインスタンスをインストールします。
それぞれ、/usr/local/apache-admin と /usr/local/apache-data のホームディレクトリにインストールします。

* 管理用の場合

   - /usr/local/apache-admin をホームディレクトリとします。
   - 57443 ポートでサーバ証明書を使用したHTTPS 通信設定をします。

* データ用の場合
   
   - /usr/local/apache-data をホームディレクトリとします。
   - 58443 ポートで各監視対象で発行したクライアント証明書を使用した HTTPS 通信設定をします。

rex コマンドを用いてインストールします。

Apache バージョンは、2.4 系の最新をダウンロードサイトから検出してインストールします。

::

   # Getperfホームディレクトリに移動し、Apache インストールコマンドを実行します。
   cd $GETPERF_HOME
   sudo -E rex prepare_apache

Apache サービスを再起動します。

::

   sudo /usr/local/apache-admin/bin/apachectl restart
   sudo /usr/local/apache-data/bin/apachectl restart

Apache インストール後の HTTPS 疎通確認(オプション)
--------------------------------------------------

インストールした Apache で HTTPS の疎通テストを行います。

テスト用クライアント証明書の発行
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

テスト用に証明書発行スクリプト ssladmin.pl を用いて、クライアント
証明書を発行します。以下のコマンドを実行します。

::

   # テスト用の、クライアント 証明書を発行します
   ssladmin.pl client_cert --sitekey=test1 --agent=host1

上記は、 test1 サイトのでホスト名が host1 のクライアント証明書を発行します。
作成された証明書を確認します。

::

   # 証明書発行ディレクトリに移動します。
   # パスは、/etc/getperf/ssl/client/{サイト名}/{ホスト名}/network となり、上記コマンドの場合は以下になります。
   cd /etc/getperf/ssl/client/test1/host1/network

   # 発行された証明書ファイルを確認します
   ls
   License.txt  client.crt  client.key  getperf_ws.ini  zabbix.ini
   ca.crt       client.csr  client.pem  server

上記証明書を使用して、 Apache の HTTPS 疎通確認を行います。

管理用 Apache のHTTPS疎通確認
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

先ほど確認した証明書保存ディレクトリ下で以下のコマンドを実行します。

::

   # 証明書保存ディレクトリに移動し、サーバ認証接続確認のコマンドを実行します
   cd /etc/getperf/ssl/client/test1/host1/network
   wget --no-proxy https://{監視サーバIPアドレス}:57443/ --ca-certificate=ca.crt

ルート証明書を指定して、管理用 Apache に接続します。
この後の Tomcat インストールがまだのため、Tomcat との疎通エラーで 503 エラーが
発生しますが、以下のような 57443... connected がでれば OK です。

::

   Connecting to 192.168.41.199:57443... connected.

データ用 Apache のHTTPS疎通確認
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

同様にクライアント認証接続確認のコマンドを実行します。

::

   # 同様にクライアント認証接続確認のコマンドを実行します
   cd /etc/getperf/ssl/client/test1/host1/network
   wget --no-proxy https://{監視サーバIPアドレス}:58443/ \
   --ca-certificate=ca.crt --certificate=client.pem --private-key=client.key

ルート証明書、クライアント証明書、クライアント鍵を指定して、
データ用 Apache に接続します。
管理用と同様に 58443... connected がでれば OK です。
その後の 503 エラーは無視して問題ありません。

::

   Connecting to 192.168.41.199:58443... connected.


Tomcatインストール
------------------

Tomcat Webコンテナをダウンロードして、/usr/local の下にインストールします。
Apache と同様に、管理用とデータ受信用で、それぞれ、/usr/local/tomcat-admin と
/usr/local/tomcat-data のホームディレクトにインストールします。


::

   # Getperfホームディレクトリに移動し、Tomcat インストールコマンドを実行します。
   cd $GETPERF_HOME
   sudo -E rex prepare_tomcat

Tomcat バージョンは 8.5 系の最新をダウンロードサイトから検出してインストールします


Webサービスインストール
-----------------------

Webサービスエンジンの Apache Axis2 をダウンロードして、Tomcat Web コンテナにデプロイ(インストール)します。

::

   cd $GETPERF_HOME
   rex prepare_tomcat_lib

デプロイ処理は最後に、Apache, Tomcat プロセスの再起動を行います。
サービス再起動時のサービス停止エラーが発生する場合がありますが、本エラーは無視して
構いません。

デプロイに成功すると、Web ブラウザから Axis2 の管理画面へのアクセスが可能となります。

-  Axis2 管理用 http://{監視サーバIPアドレス}:57000/axis2/
-  Axis2 データ受信用 http://{監視サーバIPアドレス}:58000/axis2/

.. note::

   IPv6が無効化設定されている場合、Tomcat の再起動でプロトコルエラーが発生します。
   IPv6 形式の IP アドレスを使用しているためで、以下の設定ファイルを編集して、
   IPv4 形式の IP に修正してください。

   ::

      # 管理用 Tomcat の設定ファイル編集
      vi /usr/local/tomcat-admin/conf/server.xml
      # データ用 Tomcat の設定ファイル編集
      vi /usr/local/tomcat-data/conf/server.xml

   以下の AJP のアクセスの address を修正します。

   ::

         <Connector protocol="AJP/1.3"
               address="127.0.0.1"


Axis2 管理画面のアクセスが確認できたら、Getperf Web サービスをデプロイします。

Axis2 設定ファイルを更新します。

::

    # 管理者用Webサービスの設定
    sudo -E perl $GETPERF_HOME/script/deploy-ws.pl config_axis2 --suffix=admin

    # データ用Webサービスの設定
    sudo -E perl $GETPERF_HOME/script/deploy-ws.pl config_axis2 --suffix=data

Getperf Web サービスをビルドしてデプロイします。

::

    # 管理者用Webサービスのデプロイ
    sh $GETPERF_HOME/script/axis2-install-ws.sh /usr/local/tomcat-admin

    # データ用Webサービスのデプロイ
    sh $GETPERF_HOME/script/axis2-install-ws.sh /usr/local/tomcat-data

設定を反映させるため、Web サービスを再起動します。

::

    cd $GETPERF_HOME
    # 管理者用Webサービスのデプロイ
    rex restart_ws_admin

    # データ用Webサービスのデプロイ
    rex restart_ws_data

デプロイに成功すると、前述の Axis2 管理画面のメニューからWebサービスの確認ができます。
管理画面の Services メニューを選択し、GetperfService を選択します。選択するとWSDL(XML形式のWebサービスの定義情報)が表示されます。

