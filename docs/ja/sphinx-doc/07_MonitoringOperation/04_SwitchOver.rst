フェイルオーバー後の切り戻し
==============================

フェイルオーバー発生後は、手動で旧稼働系を復帰させ、切り戻し作業を行います。
その手順を以下に記します。前提条件として、フェールオーバー後の旧稼働系は以下の状態となっていることとします。

- 旧稼働系でOSが起動ができる状態にする。
- 以下のサービスは停止した状態にする。
   - MySQL
   - Zabbix Server

**旧稼働系をスレーブとして復帰**

新稼働系でバイナリログチェックポイントを確認します。

::

   mysql -u root -p -e "show master status;"
   +-------------------+-----------+--------------+------------------+
   | File              | Position  | Binlog_Do_DB | Binlog_Ignore_DB |
   +-------------------+-----------+--------------+------------------+
   | mysqld-bin.000001 | 620812883 |              |                  |
   +-------------------+-----------+--------------+------------------+

旧稼働系をMySQLスレーブとして設定します。MySQLがダウンしている場合は起動します。

::

   sudo /etc/init.d/mysqld start

旧稼働系のMySQLに接続して、レプリケーション設定をします。

::

   mysql -u root -p

::

   SET GLOBAL read_only = 1;
   SET GLOBAL sql_slave_skip_counter = 1;
   change master to
       master_host='192.168.10.2',
       master_user='repl',
       master_password='repl',
       master_log_file='mysqld-bin.000001',
       master_log_pos=620812883;
   start slave;
   show slave status;
   exit;

旧待機系でMHAチェックコマンドを実行して、sshとレプリケーションの状態確認をします。

::

   sudo masterha_check_ssh --conf=/etc/mha.conf
   sudo masterha_check_repl --conf=/etc/mha.conf


**系の切り戻し**

旧待機系で切り戻しを実行します。
フェイルオーバー後に生成されるフラグファイルを削除します。

::

   sudo rm -f /tmp/mha/mha.failover.complete

手動切り戻しスクリプトを実行します。IPアドレスは旧稼働系のIPアドレスを指定します。

::

   sudo masterha_master_switch --master_state=alive \
   --conf=/etc/mha.conf \
   --new_master_host=192.168.10.1  --orig_master_is_new_slave

デーモンを再起動します。

::

   sudo initctl start mha

元に戻っていることを確認します。

::

   sudo masterha_check_repl --conf=/etc/mha.conf

.. note:: スレーブで不整合エラーが出る場合の対処

   "show slave status;"で更新SQLのエラーが発生した場合は、以下のコマンドでエラーとなったSQLを順にスキップさせてください。

   ::

      mysql -u root -p
      STOP SLAVE; SET GLOBAL SQL_SLAVE_SKIP_COUNTER=1; START SLAVE;
      show slave status;
