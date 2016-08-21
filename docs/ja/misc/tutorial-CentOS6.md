Getperf セットアップ手順(CentOS版)
==================================

はじめに
--------

本書は新収集サーバのセットアップ手順書となります。水色にマスクした各モジュールのセットアップを行います。

![system.png](../image/setup_system.png)

** 注意事項 (2015/5) **

* 現在、ベータ版ですべてのモジュールの完成しておらず、暫定的なリリースとなります

### ユーザの設定

本システムは以下の2種類のユーザを想定しています。1はサーバの初期セットアップ時のみ実行するユーザで、2は利用者が監視サイトをメンテナンスするときに都度実行するユーザで、ここでは1の初期セットアップ手順を説明します。2は[Getperfサイトチュートリアル](../tutorial.html)を参照してください。

1. sudoユーザ
新収集サーバの初期セットアップを行う。root権限で以下の作業を行う。
  * 基本パッケージのインストール(MySQL,Apache,PHPなど)
  * Getperf 収集モジュールの初期設定
  * 収集用Webサービスのインストール
2. 運用管理者(利用者)
監視サイトの構築をし、データ収集エージェントの設定、モニタリンググラフの設定を行う。
  * サイトの構築
    * サイトの登録とモニタリンググラフの設定
  * データ収集の設定
    * 監視エージェントのセットアップ

事前準備
--------

### 事前に必要な環境

* sudoユーザの作成
  * 管理用ユーザが必要。ここでは例として pscommon ユーザを変更して sudo コマンドが実行できるようにします

* プロキシー環境の設定(必要な場合)
  * プロキシー設定をして、yumでプロキシー経由でパッケージインストールできるようにします
  * cpanmでプロキシー経由でPerlライブラリをインストール出来る様にします

### sudo ユーザの作成

Getperf管理用ユーザを作成し、root権限を追加します。rootユーザにスイッチユーザして実行してください。

    su
    (rootパスワード入力)

ここでは例としてユーザ名を、 pscommon としていますが適宜変更してください。

    useradd pscommon

パスワードを設定します

    passwd pscommon

visudoで設定ファイルを編集します

    visudo

visudo で /etc/sudousers編集

visudo 編集箇所

Default secure_pathの行を探して行の最後に、/usr/local/bin:/usr/local/sbinを追加します

    Defaults secure_path = /sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin

最終行にユーザ登録の行を追加します

    pscommon        ALL=(ALL)       NOPASSWD: ALL

インストールするApacheプロセスがホームディレクトリ下をアクセスできるよう、ホームディレクトリのアクセス権限を変更します

    su - pscommon
    chmod a+rx $HOME

### プロキシー環境の設定

プロキシー環境の場合、上記で作成したユーザがプロキシー経由でパッケージ管理ソフトを利用できる様に設定をします。以下を参照してください。

[プロキシー環境設定手順](proxy-setup.html)

Getperfモジュールのダウンロード、解凍
-------------------------------------

### GitHub からダウンロード

** <GitHub URL を添付> **

ソースを tar 圧縮する

    cd ~/work/getperf
    git archive --format=tar --prefix=getperf/ HEAD | gzip > ../getperf.tar.gz

zipファイル転送。xxx.xxx.xxx.xxxは構築する収集サーバのアドレスとなります。

    scp ../getperf.tar.gz pscommon@xxx.xxx.xxx.xxx:~/

### 収集サーバ側でのモジュール解凍

管理ユーザで、ソースを$HOMEに解凍します

    cd $HOME
    tar xvf getperf.tar.gz

解凍したディレクトリをGETPERF_HOMEとして環境変数に登録します

    vi ~/.bash_profile

最終行に以下を追加

```
export GETPERF_HOME=$HOME/getperf
export PATH=$GETPERF_HOME/script:$PATH
```

環境変数読込み

```
source ~/.bash_profile
```

### プロキシー環境の設定

プロキシー内環境で利用する場合は、プロキシー経由で各種インストールパッケージがダウンロードできるよう、プロキシーの設定が必要となります。[プロキシー環境設定手順](proxy-setup.html)を参照してください。

RPM基本ソフトのインストール
---------------------------

ここではPerlのパッケージ管理ツールcpanm実行に最低限必要なソフトを手動でインストールします。

