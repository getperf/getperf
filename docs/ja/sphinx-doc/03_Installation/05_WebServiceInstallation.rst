Webサービスインストール
=======================

監視エージェント通信用 Web サービスのインストールを行います。

.. データ集計サービスの起動停止スクリプト /etc/init.d/sumupctl を登録します。

.. ::

..     sudo -E rex install_sumupctl

.. データ集計サービスのモニタースクリプトを cron に登録します。
.. 以下 Rex コマンドで cron 登録をします。

.. ::

.. 	sudo -E rex run_monitor_sumup

事前準備
--------

Webサービスのインストールで、Java ビルドツール Gradle, Apache Ant を使用します。
前頁にインストール手順の記載がありますので、事前にインストールしてください。


必要なパッケージのインストール
------------------------------

openssl-devel等のパッケージインストール
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
以下のコマンドで yum インストールします。

::

   sudo -E yum install openssl-devel redhat-lsb-core expat-devel

.. apr、apr-utilのインストール
.. ^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. apr、apr-util の最新版(例：apr-1.7.4.tar.gz、apr-util-1.6.3.tar.gz)を以下からダウンロードします。

.. http://apr.apache.org/download.cgi

.. apr をインストールします。

.. ::

..    tar xvfz apr-x.x.x.tar.gz
..    cd apr-x.x.x/
..    ./configure
..    make
..    sudo make install

.. apr-util をインストールします。

.. ::

..    tar xvfz apr-util-x.x.x.tar.gz
..    cd apr-util-x.x.x/
..    ./configure --with-apr=/usr/local/apr --with-expat=/usr/lib64
..    make
..    sudo make install


.. pcre のインストール
.. ^^^^^^^^^^^^^^^^^^^
.. pcre の最新版(例：pcre-8.45.zip)を以下からダウンロードします。

.. https://ja.osdn.net/projects/sfnet_pcre/releases/

.. pcre をインストールします。

.. ::

..    unzip pcre-x.x
..    cd pcre-x.x/
..    ./configure
..    make
..    sudo make install


.. nghttp2 のインストール
.. ^^^^^^^^^^^^^^^^^^^^^^
.. nghttp2 の最新版(例：nghttp2-1.52.0.tar.gz)を以下からダウンロードします。

.. https://github.com/nghttp2/nghttp2

.. nghttp2 をインストールします。

.. ::

..    tar xvfz nghttp2-x.x.x
..    cd nghttp2-x.x.x/
..    ./configure
..    make
..    sudo make install
..    echo /usr/local/lib >> /etc/ld.so.conf
   .. sudo ldconfig


Apacheインストール
------------------

Apache HTTP サーバのソースをダウンロードして、/usr/local の下にインストールします。管理用とデータ受信用の2つのインスタンスをインストールし、
それぞれ、/usr/local/apache-admin　と　/usr/local/apache-data のホームディレクトリにインストールします。

* 管理用の場合、57443 ポートでサー
バ証明書を使用します
* データ用の場合、 58443 ポートで各監視対象で発行したクライアント証明書を使用します

rex コマンドを用いてインストールします。
Apache バージョンは、2.4 系の最新をダウンロードサイトから検出してインストールします

.. .. note::

..    セットアップスクリプトでApache 2.2系のダウンロードに失敗する場合があります。
..    その場合は以下の手順で手動ダウンロードして、アーカイブを解凍した後に
..    セットアップスクリプトを実行してください。

..    ::

..       cd /tmp/rex
..       wget https://archive.apache.org/dist/httpd/httpd-2.2.34.tar.gz
..       tar xvf httpd-2.2.34.tar.gz

..    Rexfile のバージョン指定を、 32 から 34 に変更

..    ::

..       cd ~/getperf
..       vi Rexfile

..    ::

