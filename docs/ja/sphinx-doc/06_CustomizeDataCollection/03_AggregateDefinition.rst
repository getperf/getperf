集計定義
========

集計処理フロー
--------------

監視サーバの集計処理の流れは以下となります。

1. 受信データzipファイルを anlysis の下に解凍
2. 解凍したファイルパスを解析して、集計スクリプトを検索
3. 集計スクリプト実行

2は以下の集計スクリプトの検索ルールに従って集計スクリプトを選択します。

集計スクリプトの検索ルール
--------------------------

集計スクリプトは Perl のクラスライブラリで、解凍したファイルパスからクラスを検索します。
そのルールは以下の通りです。

1. analysis 下の採取データファイルパスからカテゴリ名とファイル名を抽出します。

   例 : analysis/{監視対象}/Linux/20151111/170000/loadavg.txt から、Linux と loadavg.txt を抽出

2. カテゴリ名とファイル名は Camel 表記に変換します。
3. ファイル名はファイル拡張子と、\_\_(アンダースコア2つ)で始まるサフィックスの文字列を除きます。

   例 : loadavg.txt を Loadavg に変換

4. サイトディレクトリ下の lib/Getperf/Command/Site/{カテゴリ名}/{ファイル名}.pm を検索します。

   例 : lib/Getperf/Command/Site/Linux/Loadavg.pm を検索

5. 存在しない場合は、GETPERF\_HOME 下の
   lib/Getperf/Command/Base/{カテゴリ名}/{ファイル名}.pm　を検索します。

   例 : $GETPERF\_HOME/lib/Getperf/Command/Base/Linux/Loadavg.pm を検索

6. 4,5 のいずれのファイルも存在しない場合は集計処理をスキップします。

4 はサイト内固有のスクリプトファイルとなり集計処理のカスタマイズに用います。
5は全サイト共通のスクリプトファイルで不変なスクリプトとなります。

集計スクリプトのコーディング
----------------------------

ここでは既存の Linux HWリソースの集計スクリプトを参照してコードの説明をします。
Linux の HW リソースの集計スクリプトは、サイト初期化時にデフォルトでインストールされます。
サイトディレクトリに移動し、登録されているスクリプトを確認します。

loadavg ロードアベレージのデータ集計
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

まず初めに単純な例として loadavg のデータ集計例を示します。loadavgの受信データは以下形式となります。

例 : loadavg 受信データ
(analysis/{監視対象}/Linux/20151114/180000/loadavg.txt)

::

    0.00 0.00 0.00 1/348 31163
    0.00 0.00 0.00 1/343 31205
    0.00 0.00 0.00 1/342 32432
    <中略>

最初の 3 桁は、1分、5分、10分間前に測定されたロードアベレージ値を表示します。
本値を集計するスクリプトを参照します。
実際には3桁の値を抽出して時系列データベースに登録するだけの簡単なスクリプトです。
説明が必要な個所をコメントで追記しています。

例 : loadavg 集計スクリプト (lib/Getperf/Command/Site/Linux/Loadavg.pm)

::

    package Getperf::Command::Site::Linux::Loadavg; # 1.パッケージ名
    use strict;
    use warnings;
    use Data::Dumper;
    use Time::Piece;                                # 2.必須ライブラリ
    use base qw(Getperf::Container);                # 2.必須ライブラリ

    sub new {bless{},+shift}

    sub parse {
        my ($self, $data_info) = @_;                # 3.$data_infoが受信データオブジェクト

        my %results;
        my $step = 5;
        my @headers = qw/load1m load5m load15m/;    # 4.データソースリスト

        $data_info->step($step);                    # 5.ステップの登録

        my $host = $data_info->host;                # 6.ホスト名の検索
        my $sec  = $data_info->start_time_sec->epoch; # 7.開始時刻の検索
        open( my $in, $data_info->input_file ) || die "@!";
        while (my $line = <$in>) {
            next if ($line=~/^\s*[a-z]/);   # skip header
            $line=~s/(\r|\n)*//g;           # trim return code
            my @loads = ($line =~ m/(\d+\.\d+)\s+/g);
            $results{$sec} = join(' ', @loads);
            $sec += $step;
        }
        close($in);
        # 8.メトリックの登録
        $data_info->regist_metric($host, 'Linux', 'loadavg', \@headers);
        # 9.レポート出力
        $data_info->simple_report('loadavg.txt', \%results, \@headers);
        return 1;
    }

    1;

parse()がデータ集計サブルーチンとなり、第2引数の $data_info が集計対象の受信データのオブジェクトで、受信データの情報や結果の出力などを行う支援クラスとなります。