### Cコンパイラなど開発環境インストール

```
sudo -E yum groupinstall "Development Tools"
sudo -E yum install kernel-devel kernel-headers
```

ここでパッケージのアップデートを行います

```
sudo -E yum update
```

** トラブルシューティング EPELリポジトリのアップデート **

環境によって、EPELリポジトリのSSL証明書が古く、yum実行時に以下のエラーがでる場合があります。

```
Error: Cannot retrieve metalink for repository: epel. Please verify its path and try again
```

その場合は以下で、リポジトリのアップデートをします。

```
sudo -E yum --disablerepo=epel update nss
```

cpanmのインストール
-------------------

はじめにcpanmをインストールして、Perl ライブラリのインストール環境を構築します。

** 注意 : Perl ライブラリのroot管理下への配置について **

インストールする Perl ライブラリは、管理ユーザと root ユーザで共有します。perlblew などの、ユーザホーム下に Perl ライブラリを配置する方法ではなく、/usr/share/perl5　など、 root 管理下のディレクトリにライブラリをインストールします。そのため、インストールコマンドは、全て sudo 権限で実行するか、--sudoオプションをつけて実行してください。

```
sudo -E yum install perl-devel
curl -L http://cpanmin.us | perl - --sudo App::cpanminus
```

Perl ライブラリのインストール
-----------------------------

各種Perlライブラリをcpanmで一括インストールします。cpanfileに記載されたライブラリを順次インストールします

### 依存ライブラリのインストール

yumで依存ライブラリをインストールします

```
sudo -E yum install libssh2-devel expat expat-devel
```

### cpanmでコンパイルエラーとなるライブラリのパッケージインストール

2015/1/6時点では、Perl ライブラリのバージョン指定が決まっておらず、各種ライブラリのアップデート状況で、以下の依存関係に関するエラーが発生します。

```
Installing the dependencies failed: Module 'XML::Parser' is not installed
Installing the dependencies failed: Module 'IO::Socket::SSL' is not installed, Module 'Crypt::SSLeay' is not installed
```

本回避策として事前にyumからパッケージインストールでライブラリをインストールしてください

```
sudo -E yum -y install perl-XML-Parser perl-XML-Simple perl-Crypt-SSLeay
sudo -E yum -y install perl-Net-SSH2
```

### cpanm実行

cpanm --installdepsオプションでPerlライブラリを一括インストールします

```
cd $GETPERF_HOME
sudo -E cpanm --installdeps .
```

「Installing the dependencies failed:」の依存エラーが出た場合は、前述のyumのパッケージインストールでPerlライブラリをインストールしてください。cpanm実行、依存エラーの解消の繰り返しで、試行錯誤的な作業が必要となる場合がありますが、最終的にcpanm で以下のメッセージが出力されればOKです

```
--> Working on .
Configuring Getperf-0.01 ... OK
<== Installed dependencies for .. Finishing.
```

設定ファイルの生成
------------------

以下で、Getperf設定ファイルのテンプレートを作成します。

```
cd $GETPERF_HOME
perl script/cre_config.pl
```

config/getperf_site.jsonに保存されるので、本ファイルを編集して適宜設定を修正します

```
vi config/getperf_site.json
```

以下はMySQLのrootパスワード設定となり、セキュリティの関係上、別名に変更してください

```
"GETPERF_CACTI_MYSQL_ROOT_PASSWD": "getperf",
```

同様に各種設定ファイルを作成します。

```
vi config/getperf_cacti.json
vi config/getperf_rrd.json
```

** (暫定)rsyncによる旧バージョンサイトとの同期 **

perl script/cre_rsync_config.pl

** (暫定)各設定パラメータの定義表を追加 **

各種M/Wのインストール
---------------------

Perlライブラリのインストールで、Perl製ソフトウェア構成管理ツール rex が利用出来る様になります。これ以降の作業はrexコマンドを使用します。rex -T で各コマンドのヘルプが出ます

```
rex -T
```

実行は「rex {コマンド}」となり、各コマンドの内容は以下の通り。sudo権限が必要な操作は、「sudo rex {コマンド}」となります

