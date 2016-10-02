監視テンプレートの作成
======================

テンプレートの構成
------------------


エージェント設定追加
--------------------

::

	curl -o /dev/null "http://192.168.10.1:57000/" -w "%{time_total}\n" 2> /dev/null
	0.002

::

    ;---------- Monitor command config (HTTP Response) -----------------------------------
    STAT_ENABLE.HTTP = true
    STAT_INTERVAL.HTTP = 300
    STAT_TIMEOUT.HTTP = 300
    STAT_MODE.HTTP = concurrent

    STAT_CMD.HTTP = 'curl -o /dev/null "http://{外部サーバアドレス}/" -w "%{time_total}\n"', {外部サーバアドレス}/http_response.txt


データ集計のカスタマイズ
------------------------

::

	sumup --init analysis/ostrich/HTTP/20161001/174000/192.168.10.1/http_response__getperf_ws.txt

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
	    my $app  = $data_info->file_suffix; # 3. 受信データファイル名からアプリ名抽出
	    my $sec  = $data_info->start_time_sec->epoch;

	    open( IN, $data_info->input_file ) || die "@!";
	    while (my $line = <IN>) {
	        $line=~s/(\r|\n)*//g;           # trim return code
	        $results{$sec} = $line;
	    }
	    close(IN);
	    $data_info->regist_device($host, 'HTTP', 'http_response', $app, undef, \@headers);
	    # 3. 集計データファイルパス設定
	    my $output = "/HTTP/${host}/device/http_response__${app}.txt";
	    $data_info->simple_report($output, \%results, \@headers);
	    return 1;
	}

	1;

::

	sumup -l analysis/ostrich/HTTP/
	more node/HTTP/192.168.10.1/device/http_response.json


グラフ登録
----------

::

	mkdir lib/graph/HTTP
	vi lib/graph/HTTP/http_response.json

.. code-block:: json

    source

	{
	  "host_template": "HTTP",
	  "host_title": "HTTP - <node>",
	  "priority": 1,
	  "graphs": [
	    {
	      "graph_template": "HTTP - Response - <devn> cols",
	      "graph_tree": "/HTTP/<node_path>/latency/",
	      "graph_title": "HTTP - <node> - Response",
	      "graph_type": "multi",
	      "legend_max": 15,
	      "graph_items": ["sec"],
	      "vertical_label": "Disk busy %",
	      "upper_limit": 100,
	      "unit_exponent_value": 1,
	      "datasource_title": "HTTP - <node> - Response - <device>"
	    }
	  ]
	}

::

	cacti-cli -g lib/graph/HTTP/http_response.json

::

	cacti-cli node/HTTP/192.168.10.1/device/http_response.json

テンプレートのエクスポート
--------------------------

::

	cacti-cli --export HTTP

::

	sumup --export=HTTP --archive=$GETPERF_HOME/var/template/archive/config-HTTP.tar.gz
