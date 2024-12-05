Oracleクライアントインストール
==============================

ローカル環境インストール用パッケージを使用してインストールする。
以下コマンドを実行する。

::

   cd /tmp/rpms/zabbix_mariadb_snmptrapd_packages/rpms.oracle/
   sudo dnf --disablerepo=* localinstall *.rpm

Oracle クライアントのライブラリパスを設定します。

::

   export LD_LIBRARY_PATH=/usr/lib/oracle/11.2/client64/lib:$LD_LIBRARY_PATH
   export PATH=/usr/lib/oracle/11.2/client64/bin:$PATH


sqlplus を実行し動作確認します。

::

   sqlplus /nolog