|実行コマンド   |sudo| 処理内容 |
|---------------|----|----------|
|install_package|必要|Cコンパイラ、JDK、Apache、PHP、MySQL、Redis等をyumでインストールする|
|prepare_mysql  |----|MySQLのrootパスワードの設定など、mysql_secure_installと同等の処理をする|
|prepare_apache |必要|Apacheをソースからコンパイルして /usr/local 下にインストールする|
|prepare_tomcat |必要|Tomcatバイナリをダウンロードして /usr/local 下にインストールする|
|prepare_tomcat_lib |必要|Webサービス用JavaライブラリをダウンロードしてTomcatホームのlibの下にコピーする。また、Apache Axis2をwebappの下にインストールする|
|prepare_cacti  |----|Cactiバイナリをダウンロードして plugin/cacti 下に配布する|
|prepare_ws      |----|Getperf Webサービスをコンパイルして、Tomcatにデプロイする|
|create_ca      |必要|Getperf Webサービス用SSL自己署名認証局の証明書を発行する|
|cert_server    |必要|Getperf Webサービスのサーバ証明書を発行する|
|svc_start      |必要|各種サービスの起動|
|svc_stop       |必要|各種サービスの停止|
|svc_restart    |必要|各種サービスの再起動
|svc_auto       |必要|各種サービスの自動起動設定|
|restart_ws_admin|必要|管理用Webサービスサービスの再起動|
|restart_ws_data |必要|データ転送用Webサービスサービスの再起動|

### 各種ソフトをダウンロードしてインストール

yumを用いて各種ソフトをパッケージインストールします。回線速度により非常に時間が掛かる場合があり、標準のログ出力だけだと処理が進んでいるか、状況を確認しにくいので、別端末でvmstatなどを実行して状況確認したほうが良いです。sudo権限で以下を実行します。

```
sudo -E rex install_package
```

** Error installing の対処(EPEL設定が古い場合) **

EPELリポジトリ設定が古い場合に yum install で以下のエラーが発生します

```
Error: Cannot retrieve metalink for repository: epel. Please verify its path and try again
```

その場合、epel.repoを次の様に修正します

```
sudo vi /etc/yum.repos.d/epel.repo
```

変更前：

    #baseurl=http://download.fedoraproject.org/pub/epel/6/$basearch
    mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=epel-6&arch=$basearch

変更後：

    baseurl=http://download.fedoraproject.org/pub/epel/6/$basearch
    #mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=epel-6&arch=$basear

** Error installing の対処(yumの依存関係エラー) **
yumパッケージインストールをする場合にパッケージの依存関係でエラーとなる場合があります。
その場合は手動でyumを実行してエラーメッセージから依存関係エラーを調査してください。

```
sudo -E yum install pcre-devel php php-mbstring php-mysql php-pear php-common php-gd php-devel php-cli expat-devel redis
```

インストールに成功すると、以下ソフトが利用可能となります。ヘルプコマンドなどで以下のバージョンが入っているか確認します

| パッケージ | バージョン |
|--------|-----------|
|Java    |1.7        |
|gcc     |4.4        |
|Redis   |2.8        |
|MySQL   |5.1        |
|PHP     |5.3        |
|ant     |1.7        |

```
java -version
gcc -v
redis-cli -v
mysql --version
php -v
ant -v
gradle -v
```

** 注意 **
パッケージインストールした、Apache+PHPはモニタリング用Cactiのサイトとして利用します。これとは別に、/usr/localの下にWebサービス用のApacheをインストールします

SSL自己証明書作成
-------------------

/etc/getperf/sslの下に各種証明書を作成します。本証明書はエージェントとのHTTPS通信で使用し、Webサービス用のApacheに組込みます

### 自己認証局の作成

```
rex create_ca
```

以下ディレクトリが作成され、その中のca.crtが自己認証局の証明書となります

```
ls -l /etc/getperf/ssl/ca/
```

### サーバ証明書の作成

```
rex server_cert
```

以下ディレクトリが作成され、その中のserver.crtが自己認証局の証明したサーバ証明書となります

```
ls -l /etc/getperf/ssl/server/
```

Webサービス環境構築
-------------------

データ採取エージェントと連携するWebサービスを構築します。フロントに Apache HTTPD サーバ、サーブレットエンジンに Tomcat を配置し、Tomcat に Webサービスをデプロイします。