1. パッケージ名はスクリプトパス名に従います。スクリプトパス名は前述の集計スクリプトの検索ルールで検索されたパスとなります。
2. 時系列ライブラリの 'Time::Piece' 、オブジェクトコンテナライブラリの'Getperf::Container' は必須ライブラリとなります。
3. 第2引数の $data_info 受信データオブジェクトを用いて、各種APIにアクセスします。
4. 時系列データベース RRDtool に登録するデータソース名のリストです。RRDtool へのデータ登録にはいくつかの注意事項があり、次節で説明します。
5. 時系列データベースの登録データのサンプリング間隔を設定します。
6. 受信データファイルからホスト名を抽出します。
7. 受信データファイルの開始時刻(UNIX時刻)を取得します。
8. ノード、ドメイン、メトリック、ヘッダリストをノード定義に登録します。ノード定義は、node/{ドメイン}/{ノード}/{メトリック}.json ファイルに記録されます。
9. 集計データをファイルに書き込みます。'summary/{監視対象}/{カテゴリ}/{日付}/{時刻}' ディレクトリの下にファイル出力します。引数は、出力ファイル名、出力データリファレンス、ヘッダリストリファレンスを指定します。出力データはタイムスタンプをキーにした各値の連結文字列の連想配列です。出力データのは使用するレポート関数によりフォーマットが異なります。

parse()処理終了後、ノード定義ファイルの更新、 RRDtool へのデータロードを行います。チュートリアルの節で説明した sumup コマンドの実行例で説明します。受信データファイルを指定して sumup を実行します。

例： loadavg データ集計コマンドの実行例

::

    sumup analysis/{監視対象}/Linux/20151116/140000/loadavg.txt
    2015/11/16 14:53:24 [INFO] command : Site::Linux::Loadavg
    2015/11/16 14:53:24 [INFO] load row=10, error=(10/0/0)
    2015/11/16 14:53:24 [INFO] sumup : files = 1, elapse = 0.011321

ノード定義ファイルは以下の通りで、ロードする RRDtool データのパスを指定します。

例: loadavg メトリック定義の確認

::

    more node/Linux/{監視対象}/loadavg.json
    {
       "rrd" : "Linux/{監視対象}/loadavg.rrd"
    }

sumup コマンドの出力例は以下となり、本データを RRDtool にロードします。

例: loadavg 集計データ(summary/{監視対象}/Linux/20151114/180000/loadavg.txt)

::

    timestamp load1m load5m load15m
    1455210091 0.00 0.00 0.00
    1455210096 0.00 0.00 0.00
    1455210101 0.00 0.00 0.00
    <中略>

1行目はヘッダ情報でデータソースリストを simple_report() の引数に指定します。関数で指定したヘッダリストを出力します、2行目以降は結果データで、loadavg
の3桁に時刻を追加したデータとなります。本ファイルを、RRDtool にロードします。

iostat ディスクI/Oのデータ集計
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

複数デバイスからなる受信データの集計例を示します。ディスクI/Oや、ネットワークのI/Oのデータは1つのファイルに複数のデバイスの情報が記録されています。
集計スクリプトはデバイス毎に集計結果を分割し、RRDtool へのロードも分割したデバイスファイル単位に実行します。ディスクI/O統計の出力コマンドの iostat を例にして説明します。

例 : iostat 受信データ
(analysis/{監視対象}/Linux/20151116/084500/iostat.txt)

::

    Linux 2.6.32-279.el6.x86_64 (t00020823cap17)    11/14/2015      _x86_64_
    (2 CPU)

    avg-cpu:  %user   %nice %system %iowait  %steal   %idle
               0.99    0.00    0.71    0.12    0.00   98.19

    Device:         rrqm/s   wrqm/s     r/s     w/s    rkB/s    wkB/s avgrq-sz avgqu-sz   await  svctm  %util
    sda               0.05    26.81    0.34   32.12     2.33   235.77    14.67     0.13    4.10   0.12   0.39
    dm-0              0.00     0.00    0.39   58.93     2.32   235.73     8.03     0.28    4.69   0.07   0.39
    dm-1              0.00     0.00    0.00    0.01     0.01     0.03     8.00     0.00    4.59   0.32   0.00
    <中略>

集計スクリプトは各デバイスのディスクI/O 統計を抽出し、デバイス毎にファイル出力します。
説明が必要な個所をコメントで追記しています。

例 : iostat 集計スクリプト (lib/Getperf/Command/Site/Linux/Iostat.pm)

