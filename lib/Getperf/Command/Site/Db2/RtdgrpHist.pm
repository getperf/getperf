package Getperf::Command::Site::Db2::RtdgrpHist;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use base qw(Getperf::Container);
use Getperf::Command::Master::Db2;

sub new {bless{},+shift}

sub update_cacti_graph_item {
	my ($self, $data_info, $sql_hash, $graph_templates_item_id, $data_template_data_id, $rra ) = @_;

	my $update_item =
		"UPDATE graph_templates_item " .
		"SET text_format = '$sql_hash' " .
		"WHERE id = $graph_templates_item_id";
	$data_info->cacti_db_dml($update_item);

	my $update_rrd =
		"UPDATE data_template_data " .
		"SET data_source_path = '$rra' " .
		"WHERE id = $data_template_data_id";
	$data_info->cacti_db_dml($update_rrd);
}

sub parse {
    my ($self, $data_info) = @_;

	# 時間     20220404 08:00
	# 装置群    DSRTDGRPZ-
	# 作成平均秒  1
	my (%results, %sql_stats);
	my $step = 600;
	my @headers = qw/create_time/;

	$data_info->step($step);
	$data_info->is_remote(1);
	my $host   = $data_info->file_suffix;
	$host = 'RTDDB' if ($host=~/rddb/);
	my $sec  = $data_info->start_time_sec->epoch;
	if (!$sec) {
		return;
	}
	my $device;
	open( my $in, $data_info->input_file ) || die "@!";
#	$data_info->skip_header( $in );
	while (my $line = <$in>) {
		$line=~s/(\r|\n)*//g;			# trim return code
		# 時間     20220404 08:00
		if ($line=~/^時間\s+(\d+.+\d)$/) {
			$sec = localtime(Time::Piece->strptime($1, 
				'%Y%m%d %H:%M'))->epoch;
		# 装置群    DSRTDGRPZ-
		} elsif ($line=~/装置群\s+(.+?)$/) {
			$device = $1;
		# 作成平均秒  1
		} elsif ($line=~/作成平均秒\s+(\d.*?)$/) {
			$results{$device}{$sec} = $1;
		}
	}
	close($in);

	# 直近の値は10分未満の集計値となる場合があるため、除外する
	# その１つ前の集計値を登録する
	for my $device(keys \%results) {
		my %dat = %{$results{$device}};
		my $value = delete $dat{$sec};
		%{$results{$device}} = %dat;
		$sql_stats{$device}{'elapse'} = $value || 0;
	}
	# データ登録
	for my $device(keys \%results) {
		my $output_file = "Db2/$host/device/rtdgrp_hist__${device}.txt";
		$data_info->regist_device($host, 'Db2', 'rtdgrp_hist', $device, $device, \@headers);
		$data_info->simple_report($output_file, \%{$results{$device}}, \@headers);
	}
	# ランク更新
	my $query_items =
		"SELECT  g.local_graph_id, gi.sequence, " .
		"    gi.id graph_templates_item_id, gi.text_format, " .
		"    dd.id data_template_data_id, dd.data_source_path " .
		"FROM graph_templates_graph g, " .
		"    graph_templates_item gi, " .
		"    data_template_rrd dr, " .
		"    data_template_data dd " .
		"WHERE gi.local_graph_id = g.local_graph_id " .
		"    AND gi.task_item_id = dr.id " .
		"    AND dr.local_data_id = dd.local_data_id " .
		"    AND gi.graph_type_id in (4) " .
		"    AND g.title_cache = '__graph_title__' " .
		"ORDER BY gi.sequence";

	my $n_top = 30;
	my %registered_sql_hash = ();
	for my $sort_key(qw/elapse/) {
		my @sql_ranks = sort { $sql_stats{$b}{$sort_key} <=> $sql_stats{$a}{$sort_key} } keys %sql_stats;
		my $rank = 1;
		for my $sql_hash(@sql_ranks) {
			next if (defined($registered_sql_hash{$sql_hash}));
			$data_info->regist_device($host, 'Db2', 'rtdgrp_hist', $sql_hash, undef, \@headers);
			# my $output = "Db2/${host}/device/rtdgrp_hist__${sql_hash}.txt";
			# $data_info->pivot_report($output, $results{$sql_hash}, \@headers);
			$rank ++;
			$registered_sql_hash{$sql_hash} = 1;
			last if ($n_top < $rank);
		}
		print Dumper \%registered_sql_hash;
		my $ranks_n = scalar(@sql_ranks);
		my @sql_ranks_top_n;
		if ($ranks_n < $n_top) {
			@sql_ranks_top_n = (@sql_ranks, ('dummy') x ($n_top - $ranks_n));
		} else {
			@sql_ranks_top_n = @sql_ranks[0..$n_top-1];
		}
		$data_info->regist_devices_alias($host, 'Db2', 'rtdgrp_hist',
		                                 'rtdgrp_hist_by_' . $sort_key,
		                                 \@sql_ranks_top_n, undef);
	# 	my $graph_header = $graph_headers{$sort_key};
		my $graph_header ='Rtdgrp Process Time sec - Summary';
		for my $graph_title_suffix('', ' - 2', ' - 3', ' - 4') {
			my $graph_title = "Db2 - ${host} - " . $graph_header . $graph_title_suffix;
			my $query = $query_items;
			$query=~s/__graph_title__/${graph_title}/g;
			if (my $rows = $data_info->cacti_db_query($query)) {
				for my $row(@$rows) {
					my $graph_templates_item_id = $row->[2] || 0;
					my $data_template_data_id   = $row->[4] || 0;
					my $sql_hash = shift(@sql_ranks);
					if ($sql_hash && $graph_templates_item_id && $data_template_data_id) {
						my $rra = "<path_rra>/Db2/${host}/device/rtdgrp_hist__${sql_hash}.rrd";
						$self->update_cacti_graph_item($data_info, $sql_hash, $graph_templates_item_id,
							                           $data_template_data_id, $rra);
					} else {
						my $rra = "<path_rra>/Db2/${host}/device/rtdgrp_hist__dummy.rrd";
						$self->update_cacti_graph_item($data_info,, 'unkown', $graph_templates_item_id,
							                           $data_template_data_id, $rra);
					}
				}
			}
		}
	}
	return 1;
}

1;