### Webサービス用Apacheインストール

パッケージインストールした Apache とは別に、/usr/local/にWebサービス用のApacheを追加インストールします。開発サイトからソースをダウンロードしてコンパイルします。本処理も非常に時間が掛かるので、vmstatなどで状況を確認しながら行った方が良いです

```
rex prepare_apache
```

インストールが完了すると、/usr/local/の下に、以下2つのApacheホームディレクトリが作成されます。

|インスタンス名|用途                                     |SSL方式 |
|--------------|-----------------------------------------|--------|
|/usr/local/apache-admin |採取エージェントセットアップ用Webサービス|サーバ認証|
|/usr/local/apache-data  |採取データ転送用Webサービス              |クライアント認証|


### Webサービス用Tomcatインストール

/usr/local/ の下にWebサービス用Tomcatをインストールします

```
rex prepare_tomcat
```

インストールが完了すると、/usr/local/の下に、以下2つのTomcatホームディレクトリが作成されます。

|インスタンス名|用途                                     |
|--------------|-----------------------------------------|
|/usr/local/tomcat-admin  |採取エージェントセットアップ用Webサービス|
|/usr/local/tomcat-data   |採取データ転送用Webサービス              |

### サービスの起動停止確認

これで一通りのソフトウェアインストールが完了し、各種設定はまだですが、ここで各サービスの起動確認をします。対象サービスは以下となります。

|サービス名|起動方法          |
|----------|------------------|
|mysql     |パッケージインストールされたサービス。起動スクリプトはディストリビューションによって異なる。CentOSの場合、起動スクリプトは/etc/init.d/mysql|
|redis     |パッケージインストールされたサービス。CentOSの場合、起動スクリプトは/etc/init.d/redis |
|apache2   |パッケージインストールされたサービス。CentOSの場合、起動スクリプトは/etc/init.d/httpd。Cactiモニタリングサイト用に使用 |
|apache2-admin|採取エージェント用Webサービス(管理用フロント)。/usr/local/の下にインストール。起動スクリプトは/etc/init.d/apache2-admin|
|apache2-data |採取エージェント用Webサービス(Data用フロント)。/usr/local/の下にインストール。起動スクリプトは/etc/init.d/apache2-data |
|tomcat7-admin|採取エージェント用Webサービス(管理用フロント)。/usr/local/の下にインストール。起動スクリプトは/etc/init.d/tomcat-admin|
|tomcat7-data |採取エージェント用Webサービス(Data用フロント)。/usr/local/の下にインストール。起動スクリプトは/etc/init.d/tomcat-data |

#### 自動起動の設定とサービス起動確認

OS起動時に各サービスが起動する設定を行います。ここでは、プロセスの起動確認のみとし、クライアントとの疎通や機能確認については次節で確認します。

```
sudo -E rex svc_auto
```

各サービスの起動をします。

```
rex svc_start
```

各サービスのプロセスを確認します

```
ps -ef | grep mysql
ps -ef | grep redis
ps -ef | grep httpd   # Apacheの確認
ps -ef | grep java    # Tomcatの確認
```

httpdプロセスは、/usr/sbin/httpd、/usr/local/apache2-admin/bin/httpd、/usr/local/apache2-data/bin/httpdの3つのパスのプロセスが複数起動されていればOKです。javaプロセスは、 「-Dcatalina.base=???」の値が、/usr/local/tomcat-adminと/usr/local/tomcat-dataの実行引数となるプロセスが起動されていればOKです。

** httpd起動時の httpd: apr_sockaddr_info_get() failed 発生時の対処 **

/etc/hostsの127.0.0.1 にホスト名を追記することで解消されます

```
sudo vi /etc/hosts
```

127.0.0.1 の後ろにホスト名追加
```
127.0.0.1 {ホスト名} ...
```

各サービスの停止をします。

```
rex svc_stop
```

各プロセスが終了していることを確認します。この後のデプロイ作業で各サービスに接続するので再度起動します。

```
rex svc_start
```

### Cactiサイトデプロイ

監視用Cactiサイトの構築環境をセットアップします。

#### MySQL セキュリティ設定

