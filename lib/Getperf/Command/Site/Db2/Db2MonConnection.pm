package Getperf::Command::Site::Db2::Db2MonConnection;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use Storable;
use base qw(Getperf::Container);
use Getperf::Command::Master::Db2;

sub new {bless{},+shift}

my $LONG_LIVE_HANDLE_COUNT = 0;

# 前回登録値の保存ファイルパス "storage/connection_stat_{ノード}.dat" 取得
sub get_datastore {
    my ($data_info, $node, $schema) = @_;
    my $storage_dir = $data_info->absolute_storage_dir;
    return "${storage_dir}/connection_stat_${node}.dat";
}

sub parse {
    my ($self, $data_info) = @_;
    my ($results, $stats);
    my $step = 600;
    $data_info->step($step);
    $data_info->is_remote(1);
    my $host_prefix = $data_info->file_suffix || $data_info->host;
    $host_prefix = lc $host_prefix;
    my $member = 0;
    my $host = sprintf("%s%02d", $host_prefix, $member + 1);
    my $sec  = $data_info->start_time_sec->epoch;
    my $mode = 'all';
    open( my $in, $data_info->input_file ) || die "@!";
    my $handles;
    my $handle = 'Unkown';

    # ハンドラーカウントの読み込み
    my $handle_hist;
    my $datastore = get_datastore($data_info, $host_prefix);
    my $sumup_average_debug = 0;
    if (-f $datastore) {
        $handle_hist = retrieve( $datastore ) ;
        if ($sumup_average_debug || $data_info->{summary_dir} =~/\/000000/) {
            print "reset datastore for next day : $datastore\n";
            unlink $datastore;
        }
    }
    # for my $handle(sort {$handle_hist->{$b}<=>$handle_hist->{$a}} keys %{$handle_hist}) {
    #     my $count = $handle_hist->{$handle};
    #     print "$handle, $count \n";
    # }
    # exit;
    # print Dumper $handle_hist; exit;
    my $handle_count = 0;

    while (my $line = <$in>) {
        # print "$mode:$host:$line";
        $line=~s/(\r|\n)*//g;           # trim return code
        if ($line=~/MON_GET_CONNECTION/) {
            $member = 0;
            $host = sprintf("%s%02d", $host_prefix, $member + 1);
            $mode = 'active'; 
            # print "!!! NEXT SECTION\n";
        }
        next if ($line!~/^([A-Z][A-Z].+?)\s+(.+?)$/);
        my ($metric, $value) = ($1, $2);
        if ($metric eq 'MEMBER') {
            $host = sprintf("%s%02d", $host_prefix, $value + 1);
        } if ($metric eq 'APPLICATION_HANDLE') {
            $handle = $value;
            $handles->{$handle} = 1;
            $results->{$host}{$sec}{$mode} += 1;
            $handle_count = $handle_hist->{$handle} || 0;
            if ($mode eq 'active' && $handle_count > $LONG_LIVE_HANDLE_COUNT) {
                # print "REG_COUNT4:$mode,$host,$handle,$handle_count\n";
                $stats->{$host}{"LONG_LIVE_HANDLE_COUNT|$handle"}{$sec} = $handle_count;
            }
            # print "CHECK HANDLE $handle, $handle_count\n";
        } else {
            if ($mode eq 'active' && $handle_count > $LONG_LIVE_HANDLE_COUNT) {
                # print "REG_COUNT3:$mode,$host,$handle,$handle_count\n";
                if ($metric=~/ID$/) {
                    $value = "'${value}'";
                }
                # print "METRIC:$metric, VAL:$value\n";
                $stats->{$host}{"$metric|$handle"}{$sec} = $value;
            }
        }
    }
    close($in);

    # print Dumper $stats;
    for my $host(keys %{$stats}) {
        my $options = {'enable_first_load' => 1};
        db2_update_stats($data_info, $host, 'mon_get_connection', 
            $stats->{$host}, $options);
    }

    # ハンドラカウントの保存
    for my $handle (keys %{$handles}) {
        $handle_hist->{$handle} ++;
    }
    if ($handles) {
        store $handle_hist, $datastore;
    }

    my $options = {'enable_first_load' => 1};
    # db2_update_stats($data_info, $host, 'mon_get_connection', $stats, $options);
    # print Dumper $results;
    my @headers = qw/active all/;
    for my $host(keys %{$results}) {
        my $host_results = $results->{$host};
        $data_info->regist_metric($host, 'Db2', 'db2_mon_connection', \@headers);
        my $output = "Db2/${host}/db2_mon_connection.txt";
        $data_info->pivot_report($output, $host_results, \@headers);
    }

    return 1;
}

1;
