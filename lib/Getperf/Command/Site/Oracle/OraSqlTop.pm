package Getperf::Command::Site::Oracle::OraSqlTop;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use Path::Class;
use base qw(Getperf::Container);
use Getperf::Command::Master::Oracle;

sub new {bless{},+shift}

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

	# purge storage/Oracle/{sid}/device/ora_sql_top__*.rrd
	my $rrdfile_filter = "$storage_dir/Oracle/$instance/device/ora_sql_top__\*.rrd";
	open (my $in, "ls $rrdfile_filter |") || die "can't find '$rrdfile_filter' : $!";
	while (my $rrdfile = <$in>) {
		chomp $rrdfile;
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
	my @headers = qw/executions disk_reads buffer_gets rows_processed cpu_time elapsed_time/;
	my %graph_headers = (
		"cpu_time"    => "SQL CPU Time Ranking",
		"buffer_gets" => "SQL Buffer Get Ranking",
		"disk_reads"  => "SQL Disk Read Ranking",
	);

	$data_info->step($step);
	$data_info->is_remote(1);
	my $instance = $data_info->file_suffix;
	my $sec  = $data_info->start_time_sec->epoch;
	if (!$sec) {
		return;
	}
	$self->purge_sql_hash_rrd_data($data_info, $instance);
	open( my $in, $data_info->input_file ) || die "@!";
	while (my $line = <$in>) {
		$line=~s/(\r|\n)*//g;			# trim return code
		if ($line=~/Date:(.*)/) {		# parse time: 16/05/23 14:56:52
			$sec = localtime(Time::Piece->strptime($1, '%y/%m/%d %H:%M:%S'))->epoch;
			next;
		}
		my ($timestamp, $sql_hash, @values) = split(/\s*\|\s*/, $line);
		next if (!defined($timestamp) || $timestamp =~ /TIME/);
		my $col = 0;
		map {
			my $header = $headers[$col];
			$results{$sql_hash}{$sec}{$header} = $_;
			$sql_stats{$sql_hash}{$header}    += $_;
			$col ++;
		} @values[0..5];
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
		"    AND gi.graph_type_id in (7, 8) " .
		"    AND g.title_cache = '__graph_title__' " .
		"ORDER BY gi.sequence";

	my %registered_sql_hash = ();
	for my $sort_key(qw/cpu_time buffer_gets disk_reads/) {
		my @sql_ranks = sort { $sql_stats{$b}{$sort_key} <=> $sql_stats{$a}{$sort_key} } keys %sql_stats;
		my $rank = 1;
		for my $sql_hash(@sql_ranks) {
			next if (defined($registered_sql_hash{$sql_hash}));
			$data_info->regist_device($instance, 'Oracle', 'ora_sql_top', $sql_hash, undef, \@headers);
			my $output = "Oracle/${instance}/device/ora_sql_top__${sql_hash}.txt";
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
		$data_info->regist_devices_alias($instance, 'Oracle', 'ora_sql_top',
		                                 'ora_sql_top_by_' . $sort_key,
		                                 \@sql_ranks_top_n, undef);

		my $graph_header = $graph_headers{$sort_key};
		for my $graph_title_suffix('', ' - 2', ' - 3', ' - 4') {
			my $graph_title = "Oracle - ${instance} - " . $graph_header . $graph_title_suffix;
			my $query = $query_items;
			$query=~s/__graph_title__/${graph_title}/g;
			if (my $rows = $data_info->cacti_db_query($query)) {
				for my $row(@$rows) {

					my $graph_templates_item_id = $row->[2] || 0;
					my $data_template_data_id   = $row->[4] || 0;
					my $sql_hash = shift(@sql_ranks);
					if ($sql_hash && $graph_templates_item_id && $data_template_data_id) {
						my $rra = "<path_rra>/Oracle/${instance}/device/ora_sql_top__${sql_hash}.rrd";
						$self->update_cacti_graph_item($data_info, $sql_hash, $graph_templates_item_id,
							                           $data_template_data_id, $rra);
					} else {
						my $rra = "<path_rra>/Oracle/${instance}/device/ora_sql_top__dummy.rrd";
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