Cactiは定義データ保存用に、MySQLを使用するためMySQLのセットアップをします。ここでは、MySQL のセキュリティ設定ツールである、mysql_secure_install と同様の処理を実行します

```
rex prepare_mysql
```

conf/getperf_site.json 内に設定した、GETPERF_CACTI_MYSQL_ROOT_PASSWDをrootパスワードとして登録します。以下で設定したパスワードでMySQLに接続できるか、確認します。

```
mysqlshow -u root -p
(パスワード入力)
```

#### Cacti ダウンロード

Cacti開発サイトからソースをダウンロードします。サイト初期化時は本ファイルを解凍して、Cactiサイトを構築します。

```
rex prepare_cacti
```

ダウンロードしたファイルが有るか確認します。

```
ls -ltr var/cacti/
```

以下のファイルが保存されていればOKです。

```
-rw-rw-r--  1 psadmin psadmin 2272130 Jan  9 13:31 cacti-0.8.8b.tar.gz
```

サイト初期構築の動作確認
------------------------

上記手順でサイトの初期構築スクリプトの実行が可能となります。特定ディレクトリをホームとして、集計用ディレクトリ、集計スクリプト、モニタリング用Cactiサイトのホームディレクトリを作成します。

** 注意 **
以下作業は、sudoユーザではない一般ユーザでの実行を想定しています。今回は、同一ユーザで実行しますが、別ユーザで異なるディレクトリに複数サイト作成することが可能です。

### サイト初期化動作確認

ここでは、試しに kawasaki というサイトを作成してみます。ディレクトリはテスト用ディレクトリ下の、 t/kawasaki とします。管理ユーザで以下を実行します。

```
cd $GETPERF_HOME
perl script/initsite.pl t/kawasaki
```

以下のようなメッセージが出力されればOKです。

    Welcome to Getperf monitoring site !
    ====================================
    
    Please memo these information.
    
    The site key is "kawasaki" .
    The access key is "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX" .
    
    /home/pscommon/getperf/t/kawasaki has created as a site home directory .
    Under this directory , it include the collected data , aggregated script ,
    graph definition , and a monitoring site home page .
    If you customize the site , you can edit each directory .
    
    URL for Cacti monitoring will be following .
    
    http://192.168.10.1/kawasaki
    
    login user is "admin",and password is "admin" , after login , please change the password .
    
    Thanks

** 重要 : サイトキーとアクセスキーについて **

上記で生成したサイトキーとアクセスキーはエージェントセットアップの認証で使用しますのでメモをしておいてください。

作成したサイトのディレクトリを確認します。

```
ls t/kawasaki/
analysis  html  lib  node  site  storage  summary  view
```

本ディレクトリがサイトの保存、データ集計、グラフ定義用のディレクトリとなり収集データの確認、データ集計の設定、グラフ定義は本ディレクトリ下で行います。

### Cactiサイトの接続確認

前述のスクリプトは、Cactiモニタリング用Webサイトの初期構築を行います。
t/kawasaki/htmlがサイトのホームディレクトリとなり、Webブラウザから以下URLでアクセスします。

```
http://{サーバ接続先}/kawasaki
```

上記にアクセスすると、「Cacti Installation Guide」が表示され、順にNextボタンをクリックすることでインストールを完了します。
ユーザ名 'admin'、パスワード 'admin' でログインします。

** トラブルシューティング **

実行ユーザのホームのアクセス権限が不足している場合("drwx------.")、Webブラウザに以下メッセージが出力されます

```
Forbidden
You don't have permission to access ... on this server.
```

その場合は、以下ホームディレクトリのアクセス権限の変更("drwx--x--x.")をします

```
chmod a+x $HOME
```

Webサービスアプリケーションのデプロイ、動作確認
-----------------------------------------------

収集エージェントと連携するWebサービスアプリケーションをコンパイルし、Tomcatにデプロイします。Webサービスは管理用と、データ受信用の2つのサービスを設定します。

### JavaライブラリとApache Axis2のインストール

Javaライブラリをダウンロードし、Tomcatホームのlibにコピーします。
また、Apache Axis2 WebサービスライブラリをTomcatホームのwebappにコピーします。

```
rex prepare_tomcat_lib
```

