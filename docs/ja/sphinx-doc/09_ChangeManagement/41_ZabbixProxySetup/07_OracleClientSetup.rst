Oracleクライアントインストール
==============================

Zabbixサーバ、プロキシの各サーバに Oracle クライアントをインストールします。

パッケージは Oracle 社提供の rpm を使用します。あらかじめ以下のモジュールを準備してください。

/tmp/rpms/rpms.oracle/ に以下の rpm をアップロードします。

   * oracle-instantclient11.2-basic-11.2.0.4.0-1.x86_64.rpm
   * oracle-instantclient11.2-devel-11.2.0.4.0-1.x86_64.rpm
   * oracle-instantclient11.2-sqlplus-11.2.0.4.0-1.x86_64.rpm

上記モジュールは NY2 Zabbix 構築で使用したモジュールで、本構築作業用ディレクトリ下の
ファイルアーカイブを使用してください。

ローカル環境インストール用のコマンドを使用してパッケージインストールします。
以下コマンドを実行してください。

::

   cd /tmp/rpms/rpms.oracle/
   sudo dnf --disablerepo=* localinstall *.rpm

Oracle クライアントのライブラリパスを設定します。

::

   export LD_LIBRARY_PATH=/usr/lib/oracle/11.2/client64/lib:$LD_LIBRARY_PATH
   export PATH=/usr/lib/oracle/11.2/client64/bin:$PATH


sqlplus を実行し動作確認します。

::

   sqlplus /nolog



