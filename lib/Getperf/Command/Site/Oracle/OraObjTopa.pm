package Getperf::Command::Site::Oracle::OraObjTopa;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use base qw(Getperf::Container);
use Getperf::Command::Master::Oracle;

sub new {bless{},+shift}

my $PURGE_RRD_HOUR = 3 * 24;

sub update_cacti_graph_item {
	my ($self, $data_info, $obj_key, $graph_templates_item_id, $data_template_data_id, $rra ) = @_;

	my $update_item =
		"UPDATE graph_templates_item " .
		"SET text_format = '$obj_key' " .
		"WHERE id = $graph_templates_item_id";
	$data_info->cacti_db_dml($update_item);

	my $update_rrd =
		"UPDATE data_template_data " .
		"SET data_source_path = '$rra' " .
		"WHERE id = $data_template_data_id";
	$data_info->cacti_db_dml($update_rrd);
}

sub purge_object_rank_rrd_data {
	my ($self, $data_info, $instance) = @_;

	my $storage_dir = $data_info->{absolute_storage_dir};
	my $limit_time  = $data_info->start_time_sec->epoch - $PURGE_RRD_HOUR * 3600;

	# purge storage/Oracle/{sid}/device/ora_obj_top__*.rrd
	my $rrdfile_filter = "$storage_dir/Oracle/$instance/device/ora_obj_top__\*.rrd";
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

	my (%results, %obj_stats);
	my $step = 3600;
	my $n_top = 40;
	my @headers = qw/logical_reads lr_ratio physical_reads pr_ratio physical_writes rw_ratio/;

	my %graph_headers = (
		"logical_reads"   => "Object Logical Read Ranking",
		"physical_reads"  => "Object Physical Read Ranking",
		"physical_writes" => "Object Physical Write Ranking",
	);

	$data_info->step($step);
	$data_info->is_remote(1);
    my $instance = $data_info->file_suffix;
	my $sec  = $data_info->start_time_sec->epoch;
	if (!$sec) {
		return;
	}
	$self->purge_object_rank_rrd_data($data_info, $instance);
	open( my $in, $data_info->input_file ) || die "@!";
	while (my $line = <$in>) {
		$line=~s/(\r|\n)*//g;			# trim return code
		if ($line=~/Date:(.*)/) {		# parse time: 16/05/23 14:56:52
			$sec = localtime(Time::Piece->strptime($1, '%y/%m/%d %H:%M:%S'))->epoch;
			next;
		}
		my ($timestamp, $owner, $segment_name, $bytes, $buffer_type, $object_type, $tablespace_name, @values) = split(/\s*[\|,]\s*/, $line);
		next if (!defined($timestamp) || $timestamp eq 'TIME');
		my $object_key = join('.', $object_type || '', $owner || '', $segment_name || '');
		$object_key=~s/[\$\s\\]/_/g;
		$object_key=~s/(\()(.+?)(\))/_$2/g;
		my $col = 0;
		map {
			my $header = $headers[$col];
			$results{$object_key}{$sec}{$header} = $_ || 0;
			$obj_stats{$object_key}{$header}    += $_ || 0;
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
		"    AND gi.graph_type_id in (4) " .
		"    AND g.title_cache = '__graph_title__' " .
		"ORDER BY gi.sequence";

	for my $sort_key(qw/logical_reads physical_reads physical_writes/) {
		my @obj_ranks = sort { $obj_stats{$b}{$sort_key} <=> $obj_stats{$a}{$sort_key} } keys %obj_stats;
		my $rank = 1;
		for my $obj_key(@obj_ranks) {
			$data_info->regist_device($instance, 'Oracle', 'ora_obj_top', $obj_key, undef, \@headers);
			my $output = "Oracle/${instance}/device/ora_obj_top__${obj_key}.txt";
			$data_info->pivot_report($output, $results{$obj_key}, \@headers);
			$rank ++;
			last if ($n_top < $rank);
		}
		my $ranks_n = scalar(@obj_ranks);
		my @obj_ranks_top_n;
		if ($ranks_n < $n_top) {
			@obj_ranks_top_n = (@obj_ranks, ('dummy') x ($n_top - $ranks_n));
		} else {
			@obj_ranks_top_n = @obj_ranks[0..$n_top-1];
		}
		$data_info->regist_devices_alias($instance, 'Oracle', 'ora_obj_top',
		                                 'ora_obj_top_by_' . $sort_key,
		                                 \@obj_ranks_top_n, undef);

		my $graph_header = $graph_headers{$sort_key};
		for my $graph_title_suffix('', ' - 2', ' - 3', ' - 4') {
			my $graph_title = "Oracle - ${instance} - " . $graph_header . $graph_title_suffix;
			my $query = $query_items;
			$query=~s/__graph_title__/${graph_title}/g;
			if (my $rows = $data_info->cacti_db_query($query)) {
				for my $row(@$rows) {
					my $graph_templates_item_id = $row->[2] || 0;
					my $data_template_data_id   = $row->[4] || 0;
					my $obj_key = shift(@obj_ranks);
					if ($obj_key && $graph_templates_item_id && $data_template_data_id) {
						my $rra = "<path_rra>/Oracle/${instance}/device/ora_obj_top__${obj_key}.rrd";
						$self->update_cacti_graph_item($data_info, $obj_key, $graph_templates_item_id,
							                           $data_template_data_id, $rra);
					} else {
						my $rra = "<path_rra>/Oracle/${instance}/device/ora_obj_top__dummy.rrd";
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