インストール後、以下URLにアクセスし、Apache Axis2の管理コンソールに接続できることを確認します。

```
http://{サーバ接続先}:57000/axis2/
```
httpsの場合、
```
https://{サーバ接続先}:57443/axis2/
```

データ転送用Webサービスはポート番号が変わり、以下となります。

```
http://{サーバ接続先}:58000/axis2/
```

** 注意 **
データ転送用WebサービスのHTTPS接続はクライアント認証が必要なため、Webブラウザからアクセスはできません。クライアント証明についてはエージェントセットアップ手順にて説明します

### Webサービスアプリケーションのデプロイと動作確認

JavaソースからWebサービスアプリケーションをコンパイルし、Tomcatにデプロイします。

* Webアプリモジュール
  $GETPERF_HOME/module/getperf-ws
* Tomcatデプロイ先
  $TOMCAT_HOME/webapps/axis2/WEB-INF/services
* Webサービスアーカイブファイル
  GetperfService.aar

```
rex prepare_ws
```

ブラウザからデプロイしたサービスの接続を確認します。

```
https://{サーバ接続先}:57443/axis2/services/GetperfService?wsdl
```

エージェントモジュールのコンパイル、動作確認
--------------------------------------------

エージェントのコンパイル手順は UNIXと、Windowsで分かれます。ここでは集計サーバ上でLinuxの手順を説明します。Windowsについては、「[エージェントコンパイル手順」](agent_compile.html)を参照してください。

### Linux版コンパイル

エージェントモジュールソースに移動します

```
cd $GETPERF_HOME/module/getperf-agent/
```

** Linuxヘッダーファイルの作成 **

コンパイル環境がLinuxの場合、Linuxのディストリビューション用のヘッダーファイルを生成します

```
perl make_linux_include.pl
```

** include/gpf_common_linux.h **に以下例の内容が作成されます

    #define GPF_OSNAME        "CentOS6"
    #define GPF_OSTAG         "UNIX"
    #define GPF_OSTYPE        "CentOS"
    #define GPF_ARCH          "x86_64"
    #define GPF_MODULE_TAG    "CentOS6-x86_64"

configureスクリプトでmakefileを作成して、makeします

```
./configure
make
```

### 疎通確認

コンパイルモジュールの動作確認を行います。ここでは前述で構築したWebサービスと疎通確認を行います。以下スクリプトでWebサービスとの疎通確認、テスト用エージェントのSSL証明書や設定ファイルを生成します。

```
cd test
perl make_test_config.pl --site=kawasaki --agent=localhost
```

Webサービスとの疎通確認は、wgetコマンドレスポンスが 200 OK となれば、正しく疎通できています

### tarファイル作成

コンパイルしたバイナリをパッケージングします

```
cd $GETPERF_HOME/module/getperf-agent/
```

設定ファイル Agent.pm のサンプルをコピーして、設定します

```
cp Agent.pm.sample Agent.pm
vi Agent.pm
```

$URL_CMが管理用Webサービスのアドレスとなるよう、URLの接続先を変更します

```
$URL_CM = 'https://192.168.110.129:57443/axis2/services/GetperfService';
```

保存したら、deploy.pl を実行します。本スクリプトは$HOME/putneの下にモジュールを配布し、tarファイルを生成します

```
perl deploy.pl
```

以下コマンドでモジュールが作成されていることを確認します

```
cd $HOME
ls ptune                     # エージェントモジュール
ls getperf-2.*.tar.gz        # tarアーカイブ
ls update                    # 実行モジュールのみのアーカイブ(アップデート用に使用)
```

** アップデートモジュールの配布 **

上記で作成したアップデートモジュールは集計サーバ側に配布することで、アップデートのチェックとダウンロードができます。集計サーバの以下ディレクトリにコピーすることで、エージェントセットアップ時に本ファイルでアップデートの有無を確認します

```
mkdir $GETPERF_HOME/plugins/agent/
cp -r update  $GETPERF_HOME/plugins/agent/
```

### エージェント動作確認

エージェントのセットアップを行い、サーバの接続設定をます。

```
cd $HOME/ptune/bin
./getperfctl setup
```

