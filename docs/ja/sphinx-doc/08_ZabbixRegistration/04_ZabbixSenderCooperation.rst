集計データとZabbixの連携
========================

Getperf の集計データを Zabbix に転送して監視をする場合の手順は以下となります。

1. データ転送用の Zabbix アイテムを登録する
2. 集計スクリプト内で登録した Zabbix アイテムにデータを転送する

1はエージェントレス構成での Zabbix アイテム登録になり、手順は前節で説明した通りです。2は、集計スクリプトに Zabbix データ転送用 API のコードを追加します。本 API は Zabbix データ転送コマンド zabbix_sender を実行して、Zabbix にデータを転送します。

zabbix_senderについて
---------------------

zabbix_sender は、Zabbix　エージェントを経由せずに直接、Zabbix　の監視アイテムにデータ転送をするコマンドで、Getperf は事前に転送用データファイルを作成して zabbix_sender を実行します。
例としてOracle 表領域使用率のデータファイルを以下に記します。

::

   vi testdat.txt
   cat testdata.txt
   orcl adm.oracle.tbs.usage.UNDOTBS1 1464209361 15
   orcl adm.oracle.tbs.usage.USERS 1464209361 95.49
   orcl adm.oracle.tbs.usage.SYSTEM 1464209361 98.85

各行のフォーマットは"<ホスト> <アイテム> <タイムスタンプ(エポック値)> <値>"となります。本ファイルを指定して、zabbix_sender を実行します。実行例は以下となります。

::

   zabbix_sender -z 127.0.0.1 -p 10051 -i testdat.txt
   info from server: "processed: 4; failed: 0; total: 4; seconds spent: 0.001767"
   sent: 4; skipped: 0; total: 4

-z オプションが Zabbix サーバのIP 、-p オプションがZabbix サーバの接続ポートとなり、$GETPERF_HOME/config/getperf_zabbix.json ファイルのZABBIX_SERVER_IP, ZABBIX_SERVER_PORTのパラメータを使用します。

データ集計スクリプトのカスタマイズ
----------------------------------

データ集計スクリプトに上記、データ転送用のファイルを作成するコードを追加します。例として Oracle 表領域の集計スクリプトのコードの一部を以下に記します。(必要なコードのみ編集しているため、実際のコードとは異なります。)

::

   cat lib/Getperf/Command/Site/Oracle/OraTbs.pm

      my %zabbix_send_data;

      while (my $line = <$in>) {
         <中略>
         my $zabbix_item = "adm.oracle.tbs.usage." . $tbs;
         $zabbix_send_data{$sec}{$zabbix_item} = $value;                   # 1
      }

      $data_info->report_zabbix_send_data($instance, \%zabbix_send_data);  # 2

#1 で、%zabbix_send_data 連想配列に値をセットします。#2 でAPIをコールして、転送用データファイルを作成します。
本スクリプトを実行すると、転送用データファイルが作成され、zabbix_sender を起動してZabbix にデータを転送します。

