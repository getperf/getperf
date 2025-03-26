package Getperf::Command::Site::Db2::Db2SqlRankTest;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use base qw(Getperf::Container);
use Getperf::Command::Master::Db2;
use Storable;

# Db2 SQL ランク集計結果テスト用

sub new {bless{},+shift}

sub parse {
    my ($self, $data_info) = @_;

	my $step = 600;
	$data_info->step($step);

	my @headers = qw/value/;

	$data_info->is_remote(1);

	my $host = $data_info->file_suffix || $data_info->host;
	my $sec  = $data_info->start_time_sec->epoch;

	my $results;
    my $query = "select `member`, `metric`, sum(`value`) " .
        "from `db2_sql_rank` " .
        "where `clock` = $sec " .
        "group by `member`, `metric`";
    my $rows = $data_info->cacti_db_query($query);
    for my $row(@{$rows}) {
        my ($member, $metric, $value) = @{$row};
        $results->{$sec} = $value;
        my $output = "Db2/${member}/device/db2_sql_rank_test__${metric}.txt";
        $data_info->regist_device($member, 'Db2', 'db2_sql_rank_test',
            $metric, $metric, \@headers);
        $data_info->simple_report($output, $results, \@headers);
    }
	return 1;
}

1;