::

    package Getperf::Command::Site::Linux::Iostat;
    use strict;
    use warnings;
    use Data::Dumper;
    use Time::Piece;
    use base qw(Getperf::Container);

    # avg-cpu:  %user   %nice %system %iowait  %steal   %idle
    #            0.37    0.00    1.97    0.24    0.00   97.41

    # Device:         rrqm/s   wrqm/s     r/s     w/s    rkB/s    wkB/s avgrq-sz avgqu-sz   await  svctm  %util
    # sda               0.34    14.29    7.65    1.97   153.33    65.03    45.37     0.01    1.16   0.93   0.89

    sub new {bless{},+shift}

    sub parse {
        my ($self, $data_info) = @_;

        my %results;
        my $step = 30;
        my $start_timestamp = $data_info->start_timestamp;
        my @headers = qw/rrqm_s wrqm_s r_s w_s rkb_s wkb_s svctm pct/;

        $data_info->step($step);
        my $host = $data_info->host;
        my $sec  = $data_info->start_time_sec->epoch;
        open(my $in, $data_info->input_file ) || die "@!";
        while (my $line = <$in>) {
            $line=~s/(\r|\n)*//g;   # trim return code

            if ($line=~/^\s*([a-zA-Z]\S*?)\s+(\d.*\d)$/) {
                my ($device, $body) = ($1, $2);
                # 1. 集計データファイルのパス名の指定。サフィックスにデバイスを登録
                my $output_file = "device/iostat__${device}.txt";
                # 2. 集計結果のヘッダを設定
                $results{$output_file}{headers} = \@headers;
                # 3. デバイスの登録
                $data_info->regist_device($host, 'Linux', 'iostat', $device, undef, \@headers);

                # 4. データソース名をキーに各要素の連想配列を登録
                my @values = split(/\s+/, $body);
                for my $header(qw/rrqm_s wrqm_s r_s w_s rkb_s wkb_s/) {
                    my $value = shift(@values);
                    $results{$output_file}{out}{$sec}{$header} = $value;
                }
                $results{$output_file}{out}{$sec}{pct}   = pop(@values);
                $results{$output_file}{out}{$sec}{svctm} = pop(@values);

            } elsif ($line=~/^Device:/) {
                $sec += $step;
            }

        }
        close($in);
        # 5. 集計結果をデバイス毎にファイル出力
        for my $output_file(keys %results) {
            my $headers  = $results{$output_file}{headers};
            $data_info->pivot_report($output_file, $results{$output_file}{out}, $headers);
        }
        return 1;
    }

    1;

デバイス毎にファイル出力を変えるため、ファイル名のサフィックスにデバイス名を追加して振り分けをしています。

1. パス名のサフィックスにデバイスを追加したファイルパスを設定します。デバイス付きのファイルパスは、'device/{メトリック}__{デバイス}.txt' という形式で指定します。
2. デバイス毎の振り分けでデータソースが異なるケースを想定して、個々のデバイス毎にヘッダを設定します。
3. デバイスのノード定義を登録します。引数に、ノード名、ドメイン名、メトリック名、デバイス名、デバイスのテキスト名、ヘッダのポインタを指定します。ノード定義は、'node/{ドメイン}/{監視対象}/device/{メトリック}.json' という形式で保存されます。
4. 各要素をキーにした連想配列で結果を登録します。
5. 集計結果をデバイスファイル毎に出力します。

受信データファイルを指定して sumup を実行します。ノード定義は、新たにdevices 要素が追加されます。

例: iostat メトリック定義の確認

::

    more node/Linux/{監視対象}/device/iostat.json
    {
       "devices" : [
          "sda",
          "dm-0",
          "dm-1"
       ],
       "rrd" : "Linux/t00020823cap17/device/iostat__*.rrd"
    }

集計データはデバイスファイルごとに生成されます。デバイスファイルは、device ディレクトリの下に保存する必要があります。

例: iostat 集計データ(summary/{監視対象}/Linux/20151114/180000/device/iostat\_\_sda.txt)

::

    timestamp rrqm_s wrqm_s r_s w_s rkb_s wkb_s svctm pct
    1455210061 0.05 26.81 0.34 32.12 2.33 235.77 0.12 0.39
    1455210091 0.00 2.60 0.00 1.20 0.00 15.20 0.28 0.03
    1455210121 0.00 18.47 0.00 5.20 0.00 94.67 0.99 0.52
    <中略>

HTTP レスポンスのデータ集計
~~~~~~~~~~~~~~~~~~~~~~~~~~~

リモート採取の集計例として、外部サーバの HTTP レスポンスのデータ集計を新規に設定します。
curlコマンドを用いて、指定したURLのレスポンス時間[秒]を計測し、その結果を集計します。

例 : 外部サーバのHTTPレスポンス時間[秒]の計測例

::

    curl -o /dev/null "http://{外部サーバアドレス}/" -w "%{time_total}\n" 2> /dev/null
    0.020

