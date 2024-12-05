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

1. 46 行目付近の接続情報を修正します。

   ::

       $db_password = '<DB接続パスワード>';
       $curr_tz = 'Asia/Tokyo';

2. 60行目をコメントアウトします。

   ::

       #                'history_bin' => { 'period' => 'day', 'keep_history' => '60'},

3. 127行目付近のコメントアウトをMySQL8用に変更します。

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
変更にはパーティションキーの時刻の範囲指定が必要なため、以下で最古の更新日付を確認します。

::

   mysql -u zabbix -pgetperf zabbix -e 'SELECT FROM_UNIXTIME(MIN(clock)) FROM history_uint;'

実行結果例は以下となります。

::

   +---------------------------+
   | FROM_UNIXTIME(MIN(clock)) |
   +---------------------------+
   | 2024-12-05 12:24:41       |
   +---------------------------+
   1 row in set (0.01 sec)


この場合は2024/12/5が最古のデータで、本日付から現在時刻の翌日までをパーティションキーの範囲として、パーティション表を作成します。

mysql コマンドで zabbix に接続します。

::

   # MySQL に接続
   mysql -u zabbix -pgetperf zabbix

各テーブルに対してSQLを実行します。
以下の通り範囲指定の箇所を修正します。

* 「p2024_12_05 VALUES LESS THAN (UNIX_TIMESTAMP("2024-12-05 00:00:00") 」の箇所を確認した最古の日付(この場合は2024/12/05)で記述します
* 「p2024_12_06 VALUES LESS THAN (UNIX_TIMESTAMP("2024-12-06 00:00:00")」の箇所を翌日の日付(この場合は2024/12/06)で記述します


::

   ALTER TABLE history PARTITION BY RANGE ( clock) (PARTITION p2024_12_05 VALUES LESS THAN (UNIX_TIMESTAMP("2024-12-05 00:00:00")) ENGINE = InnoDB, PARTITION p2024_12_06 VALUES LESS THAN (UNIX_TIMESTAMP("2024-12-06 00:00:00")) ENGINE = InnoDB);
   ALTER TABLE history_log PARTITION BY RANGE ( clock) (PARTITION p2024_12_05 VALUES LESS THAN (UNIX_TIMESTAMP("2024-12-05 00:00:00")) ENGINE = InnoDB, PARTITION p2024_12_06 VALUES LESS THAN (UNIX_TIMESTAMP("2024-12-06 00:00:00")) ENGINE = InnoDB);
   ALTER TABLE history_str PARTITION BY RANGE ( clock) (PARTITION p2024_12_05 VALUES LESS THAN (UNIX_TIMESTAMP("2024-12-05 00:00:00")) ENGINE = InnoDB, PARTITION p2024_12_06 VALUES LESS THAN (UNIX_TIMESTAMP("2024-12-06 00:00:00")) ENGINE = InnoDB);
   ALTER TABLE history_text PARTITION BY RANGE ( clock) (PARTITION p2024_12_05 VALUES LESS THAN (UNIX_TIMESTAMP("2024-12-05 00:00:00")) ENGINE = InnoDB, PARTITION p2024_12_06 VALUES LESS THAN (UNIX_TIMESTAMP("2024-12-06 00:00:00")) ENGINE = InnoDB);
   ALTER TABLE history_uint PARTITION BY RANGE ( clock) (PARTITION p2024_12_05 VALUES LESS THAN (UNIX_TIMESTAMP("2024-12-05 00:00:00")) ENGINE = InnoDB, PARTITION p2024_12_06 VALUES LESS THAN (UNIX_TIMESTAMP("2024-12-06 00:00:00")) ENGINE = InnoDB);
   ALTER TABLE trends PARTITION BY RANGE ( clock) (PARTITION p2024_12_05 VALUES LESS THAN (UNIX_TIMESTAMP("2024-12-05 00:00:00")) ENGINE = InnoDB, PARTITION p2024_12_06 VALUES LESS THAN (UNIX_TIMESTAMP("2024-12-06 00:00:00")) ENGINE = InnoDB);
   ALTER TABLE trends_uint PARTITION BY RANGE ( clock) (PARTITION p2024_12_05 VALUES LESS THAN (UNIX_TIMESTAMP("2024-12-05 00:00:00")) ENGINE = InnoDB, PARTITION p2024_12_06 VALUES LESS THAN (UNIX_TIMESTAMP("2024-12-06 00:00:00")) ENGINE = InnoDB);

パーティションメンテナンススクリプトの動作確認とスケジュール設定
----------------------------------------------------------------

手動でスクリプトを実行し、動作確認します。

::

   # psadmin ユーザで Zabbix サーバに接続
   cd ~/work
   ./mysql_zbx_part.pl

実行ログを以下 syslog から確認します。

::

   sudo tail -f /var/log/messages

確認ができなた、Cron にて定期実行の設定をします。

::

   crontab -e

以下行を追加します。

::

   55 22 * * *  (source /home/psadmin/.bash_profile && /home/psadmin/work/mysql_zbx_part.pl >/dev/null 2>&1)


Zabbixハウスキーパーの無効化
----------------------------


Perlスクリプトまたはストアドプロシージャのいずれかをパーティション分割して設定した後、
HistoryテーブルとTrendsテーブルのZabbixハウスキーパーを無効にする必要があります。

* Zabbixフロントエンドに移動し、[管理] [一般設定] [データの保存期間] を選択します

* ヒストリと、トレンドの「削除処理を有効」のチェックを外します。

