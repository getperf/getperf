Cacti エージェント Getperf V2 版移行について
============================================

概要
----

現在の Cactiエージェントは C/C++ でコーディングされており、サーバが高負荷の状態になった時に、
排他制御の誤りで異常終了してしまう問題があります。
本バグ修正は C/C++ のメモリ管理に関する修正で、コーディングミスを
起こすリスクが高く、致命的な問題を作り出してしまう可能性がく、コード修正を保留しています。
代替策として C/C++ よりクリーンで安全と言われている Go 言語への移行を進めています。
バージョン 2 以降が Go 言語移行版で、一部の処理を Go 言語に書き換えており、
以下の2バージョンの構成があります。

1. v2.1 ～

    メイン処理を C/C++ から Go 言語に移行し、zip ファイルデータの転送は外部コマンドで
    従来の C/C++ モジュールをキックする方式に変更。キックするコマンドは OpenSSL v1.0 
    の C ライブラリを使用している

2. v2.18 ～

    データ転送処理も Go 言語に移行し、OpenSSL ライブラリを使用せずに、Go 言語の 
    SSL/TLS ライブラリを使用した版

今後、v2.18 以降への移行が望ましい状況ですが、使用する Go 言語版の SSL/TLS ライブラリは
脆弱性対応のため X.509v3 に対応した HTTPS 通信のみのサポートとなり、現在の X.509v3 の対応していないCacti 受信サーバの HTTPS 通信では利用できません。

今後、Cacti 受信サーバの X.509v3 移行対応を進め、同時に v2.18 のモジュール移行を
進められるよう、以下のパラメータで HTTPS 通信処理のモードを変更できるようにしています。

1. POST_SOAP_CMD_TYPE = Legacy

    既定のデータ転送モードで、現 Cacti 受信サーバでも利用可能な、従来の外部コマンドを
    キックするモード。

2. POST_SOAP_CMD_TYPE = Internal

    新規のデータ転送モードで、内部処理でデータ転送をするモード。X.509 v3 移行後は
    本モードを使用します。

1が標準となり、現環境でも移行が可能です。X.509 v3 移行後は 2のモードに変更します。


    # 全モジュール版：
    getperf2-ZabbixX-BuildXX-CentOS8-x86_64.tar.gz
    ※ XX の箇所は 18以上のものを選んでください

パッチ適用手順
--------------

修正パッチ適用版の適用手順を以下に記します。

本モジュールのファイル構成は以下となり、ダウンロードサイトからダウンロード可能です。

::

    # Linux 
    getperf2-patch-BuildXX-CentOS8-x86_64.tar.gz

    # Windows
    getperf2-patch-BuildXX-Windows-x86_64.zip

監視対象サーバに zabbix ユーザでssh接続します。

現エージェントを停止します。

::

    # 旧エージェントの停止スクリプトを実行
    sudo /etc/init.d/getperfagent stop
    # プロセスが終了したことを確認
    ps -ef | grep _getperf

パッチ適用版アーカイブをダウンロードします。

::

    wget http://{ダウンロードサイトIP}/getperf2-patch-Build18-CentOS8-x86_64.tar.gz

ptune の下に解凍します。

::

    cd ~/ptune/
    tar xvf getperf2-patch-Build18-CentOS8-x86_64.tar.gz

新エージェントを開始します。

::

    # 新エージェントの起動スクリプトを実行
    ~/ptune/bin/getperfctl start
     ps -ef | grep _getperf

モード変更手順
---------------

設定ファイルを編集します。

::

    vi ~/ptune/getperf.ini

以下のパラメータを追加します。

::

    ; Data transfer mode
    POST_SOAP_CMD_TYPE = Internal

zipファイル転送モードの指定で、 Lagacy にすると、現行の C言語版外部コマンドを
キックするモードになります。Internal にすると、外部コマンドや OpenSSL ライブラリ
の使用をしない内部処理で実行するモードとなります。