エージェントに5分間隔で上記 curl コマンドを実行する設定をします。
vi~/ptune/conf/HTTP.ini で以下設定ファイルを作成し、 ~/ptune/bin/getperfctl stop、~/ptune/bin/getperfctl start でエージェントを再起動してください。
注意点として出力ファイルの指定で、外部サーバのアドレスをディレクトリに追加します。本ディレクトリは監視対象ノードの解析で使用します。

例 : エージェントのHTTP採取設定({エージェントホーム}/conf/HTTP.ini)

::

    ;---------- Monitor command config (HTTP Response) -----------------------------------
    STAT_ENABLE.HTTP = true
    STAT_INTERVAL.HTTP = 300
    STAT_TIMEOUT.HTTP = 300
    STAT_MODE.HTTP = concurrent

    STAT_CMD.HTTP = 'curl -o /dev/null "http://{外部サーバアドレス}/" -w "%{time_total}\n"', {外部サーバアドレス}/http_response.txt

集計スクリプトは以下となります。注意点をコメントで追記しています。

例 : HTTPレスポンス 集計スクリプト
(lib/Getperf/Command/Site/HTTP/HttpResponse.pm)

::

    package Getperf::Command::Site::HTTP::HttpResponse;
    use strict;
    use warnings;
    use Data::Dumper;
    use Time::Piece;
    use base qw(Getperf::Container);

    sub new {bless{},+shift}

    sub parse {
        my ($self, $data_info) = @_;

        my %results;
        my $step = 300;
        my @headers = qw/response/;

        $data_info->step($step);
        $data_info->is_remote(1);           # 1. リモート採取設定
        my $host = $data_info->postfix;     # 2. 受信データファイルパスからホスト名抽出
        my $sec  = $data_info->start_time_sec;

        open( IN, $data_info->input_file ) || die "@!";
        while (my $line = <IN>) {
            $line=~s/(\r|\n)*//g;           # trim return code
            my $timestamp = $sec->datetime;
            $results{$timestamp} = $line;
            $sec += $step;
        }
        close(IN);
        $data_info->regist_metric($host, 'HTTP', 'http_response', \@headers);
        # 3. 集計データファイルパス設定
        my $output = "/HTTP/${host}/http_response.txt";
        $data_info->simple_report($output, \%results, \@headers);
        return 1;
    }

    1;

基本的な処理の流れは同じですが、コメントに記した箇所が異なります。

1. リモート採取を有効化します。リモート採取用の集計処理に変更します。
2. 受信データパスのディレクトリ部分からホスト名(監視対象ノード)を抽出します。
3. 集計データパスは '{ドメイン}/{ノード}/{メトリック}.txt'
   で指定します。デバイスデータの場合は、'{ドメイン}/{ノード}/device/{メトリック}\_\_{デバイス}.txt'となります。

リモート採取を有効化した場合、集計データのパスの指定方法が変わります。

例: HTTPレスポンス
集計データ(summary/{監視対象}/HTTP/20151114/180000/HTTP/{外部サーバアドレス}/http\_response.txt)

::

    timestamp response
    1455210091 0.023

集計データパスの時刻ディレクトリの後ろに、ドメイン、ノードのペアのディレクトリが追加されます。複数のノードの振り分けをするため、ディレクトリを分けて集計します。上記例では外部サーバアドレスが監視対象ノードとなります。

設定の反映手順
--------------

集計スクリプトの変更内容を自動集計に反映させるには集計デーモンを再起動する必要があります。以下のコマンドを実行します。

例 : 集計デーモンの再起動

::

    cd {サイトホーム}
    sumup restart

ヘッダによる RRDtool データソース定義
-------------------------------------

集計データのヘッダ定義はRRDtoolのデータソースリストとなりすが、以下のフォーマットで':'区切り文字でオプションを追加することができます。

ヘッダの定義

::

    ds-name:ds-type:heartbeat:min:max

-  ds-name :
   データソース名。RRDtoolは名前の付け方に幾つかの制約があります(詳細は後述)。
-  ds-type : データソースタイプ。GAUGE \| COUNTER \| DERIVE \| ABSOLUTE
   から選択します。既定は GAUGE です。
-  heartbeat :
   ハートビート値(sec)。登録間隔が本値より長い場合は欠損値として扱います。既定は
   step \* 100 です。
-  min : 値の下限値。既定は 0 です。
-  max : 値の上限値。既定は 無制限(U) です。

使用例を以下に記します。

例 : ネットワークカウンタのヘッダ定義

::

    my @headers = ('inBytes:COUNTER', 'inPackets:COUNTER', 'outBytes:COUNTER', 'outPackets:COUNTER');

**データソース名命名の注意事項**

-  名前は19文字以内にする必要があります
-  使用できる文字列は大文字小文字の英字、数字、'_'となります

