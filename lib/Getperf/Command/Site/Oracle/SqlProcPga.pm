package Getperf::Command::Site::Oracle::SqlProcPga;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
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

	# purge storage/Oracle/{sid}/device/sql_proc_pga__*.rrd
	my $rrdfile_filter = "$storage_dir/Oracle/$instance/device/sql_proc_pga__\*.rrd";
	open (my $in, "ls $rrdfile_filter | grep -v dummy |") || die "can't find '$rrdfile_filter' : $!";
	while (my $rrdfile = <$in>) {
		# print $rrdfile;
		chomp $rrdfile;
		next if ($rrdfile=~/dummy/);
		my $updated = (stat($rrdfile))[8];
		if ($updated < $limit_time) {
			unlink $rrdfile;
		}
	}
	close($in);
}

sub parse {
    my ($self, $data_info) = @_;

	my (%results, $sql_stats);
	my $step = 600;
	my $n_top = 10;
	my @headers = qw/
        pga_alloc_mem
	/;

	my %graph_headers = (
		"pga_alloc_mem" => "PGA Memory Usage Ranking",
	);

	$data_info->step($step);
	$data_info->is_remote(1);

	my $instance = $data_info->file_suffix;
	print ("INSTANCE:$instance\n");
   my $sec  = $data_info->start_time_sec->epoch;
	if (!$sec) {
		return;
	}
	$self->purge_sql_hash_rrd_data($data_info, $instance);
	open( my $in, $data_info->input_file ) || die "@!";
	while (my $line = <$in>) {
		print $line;
		$line=~s/(\r|\n)*//g;			# trim return code
		next if ($line !~/^\d+/);
		my ($time, $inst_id, $program, @values) = split(/\s*\|\s*/, $line);
		$program=~s/[@ \(\)]/_/g;	# trim '@'... from oracle@kc-test03 (MMON)
		$program=~s/_$//g;
		# print "$program\n";
		# if ($line=~/Date:(.*)/) {               # parse time: 16/05/23 14:56:52
		# 	$sec = localtime(Time::Piece->strptime($1, '%y/%m/%d %H:%M:%S'))->epoch;
		# 	next;
		# }
		for my $col (0..0) {
			my $header = $headers[$col];
			my $value = $values[$col];
			my $instance_by_id = $instance;
			$instance_by_id = "${instance}_${inst_id}" if ($inst_id > 1);
			$results{$instance_by_id}{$program}{$sec}{$header} = $value || 0;
			$sql_stats->{$instance_by_id}{$program}{$header}    += $value || 0;
		}
	}
	close($in);
	# print Dumper \%results;
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
		"    AND gi.graph_type_id in (4, 7, 8) " .
		"    AND g.title_cache = '__graph_title__' " .
		"ORDER BY gi.sequence";

	# print Dumper \%results;
	for my $instance(keys %results) {
		my %registered_sql_hash = ();
		for my $sort_key(qw/pga_alloc_mem/) {
			my %sql_stats2 = %{$sql_stats->{$instance}};
			my @sql_ranks = sort { $sql_stats2{$b}{$sort_key} <=> $sql_stats2{$a}{$sort_key} } keys %sql_stats2;
			my $rank = 1;
			for my $sql_hash(@sql_ranks) {
				next if (defined($registered_sql_hash{$sql_hash}));
				$data_info->regist_device($instance, 'Oracle', 'sql_proc_pga', $sql_hash, undef, \@headers);
				my $output = "Oracle/${instance}/device/sql_proc_pga__${sql_hash}.txt";
				$data_info->pivot_report($output, $results{$instance}{$sql_hash}, \@headers);
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
			$data_info->regist_devices_alias($instance, 'Oracle', 'sql_proc_pga',
			                                 'sql_proc_pga_by_' . $sort_key,
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
							my $rra = "<path_rra>/Oracle/${instance}/device/sql_proc_pga__${sql_hash}.rrd";
							$self->update_cacti_graph_item($data_info, $sql_hash, $graph_templates_item_id,
								                           $data_template_data_id, $rra);
						} else {
							my $rra = "<path_rra>/Oracle/${instance}/device/sql_proc_pga__dummy.rrd";
							$self->update_cacti_graph_item($data_info,, 'unkown', $graph_templates_item_id,
								                           $data_template_data_id, $rra);
						}
					}
				}
			}
		}
	}

	return 1;
}

1;
