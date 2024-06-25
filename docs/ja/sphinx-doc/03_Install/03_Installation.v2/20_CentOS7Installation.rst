==================================
CentOS7 Getperf インストール留意点
==================================

概要
====

CentOS6ベースの Getperf を CentOS7 環境へインストールする際の留意点は以下となります

* MySQL は 5.7以上だと既定値の設定が大きく変わるため、5.6 を指定する
* Apache / Tomcat 周りは Apache 2.2 , Tomcat 7 系のままで良い
    * Tomcat server.xml の AJP 設定が変わるので手動で設定ファイルを編集
    * jar のデプロイでエラーが発生、要調査。他サイトからのコピーで対応
* PHP/Cacti 周りは、PHPを5.4に上げ、Cacti は0.8.8 のままとする
    * MySQL のsql_mode 設定変更をしないとグラフ表示できないなど不具合あり
* サービス起動設定が systemctl に変わるので、起動スクリプト等の移行が必要
* 古い Getperf デーモンは動作が不安定なため、Rsync/Cron 構成に変える

.. note::

    CentOS8 系は perl ライブラリなど不明となるパッケージが多数あるため、
    CentoOS7 系へのインストールが望ましい

基本設定
---------

Firewall 無効化設定はiptables から以下に変更。

::

    systemctl status firewalld 
    systemctl stop firewalld 
    systemctl disable firewalld 


MySQL 5.6 バージョン指定インストール
---------------------------------------

パッケージインストールの前に、バージョン5.6 を指定して MySQL
パッケージをインストールする

::

    sudo -E yum localinstall http://dev.mysql.com/get/mysql57-community-release-el6-7.noarch.rpm
    sudo -E yum repolist all | grep mysql

    sudo -E yum -y install yum-utils
    sudo -E yum-config-manager --disable mysql57-community
    sudo -E yum-config-manager --enable mysql56-community

    yum info mysql-community-server

    sudo  yum -y install mysql-community-server
    sudo systemctl enable mysqld
    sudo systemctl start mysqld

以降は、mysql-devel 等の依存パッケージも 5.6 系がインストールされるようになる

Gradle のバージョン指定
------------------------

インストールスクリプトを編集して、バージョンを最新 6.7.1 に変更
ダウンロードサイトのURLをhttpからhttpsに変更

::

    vi ./script/gradle-install.sh
    #gradle_version=2.3
    gradle_version=6.7.1

    wget -N https://services.gradle.org/distributions/gradle-6.7.1-all.zip

Apache/ Tomcat 
------------------

Apache は 2.2 系の最新版を事前にダウンロードする。
保存先は /tmp/rex

::

    cd /tmp/rex
    wget https://archive.apache.org/dist/httpd/httpd-2.2.34.tar.gz
    tar xvf httpd-2.2.34.tar.gz

Rexfile のバージョン指定を、 32 から 34 に変更

::

    cd ~/getperf
    vi Rexfile

Tomcat AJP の設定が有効にならないので手動で変える。
通信暗号化が既定では有効のため、secretRequired を無効にする

* tomcat-data

vi /usr/local/tomcat-data/conf/server.xml

::

    <Connector protocol="AJP/1.3"
               address="::1"
               port="58009"
               redirectPort="58443" secretRequired="false" />

* tomcat-admin

vi /usr/local/tomcat-admin/conf/server.xml

::

    <Connector protocol="AJP/1.3"
               address="::1"
               port="57009"
               redirectPort="57443" secretRequired="false" />




サービス自動起動設定
---------------------

mysqldとhttpd の設定スクリプトでエラーとなるため、手動で登録が必要

::

    [2020-12-08 04:29:15] INFO - sudo -E bash -c "/etc/init.d/mysqld start"
    [2020-12-08 04:29:15] INFO - bash: /etc/init.d/mysqld: No such file or directory
    [2020-12-08 04:29:18] INFO - start : httpd
    [2020-12-08 04:29:18] INFO - sudo -E bash -c "/etc/init.d/httpd start"
    [2020-12-08 04:29:18] INFO - bash: /etc/init.d/httpd: No such file or directory

MySQL 設定
-------------

既定のMySQL設定だと、Cacti 周りで多数エラーが発生する

::

    Incorrect datetime value: '0000-00-00 00:00:00' for column 'status_fail_date' at row 1node8:0

mysql のエラーが出力されていた。 sql_mode を変える必要がある

::

    SHOW VARIABLES LIKE "%sql_mode%";
    +---------------+--------------------------------------------+
    | Variable_name | Value                                      |
    +---------------+--------------------------------------------+
    | sql_mode      | STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION |
    +---------------+--------------------------------------------+

オンラインでの設定変更。

::

    SET GLOBAL sql_mode = 'NO_ENGINE_SUBSTITUTION';

/etc/my.cnf の sql_mode も変更する

::

    sudo vi /etc/my.cnf

::

    # Recommended in standard MySQL setup
    #sql_mode=NO_ENGINE_SUBSTITUTION,STRICT_TRANS_TABLES
    sql_mode=NO_ENGINE_SUBSTITUTION

Rsync/ sitesync 設定
-----------------------

xinetd 設定で、rsync を有効化する設定が centos7 にはない。以下は
実施しなくても良い

::

    ### sudo vi /etc/xinetd.d/rsync
    ### 
    ### disable = no に変更します。
    ### 
    ### xinetd の起動設定をします。
    ### 
    ### sudo chkconfig xinetd on

rsyncd.conf の設定で、ファイルオーナーを root に変える

sudo vi /etc/rsyncd.conf

::

    # 名前(旧サイトのサイトキー)
    [archive_test1]
    # 転送データの保存ディレクトリ
    path =  /home/psadmin/getperf/t/staging_data/test1
    # 転送先許可IPアドレス(新サーバから疎通できるようにする)
    hosts allow = 133.118.210.0/24
    hosts deny = *
    list = true
    # 転送データのオーナー
    uid = root
    # 転送データのオーナーグループ
    gid = root
    read only = false
    dont compress = *.gz *.tgz *.zip *.pdf *.sit *.sitx *.lzh *.bz2 *.jpg *.gif *.png

その他
------

Zabbix 設定無効化

::

    vi ~/getperf/config/getperf_zabbix.json

::

        "USE_ZABBIX_MULTI_SITE": 0,
        "GETPERF_USE_ZABBIX_SEND": 0,
        "GETPERF_AGENT_USE_ZABBIX": 0

DBD::mysql が入らないので、手動で入れる

::

    sudo -E cpanm DBD::mysql 
