=================
集計スクリプトAPI
=================

集計スクリプトのparse関数の引数の受信データオブジェクト $data_info の API 定義を記します。　
集計スクリプトのサブルーチンは以下形式となり、$data_info を引数として使用して集計処理をコーディングします。

例: 集計スクリプトのサブルーチン

::

    sub parse {
        my ($self, $data_info) = @_;

        # $data_info オブジェクトを経由した API 処理
    }

受信データの情報取得、設定
--------------------------

受信データ情報取得
^^^^^^^^^^^^^^^^^^

受信データパスから各種情報を取得します。

host()
""""""

::

    my $host = $data_info->host;    # server01

エージェントを実行した監視対象サーバを取得します。

postfix()
"""""""""

::

    # 受信データ 192.168.10.1/http_response.txt から、192.168.10.1 を取得
    my $host = $data_info->postfix;

リモート採取で監視対象をディレクトリごとに振り分けをする場合、ディレクトリ名から監視対象を取得します。

file_suffix()
"""""""""""""

::

    # 受信データ http_response__192.168.10.2.txt から、192.168.10.2 を取得
    my $host = $data_info->postfix;

受信データのファイル名のサフィックスを取得します。リモート採取で監視対象をサフィックスに指定する場合に使用します。

file_name()
"""""""""""

::

    my $file_name = $data_info->file_name;  # http_response__192.168.10.2.txt

受信データのファイル名を取得します。

file_ext()
""""""""""

::

    my $file_ext = $data_info->file_ext;    # txt

受信データのファイル拡張子を取得します。

start_timestamp()
"""""""""""""""""

::

    my $start_timestamp = $data_info->start_timestamp;  # 2014-11-17T08:00:00

受信データのコマンド開始時刻を取得して'%Y-%m-%dT%H:%M:%S'形式の文字列に変換します。

start_time_sec()
""""""""""""""""

::

    my $sec  = $data_info->start_time_sec;  # 1447457299
    $timestamp = $sec->datetime;            # 2015-11-13T23:28:19

受信データのコマンド開始時刻を取得してUNIX時刻に変換します。結果オブジェクトをdatetime関数で呼ぶと'%Y-%m-%dT%H:%M:%S'形式の文字列に変換します。

.. note::

    戻り値は Time::Piece 型となりますが、データ集計で使用するデータ型は int 型の方がパフォーマンス面で有利で使い勝手もよくなります。
    int型に変換する場合は以下epoch関数を追加します。

    ::

        my $sec  = $data_info->start_time_sec->epoch;

集計データ設定
^^^^^^^^^^^^^^

集計データの設定をします。

is_remote()
"""""""""""

::

    $data_info->is_remote(1);
    my $host = $data_info->postfix;
    my $output = "/HTTP/${host}/http_response.txt";

引数に1を指定した場合、リモート採取を有効にします。集計データパスは '{ドメイン}/{ノード}/{メトリック}.txt'
で指定します。デバイスデータの場合は、'{ドメイン}/{ノード}/device/{メトリック}__{デバイス}.txt'となります。

step()
""""""

RRDtool のステップ(秒)を指定します。

受信データファイル入力
^^^^^^^^^^^^^^^^^^^^^^

input_file()
""""""""""""

::

    open(my $in, $data_info->input_file ) || die "@!";

受信データのファイルパスを取得します。open 関数と合わせて使用します。

input_dir()
"""""""""""

::

    my $input_dir = $data_info->input_dir;  # {サイトホーム}/analysis/{監視対象}/Linux/20151116/084500

受信データのディレクトリパスを取得します。

skip_header()
"""""""""""""

::

    open( my $in, $data_info->input_file ) || die "@!";
    $data_info->skip_header( $in );

受信データのデータファイルの先頭行のヘッダの読み込みをスキップします。1行目,2行目で開始と終了が英字またた'-'の場合,'-'と空白からなる場合は次の行までファイルポインタをスキップします。

メトリックの登録
^^^^^^^^^^^^^^^^

ノード定義にメトリック情報を登録します。regist_metric、 regist_device は登録後、RRDtool へのデータロードを実行します。
regist_node　ノードに情報を追加をする関数で次節で設定例を説明します。

regist_metric()
"""""""""""""""