..       task "prepare_apache", sub {
..         my $version = '2.2.34';
..         my $module  = 'httpd-2.2.34';
..         my $archive = "${module}.tar.gz";
..         my $download = 'http://ftp.riken.jp/net/apache//httpd/httpd-2.2.34.tar.gz';

.. .. note::

..    RHEL8 の場合、OpenSSL1.0 共有ライブラリをインストールする

..    ::

..       mkdir -p ~/work/sfw; cd ~/work/sfw
..       wget https://ftp.openssl.org/source/old/1.0.2/openssl-1.0.2u.tar.gz
..       https://www.openssl.org/source/openssl-1.1.1k.tar.gz
..       tar xvfz openssl-1.0.2u.tar.gz
..       cd openssl-1.0.2u
..       ./config shared
..       make
..       sudo make install
..       sudo vi /etc/ld.so.conf
..       # 最終行に以下を追加
..       /usr/local/ssl/lib

..       sudo /sbin/ldconfig

..    Rexfile のapache configure コマンドのオプションにsslホームを指定

..    ::
   
..       --with-ssl=/usr/local/ssl


error: Bundled APR requested but not found at 
./srclib/. Download and unpack the corresponding apr and apr-util packages to ./srclib/.



sudo -E yum -y install apr-devel apr-util  apr-util-devel

::

   # Getperfホームディレクトリに移動し、Apache インストールコマンドを実行します。
   cd ~/getperf
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

上記はルート証明書を指定して、管理用 Apache に接続します。
実行後、以下のような 57443... connected がでれば OK です。
その後に 503 エラーが出ていても無視して OK です。

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

上記はルート証明書、クライアント証明書、クライアント鍵を指定して、
データ用 Apache に接続します。
実行後、以下のような 58443... connected がでれば OK です。
その後に 503 エラーが出ていても無視して OK です。

::

   Connecting to 192.168.41.199:58443... connected.


Tomcatインストール
------------------

Tomcat Webコンテナをダウンロードして、/usr/local の下にインストールします。
Apache と同様に、管理用とデータ受信用で、それぞれ、/usr/local/tomcat-admin と
/usr/local/tomcat-data のホームディレクトにインストールします。


::

   # Getperfホームディレクトリに移動し、Tomcat インストールコマンドを実行します。
   cd ~/getperf
   sudo -E rex prepare_tomcat

Tomcat バージョンは 8.5 系の最新をダウンロードサイトから検出してインストールします

.. .. note::

..    Tomcat AJP の設定が有効にならないので手動で変える。
..    通信暗号化が既定では有効のため、secretRequired を無効にします。
..    "Define an AJP 1.3 Connector on port" のコメント行の後ろに
..    以下を追加します。

..    * tomcat-data

..    ::

..       vi /usr/local/tomcat-data/conf/server.xml

..    ::

..       <!-- Define an AJP 1.3 Connector on port 8009 -->
..       <Connector protocol="AJP/1.3"
..                  address="::1"
..                  port="58009"
..                  redirectPort="58443" secretRequired="false" />

..    * tomcat-admin

..    ::

..       vi /usr/local/tomcat-admin/conf/server.xml

..    ::

..       <!-- Define an AJP 1.3 Connector on port 8009 -->
..       <Connector protocol="AJP/1.3"
..                  address="::1"
..                  port="57009"
..                  redirectPort="57443" secretRequired="false" />

Webサービスインストール
-----------------------

Webサービスエンジンの Apache Axis2 をダウンロードして、Tomcat Web コンテナにデプロイ(インストール)します。

::

    rex prepare_tomcat_lib

デプロイ処理は最後に、Apache, Tomcat プロセスの再起動を行います。
サービス再起動時のサービス停止エラーが発生する場合がありますが、本エラーは無視して
構いません。

デプロイに成功すると、Web ブラウザから Axis2 の管理画面へのアクセスが可能となります。

-  Axis2 管理用 http://{監視サーバIPアドレス}:57000/axis2/
-  Axis2 データ受信用 http://{監視サーバIPアドレス}:58000/axis2/


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
管理画面の Services メニューを選択し、GetperfService　を選択します。選択するとWSDL(XML形式のWebサービスの定義情報)が表示されます。

.. .. note::

..    2020/12 に以下の課題を解消しました。

..    現在、デプロイした getperf-ws-1.0.0.jar は、Axis2 のサービス登録で
..    エラーが発生します。
..    別サイトから jarファイルをアップロードしてtomcatを再起動します。

..    ::

..       # 旧サイトから、getperf-ws-1.0.0.jar ファイルを/tmpにコピー
..       cp /tmp/getperf-ws-1.0.0.jar \
..       /usr/local/tomcat-data/webapps/axis2/WEB-INF/services/getperf-ws-1.0.0.jar
..       cp /tmp/getperf-ws-1.0.0.jar \
..       /usr/local/tomcat-admin/webapps/axis2/WEB-INF/services/getperf-ws-1.0.0.jar

..    ::

..       cd $HOME/getperf
..       sudo rex restart_ws_admin
..       sudo rex restart_ws_data