初めに作成したサイトの認証を行い、エージェントの登録をします。

    /home/psadmin/ptune/network/License.txt : No such file or directory
    SSLライセンスファイルの初期化をします
    サイトキーを入力して下さい :XXXXX
    アクセスキーを入力して下さい :XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    ライセンスファイルがありません。ホストを再登録します
    以下のホスト情報を 'https://localhost:57443/axis2/services/GetperfService' に送信し、ホストを登録します
    SITEKEY : test1
    HOST    : localhost
    OSNAME  : CentOS

内容を確認し、よければyを押して、エージェントを登録します。集計サーバはエージェント登録受け付け後、SSL証明書の発行をし、エージェントは証明書のダウンロードを行います。以下のディレクトリに証明書が配布されます。

```
ls -l ../network
```

上記ディレクトリのcliemnt.pemが発行した証明書となります。

### エージェントの起動

エージェントのデーモン起動をします。

```
./getperfctl start
```

psコマンドで起動を確認します

    ps -ef | grep _getperf    
    psadmin   8123  8119  0 17:37 ?        00:00:00 /home/psadmin/ptune/bin/_getperf -c     /home/psadmin/ptune/getperf.ini
    psadmin   8139  4076  0 17:38 pts/3    00:00:00 grep _getperf

ログを確認します

```
tail -f ../_log/getperf.log
```

以下ログ例の通り、リソース採取コマンドを定期的に実行し、サーバに転送します

    2015/03/14 17:48:00 [gpf_agent.c:1018][gpfRunCollector:notice] [C][HW] START (20150314/174500) ======
    2015/03/14 17:48:00 [gpf_agent.c:1360][gpfRunWorker:notice] [W][HW][4][Exec] /bin/cat /proc/net/dev
    2015/03/14 17:48:00 [gpf_agent.c:1360][gpfRunWorker:notice] [W][HW][5][Exec] /bin/df -k -l
    2015/03/14 17:48:00 [gpf_agent.c:1360][gpfRunWorker:notice] [W][HW][3][Exec] /usr/bin/iostat -xk 30 12
    2015/03/14 17:48:00 [gpf_agent.c:1360][gpfRunWorker:notice] [W][HW][2][Exec] /usr/bin/free -s 30 -c 12
    2015/03/14 17:48:00 [gpf_agent.c:1360][gpfRunWorker:notice] [W][HW][1][Exec] /usr/bin/vmstat -a 5 61

### サービスの起動設定

/etc/init.dに起動スクリプトをコピーして、スクリプトの編集をします

    cd $HOME/ptune/bin
    sudo cp getperfagent /etc/init.d/
    sudo vi /etc/init.d/getperfagent

以下例の通り、エージェントのホームディレクトリと実行ユーザを編集します

    PTUNE_HOME=/home/psadmin/ptune
    GETPERF_USER=psadmin

chconfigでOS起動時の自動起動on設定をします

    sudo chkconfig getperfagent on
    sudo chkconfig --list | grep getperfagent

集計サーバ側の動作確認
--------------------

前述で作成した、サイトディレクトリでエージェントデータ集計の動作確認をします。作成したサイトのディレクトリに移動してください。sysn.pl --statusと実行してサイトの状態を確認します

    sync.pl --status
    {
            "site_key":   "test1",
            "access_key": "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX",
            "home":       "/home/psadmin/work/test1",
    
            "auto_aggregate": 1,
            "auto_deploy":    1
    }

sync.pl -h を実行してヘルプを確認します

    sync.pl -h
    Unknown option: h
    Error!
    Usage : sync.pl
    rsync.pl, monitor.pl:
            [--config=file] [--interval=i] [--times=i]
    sync.pl:
            [--sitekey=s] [--on|--off|--status|--lastzip|--ziplist] [--recover|--fastrecover]

以下のコマンドを実行して、エージェントデータのzipファイルの状態を確認します

```
sync.pl --ziplist
```

本コマンドは、以下のzipファイル状態の確認コマンドとなります

1行目：サイトキー  採取種別 ホスト名
2行目：最後のzipファイル 最新のzipファイル [zipファイル数]

sync.pl --ziplist 出力例：

    test1   HW      localhost
    arc_localhost__HW_20150314_173500.zip   arc_localhost__HW_20150314_181500.zip   [9]