::

    $data_info->regist_metric($node, $domain, $metric, \@headers);

ノード定義 'node/{domain}/{node}/{metric}.json' にRRDtool のパスを登録します。@headers は RRDtool のデータファイル作成時のデータソースリストとして用います。

regist_device()
"""""""""""""""

::

    $data_info->regist_device($node, $domain, $metric, $device, $device_text, \@headers);

ノード定義 'node/{domain}/{node}/device/{metric}.json' にRRDtool のパスとデバイスリストを登録します。

regist_node()
"""""""""""""

::

    $data_info->regist_node($node, $domain, $node_info_path, \%node_infos);

ノード定義 'node/{domain}/{node}/{node_info_path}.json に情報を追加します。
$node_info_path は、'info/{メトリック}'の形式で指定します。%node_infos は追加情報の連想配列を指定します。


regist_devices_alias()
""""""""""""""""""""""

::

    $data_info->regist_devices_alias($nodepath, $domain, $metric, $alias, \@devices, \@texts);

'{alias}.json' という別名で、regist_device() と同等の形式でノード定義を作成します。
regist_device() との違いは、ノード定義ファイルが {alias}.json となり、事後処理の RRDtool のデータ登録を行いません。

レポート出力
^^^^^^^^^^^^

集計データファイルを作成します。バッファリングされた集計データを成形してファイル出力します。集計データファイルは RRDtool のロードの入力ファイルになります。

simple_report()
"""""""""""""""

::

    $data_info->simple_report($output_file, \%results, \@headers);

集計データ用ディレクトリ 'summary/{監視対象}/{カテゴリ}/{日付}/{時刻}' ディレクトリの下に集計データファイルを作成します。
%results　はタイムスタンプをキーにした連想配列で、要素は1列目から順に空白またはタブで区切った文字列となります。

pivot_report()
""""""""""""""

::

    $data_info->pivot_report($output_file, \%results, \@headers);

集計データ用ディレクトリ 'summary/{監視対象}/{カテゴリ}/{日付}/{時刻}' ディレクトリの下に集計データファイルを作成します。
%results　はタイムスタンプ、列名をキーにした連想配列で、要素は値となります。列は @headers のリスト順に出力します。

standard_report()
"""""""""""""""""

::

    $data_info->standard_report($output_file, $buffer);

バッファを成形せずにそのまま集計データファイルに出力します。


report_zabbix_send_data()
"""""""""""""""""""""""""

::

    $data_info->report_zabbix_send_data($node, \%zabbix_send_data);

Zabbix データロード用ファイル 'summary/{監視対象}/{カテゴリ}/{日付}/{時刻}/zabbix_send_data.txt' を作成します。
%zabbix_send_data はタイムスタンプ、アイテムをキーにした連想配列で、要素はロードする値となります。

::

    $send_data{1464209361}{'oracle.tbs.usage'} = 95.49;
    $data_info->report_zabbix_send_data('orcl', \%send_data);

とすると、zabbix_send_data.txt は以下となります。

::

    cat summary/test_a1/Oracle/{日付}/{時刻}/zabbix_send_data.txt
    orcl oracle.tbs.usage 1464209361 95.49

Cacti DB アクセス
^^^^^^^^^^^^^^^^^

cacti_db_query()
""""""""""""""""

::

    $data_info->cacti_db_query(@params);

Cactiデータベースに対して、検索SQLを実行します。
引数に SQL を指定して実行すると、Cacti サイトの MySQL DBに接続し、SQL実行結果を返します。

::

    my $sql  = "select id,hostname from host";
    my $rows = $data_info->cacti_db_query($sql);
    print Dumper $rows;

上記を実行すると、以下の様な出力例になります。

::

    $VAR1 = [
              [
                '8',
                'Oracle - orcl'
              ]
            ];

cacti_db_dml()
""""""""""""""

::

    $data_info->cacti_db_dml(@params);

Cactiデータベースに対して、DML (更新SQL) を実行します。

::

    my $dml = "update host " .
              "set hostname = 'Oracle - orcl2' " .
              "where id = 8";
    $data_info->cacti_db_dml($dml);

上記を実行すると、host テーブルを更新します。
