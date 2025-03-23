package Getperf::Command::Site::Db2::Db2SqlRankGraphWeekly;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use Path::Class;
use base qw(Getperf::Container);
use Getperf::Command::Master::Db2;
use Storable;

sub new {bless{},+shift}

# SQL ランク集計結果グラフ登録

my $PURGE_RRD_HOUR = 3 * 24;

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

sub purge_sql_hash_rrd_data {
	my ($self, $data_info, $instance) = @_;

	my $storage_dir = $data_info->{absolute_storage_dir};
	my $limit_time  = $data_info->start_time_sec->epoch - $PURGE_RRD_HOUR * 3600;

	# purge storage/Db2/{sid}/device/ora_sql_top__*.rrd
	my $rrdfile_filter = "$storage_dir/Db2/$instance*/device/db2_sql_top__\*.rrd";
	my $rc = open (my $in, "ls $rrdfile_filter | grep -v dummy |") || warn "can't find '$rrdfile_filter' : $!";
	print "PURGE : $rrdfile_filter:$rc\n";
	while (my $rrdfile = <$in>) {
		chomp $rrdfile;
		my $updated = (stat($rrdfile))[8];
		if ($updated < $limit_time) {
			unlink $rrdfile;
		}
	}
	close($in);
}


# 先頭
# use Getperf::Command::Site::Db2::Db2SqlRankTest;
# 終了
# my $test = Getperf::Command::Site::Db2::Db2SqlRankTest->new;
# $test->parse($data_info);

