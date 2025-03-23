package Getperf::Command::Site::Db2::ActiveEvent;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use base qw(Getperf::Container);
use Getperf::Command::Master::Db2;

sub new {bless{},+shift}

my $TENANT = 'DB2V';
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
	my $rrdfile_filter = "$storage_dir/Db2/$instance/device/db2_sql_top__\*.rrd";
	open (my $in, "ls $rrdfile_filter |") || die "can't find '$rrdfile_filter' : $!";
	while (my $rrdfile = <$in>) {
		chomp $rrdfile;
		if ($rrdfile =~/dummy/) {
			next;
		}
		# print "purge $rrdfile\n";
		my $updated = (stat($rrdfile))[8];
		if ($updated < $limit_time) {
			unlink $rrdfile;
		}
	}
	close($in);
}

sub parse {
    my ($self, $data_info) = @_;

	my (%results, %sql_stats);
	my $step = 3600;
	my $n_top = 40;
	my @headers = qw/cpu_time elapsed_time/;

	my %graph_headers = (
		"cpu_time"     => "SQL CPU Time Ranking",
		"elapsed_time" => "SQL Elapsed Time Ranking",
	);

	$data_info->step($step);
	$data_info->is_remote(1);

    my $instance = $data_info->file_suffix;
	print "INSTANCE1:$instance\n";
    my $sec  = $data_info->start_time_sec->epoch;
	if (!$sec) {
		return;
	}
	$self->purge_sql_hash_rrd_data($data_info, $instance);
	open( my $in, $data_info->input_file ) || die "@!";
	while (my $line = <$in>) {
		$line=~s/(\r|\n)*//g;			# trim return code
		if ($line=~/Date:(.*)/) {               # parse time: 16/05/23 14:56:52
			$sec = localtime(Time::Piece->strptime($1, '%y/%m/%d %H:%M:%S'))->epoch;
			next;
		}
		# STMTID        
		# TOTAL_EXEC_TIME 0
		# NUMBER_OF_EXEC 1
		# EXEC_TIME_PER_SQL 2         
		# TOTAL_CPU_TIME 3
		# CPU_TIME_PER_SQL 4

		# my ($left_null, $appl_id,$uow_id,$activity_id,$started, @values) = split(/\s*[\|,]\s*/, $line);
		my ($left_null, $stmtid, @values) = split(/\s*[\|,]\s*/, $line);
		my $n = scalar(@values);
		next if (scalar(@values) == 0 || $stmtid eq 'STMTID');

		my $sql_hash = $stmtid || 'empty';
		my %colum_indexes = ('cpu_time'=>3, 'elapsed_time' => 0);
		for my $header (keys %colum_indexes) {
			my $column_index = $colum_indexes{$header};
			my $value = $values[$column_index];
			$results{$sql_hash}{$sec}{$header} = $value || 0;
			$sql_stats{$sql_hash}{$header}    += $value || 0;
		}
		# my ($timestamp, $plan_hash, $sql_hash, $sql_hash2, @values) = split(/\s*[\|,]\s*/, $line);
		# next if (!defined($timestamp) || $timestamp eq 'TIME');
		# for my $col () {
		# 	my $header = $headers[$col];
		# 	my $value = $values[$col];
		# 	$results{$sql_hash}{$sec}{$header} = $value || 0;
		# 	$sql_stats{$sql_hash}{$header}    += $value || 0;
		# }
	}
	close($in);
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
		"    AND gi.graph_type_id in (8, 7) " .
		"    AND g.title_cache = '__graph_title__' " .
		"ORDER BY gi.sequence";

	my %registered_sql_hash = ();
	for my $sort_key(qw/cpu_time elapsed_time/) {
		my @sql_ranks = sort { $sql_stats{$b}{$sort_key} <=> $sql_stats{$a}{$sort_key} } keys %sql_stats;
	# print Dumper \@sql_ranks;
		my $rank = 1;
		for my $sql_hash(@sql_ranks) {
			next if (defined($registered_sql_hash{$sql_hash}));
			$data_info->regist_device($instance, 'Db2', 'db2_sql_top', $sql_hash, undef, \@headers);
			my $output = "Db2/${instance}/device/db2_sql_top__${sql_hash}.txt";
			$data_info->pivot_report($output, $results{$sql_hash}, \@headers);
			$rank ++;
			$registered_sql_hash{$sql_hash} = 1;
			last if ($n_top < $rank);
		}
		my $ranks_n = scalar(@sql_ranks);
		my @sql_ranks_top_n;
		if ($ranks_n < $n_top) {
			@sql_ranks_top_n = (@sql_ranks, ('dummy') x ($n_top - $ranks_n));
		} else {
			@sql_ranks_top_n = @sql_ranks[0..$n_top-1];
		}
		$data_info->regist_devices_alias($instance, 'Db2', 'db2_sql_top',
		                                 'db2_sql_top_by_' . $sort_key,
		                                 \@sql_ranks_top_n, undef);

		my $graph_header = $graph_headers{$sort_key};
		for my $graph_title_suffix('', ' - 2', ' - 3', ' - 4') {
			my $graph_title = "Db2 - ${instance} - " . $graph_header . 
				' - ' . $TENANT .  $graph_title_suffix;
			my $query = $query_items;
			$query=~s/__graph_title__/${graph_title}/g;
			if (my $rows = $data_info->cacti_db_query($query)) {
			# print Dumper \@sql_ranks;
				for my $row(@$rows) {
					my $graph_templates_item_id = $row->[2] || 0;
					my $data_template_data_id   = $row->[4] || 0;
					my $sql_hash = shift(@sql_ranks);
					# print "$sql_hash && $graph_templates_item_id && $data_template_data_id\n";
					if ($sql_hash && $graph_templates_item_id && $data_template_data_id) {
						my $rra = "<path_rra>/Db2/${instance}/device/db2_sql_top__${sql_hash}.rrd";
						$self->update_cacti_graph_item($data_info, $sql_hash, $graph_templates_item_id,
							                           $data_template_data_id, $rra);
					} else {
						my $rra = "<path_rra>/Db2/${instance}/device/db2_sql_top__dummy.rrd";
						$self->update_cacti_graph_item($data_info,, 'unkown', 
							$graph_templates_item_id,
							$data_template_data_id, $rra);
					}
				}
			}
		}
	}

	return 1;
}

1;
