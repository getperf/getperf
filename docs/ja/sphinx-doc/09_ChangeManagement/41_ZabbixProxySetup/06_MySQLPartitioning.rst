MySQLパーティショニング
=======================

Zabbix サーバで MySQL 履歴テーブルをパーティション化する設定を行います。

.. note::

   本設定の詳細は以下の記事を参照してください。

   Partitioning a Zabbix MySQL(8) database with Perl or Stored Procedures

   https://blog.zabbix.com/partitioning-a-zabbix-mysql-database-with-perl-or-stored-procedures/13531/

Perl セットアップ
-----------------

Zabbix サーバで psadmin 管理者ユーザで、パーティションメンテナンススクリプトを設定します。

本スクリプトは Perl 言語で書かれており、Perl の実行環境が必要です。

:doc:`/03_Install/03_Installation/12_RsyncSetup` 記載の、「Perl 5.16.3 環境構築」
を実行してください。

パーティションメンテナンススクリプト設定
----------------------------------------

開発元からパーティションメンテナンススクリプトをダウンロードします。

::

   # Zabbix サーバに psadmin で接続
   # 作業ディレクトリ作成、移動
   mkdir ~/work
   cd ~/work
   git clone https://github.com/OpensourceICTSolutions/zabbix-mysql-partitioning-perl

メンテナンススクリプトをコピーして編集します。

::

   cp ./zabbix-mysql-partitioning-perl/mysql_zbx_part.pl .
   vi mysql_zbx_part.pl

以下の箇所を修正します。

46 行目付近の接続情報を修正します。

::

    $db_password = '<DB接続パスワード>';
    $curr_tz = 'Asia/Tokyo';

60行目をコメントアウトします。

::

    #                'history_bin' => { 'period' => 'day', 'keep_history' => '60'},

127行目付近のコメントアウトをMySQL8用に変更します。

::

   # MySQL 5.6 + MariaDB
       # my $sth = $dbh->prepare(qq{SELECT plugin_status FROM information_schema.plugins WHERE plugin_name = 'partition'});

       # $sth->execute();

       # my $row = $sth->fetchrow_array();

       # $sth->finish();
       #     return 1 if $row eq 'ACTIVE';

   # End of MySQL 5.6 + MariaDB

   # MySQL 8.x (NOT MariaDB!)
       my $sth = $dbh->prepare(qq{select version();});
       $sth->execute();
       my $row = $sth->fetchrow_array();
    
       $sth->finish();
         return 1 if $row >= 8;

パーティション表の作成
-----------------------

履歴テーブルをパーティション表に変更します。
変更にはパーティションキーの時刻の範囲指定が必要なため、最古の更新日付を確認します。

::

   mysql -u zabbix -pgetperf zabbix -e 'SELECT FROM_UNIXTIME(MIN(clock)) FROM proxy_history;'

::

+---------------------------+
| FROM_UNIXTIME(MIN(clock)) |
+---------------------------+
| 2024-12-05 12:24:41       |
+---------------------------+
1 row in set (0.01 sec)