sub parse {
    my ($self, $data_info) = @_;
	my $step = 600;
	$data_info->step($step);
	$data_info->is_remote(1);

	my $n_top = 40;

	# RRDtool データソース名と項目名のリスト。
	# RRDtoolのデータソース名は19文字以内にする必要があるため、短縮名に変換する。
	my %rrd_headers = (
		# "NUM_EXEC_WITH_METRICS" => "NUM_EXEC",
		"STMT_EXEC_TIME"        => "EXEC_TIME",
		"TOTAL_CPU_TIME"        => "CPU_TIME",
		# "TOTAL_ACT_WAIT_TIME"   => "ACT_WAIT_TIME",
		# "LOCK_WAIT_TIME"        => "LOCK_WAIT_TIME",
		# "LOCK_WAITS"            => "LOCK_WAITS",
		# "DIRECT_READ_TIME"      => "DISK_READ_TIME",
		# "DIRECT_WRITE_TIME"     => "DISK_WRITE_TIME",
		# "ROWS_MODIFIED"         => "ROWS_MODIFIED",
		# "ROWS_READ"             => "ROWS_READ",
		# "DIRECT_WRITE_TIME"     => "DISK_WRITE_TIME",
		# "FED_WAIT_TIME"         => "FED_WAIT_TIME",
	);

	# RRDtool データソース名とSQLランクグラフタイトルと項目名のリスト
	my %graph_headers = (
		# "NUM_EXEC"        => "Weekly SQL Exec Ranking",
		"EXEC_TIME"       => "Weekly SQL Exec Average Time Ranking",
		"CPU_TIME"        => "Weekly SQL CPU Average Time Ranking",
		# "ACT_WAIT_TIME"   => "Weekly SQL Active Wait Time Ranking",
		# "LOCK_WAIT_TIME"  => "Weekly SQL Lock Wait Time Ranking",
		# "LOCK_WAITS"      => "Weekly SQL Lock Wait Ranking",
		# "DISK_READ_TIME"  => "Weekly Disk Read Time Ranking",
		# "DISK_WRITE_TIME" => "Weekly Disk Write Time Ranking",
		# "ROWS_MODIFIED"   => "Weekly Modified Rows Ranking",
		# "ROWS_READ"       => "Weekly Read Rows Ranking",
		# "FED_WAIT_TIME"   => "Weekly Federation Time Ranking",
	);

	my %rrd_headers_dummy = (
		"NUM_EXEC_WITH_METRICS" => "NUM_EXEC",
		"STMT_EXEC_TIME"        => "EXEC_TIME",
		"TOTAL_CPU_TIME"        => "CPU_TIME",
		"TOTAL_ACT_WAIT_TIME"   => "ACT_WAIT_TIME",
		"LOCK_WAIT_TIME"        => "LOCK_WAIT_TIME",
		"LOCK_WAITS"            => "LOCK_WAITS",
		"DIRECT_READ_TIME"      => "DISK_READ_TIME",
		"DIRECT_WRITE_TIME"     => "DISK_WRITE_TIME",
		"ROWS_MODIFIED"         => "ROWS_MODIFIED",
		"ROWS_READ"             => "ROWS_READ",
		"DIRECT_WRITE_TIME"     => "DISK_WRITE_TIME",
		"FED_WAIT_TIME"         => "FED_WAIT_TIME",
	);
	my @rrd_headers3 = sort values %rrd_headers_dummy;

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
		"    AND gi.graph_type_id in (7,8) " .
		"    AND g.title_cache = '__graph_title__' " .
		"ORDER BY gi.sequence";

	my $host = $data_info->file_suffix || $data_info->host;
	my $sec  = $data_info->start_time_sec->epoch;

	my $results;
	# SQL ランク表の検索。デバッグ用
	print "HOST:$host\n";
	# my $query = "select `stmtid`, `metric`, sum(`value`) ". 
#	my $query = "select `stmtid`, `metric`, avg(`value`) ". 
#				" from `db2_sql_rank` where `clock` > unix_timestamp() - 7*24*3600 ".
#				" and `member` like \"$host%\" " .
#               " and `metric` in ('TOTAL_CPU_TIME', 'STMT_EXEC_TIME') " .
#				" and `stmt_type_id` like 'DML%' " .
#				" group by `stmtid`, `metric`";

    my $query = "select `stmtid`, `metric`, sum(`sum_value`) / (7*24*6) ".
                " from `db2_sql_rank_daily` where `clock` > unix_timestamp() - 7*24*3600  ".
                " and `member` like \"$host%\"  ".
                " and `metric` in ('TOTAL_CPU_TIME', 'STMT_EXEC_TIME') ".
                " group by `stmtid`, `metric` ";

	# print "QUERY:$query\n";

	my $rows = $data_info->cacti_db_query($query);
	my @rrd_headers2 = sort values %rrd_headers;
	my $sql_stats;
	for my $row(@{$rows}) {
		my ($stmtid, $metric, $value) = @{$row};
		if (defined($rrd_headers{$metric})) {
			$metric = $rrd_headers{$metric};
		} else {
			next;
		}
		print "ROW:($stmtid, $metric, $value)\n";
		# $metric = 'NUM_EXEC' if ($metric eq 'NUM_EXEC_WITH_METRICS');

		$sql_stats->{$stmtid}{$metric} = $value;
		# $results->{$sec} = $value;
		# my $output = "Db2/${member}/device/db2_sql_rank_test__${metric}.txt";
		# $data_info->regist_device($member, 'Db2', 'db2_sql_rank_test', 
		# 					$metric, $metric, \@headers);
		# $data_info->simple_report($output, $results, \@headers);
	}
	my $reports;
	# print Dumper @rrd_headers2; exit;
	for my $header(@rrd_headers2) {
		# my $sql_stat = $sql_stats->{$instance};
		# # print "$instance,$header\n";
		# next if (!$sql_stat);
		# print Dumper $sql_stat;
		# sql_stat->{$header};
		# null 値は 0 で埋める
		for my $stmtid(keys %{$sql_stats}) {
			if (!defined($sql_stats->{$stmtid}{$header})) {
				$sql_stats->{$stmtid}{$header} = 0;
			}
		}
		# print Dumper $sql_stats;exit;
		my @sql_ranks = sort { $sql_stats->{$b}{$header} <=> $sql_stats->{$a}{$header} } keys %{$sql_stats};
		print "RANK:$header\n";
		my $rank = 1;
		my %registered_stmtid = ();
		for my $stmtid(@sql_ranks) {
			next if (defined($registered_stmtid{$stmtid}));
			$data_info->regist_device($host, 'Db2', 
				'db2_sql_top', $stmtid, undef, \@rrd_headers3);
			my $output = "Db2/${host}/device/db2_sql_top__${stmtid}.txt";
			my $results;
			$results->{0} = $sql_stats->{$stmtid};
			warn "RANK : $header, $rank, $stmtid, " . $sql_stats->{$stmtid}{$header} . "\n";
			$data_info->pivot_report($output, $results, \@rrd_headers3);
			$reports->{$host}{$header}{sprintf("%03d", $rank)} = {
				STMTID => $stmtid,
				VALUE => $sql_stats->{$stmtid}{$header},
			};
			$rank ++;
			$registered_stmtid{$stmtid} = 1;
			last if ($n_top < $rank);
		}
		my $ranks_n = scalar(@sql_ranks);
		my @sql_ranks_top_n;
		if ($ranks_n < $n_top) {
			@sql_ranks_top_n = (@sql_ranks, ('dummy') x ($n_top - $ranks_n));
		} else {
			@sql_ranks_top_n = @sql_ranks[0..$n_top-1];
		}
		# print Dumper \@sql_ranks_top_n;
		$data_info->regist_devices_alias($host, 'Db2', 'db2_sql_top',
											'weekly_db2_sql_top_by_' . $header,
											\@sql_ranks_top_n, undef);
		my $graph_header = $graph_headers{$header};
		# print Dumper $graph_header;exit;
		$rank = 1;
		for my $graph_title_suffix('', ' - 2', ' - 3', ' - 4') {
			my $graph_title = "Db2 - ${host} - " . $graph_header . $graph_title_suffix;
			my $query = $query_items;
			$query=~s/__graph_title__/${graph_title}/g;
			# print "QUERY:$query\n";
			if (my $rows = $data_info->cacti_db_query($query)) {
				for my $row(@$rows) {
					my $graph_templates_item_id = $row->[2] || 0;
					my $data_template_data_id   = $row->[4] || 0;
					my $sql_hash = shift(@sql_ranks);
					if ($sql_hash && $graph_templates_item_id && $data_template_data_id) {
						my $rra = "<path_rra>/Db2/${host}/device/db2_sql_top__${sql_hash}.rrd";
						$reports->{$host}{$header}{sprintf("%03d", $rank)}{TITLE} = $graph_title;
						$self->update_cacti_graph_item($data_info, $sql_hash, $graph_templates_item_id,
														$data_template_data_id, $rra);
					} else {
						my $rra = "<path_rra>/Db2/${host}/device/db2_sql_top__dummy.rrd";
						$self->update_cacti_graph_item($data_info, 'unkown', $graph_templates_item_id,
														$data_template_data_id, $rra);
					}
					$rank ++;
				}
			}
		}
	}
	# $self->purge_sql_hash_rrd_data($data_info, $host);
	# print Dumper $reports;
	my $report_file = file($data_info->absolute_storage_dir, "report_weekly_${host}.txt");
	print "REPORT: $report_file\n";
	my $writer = $report_file->open('w') or die $!;
	my $stmtid_keys;
	for my $member(keys %{$reports}) {
		for my $header(sort keys %{$reports->{$member}}) {
			for my $rank(sort keys %{$reports->{$member}{$header}}) {
				my $report = $reports->{$member}{$header}{$rank};
				my $stmtid = $report->{STMTID} || '';
				my $title = $report->{TITLE} || '';
				my $value = $report->{VALUE} || '';
				print("$member,$header,$rank,$title,$stmtid,$value\n");
				$writer->print("$member,$header,$rank,$title,$stmtid,$value\n");
				$stmtid_keys->{$stmtid} = 1;
			}
		}
	}
	my $stmtid_size = scalar keys %{$stmtid_keys};
	$writer->print("# STMTID : $stmtid_size\n");
	$writer->close;

	return 1;
}

1;
