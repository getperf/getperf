package Getperf::Command::Site::Oracle::SqlLoad;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use base qw(Getperf::Container);
use Getperf::Command::Master::Oracle;

sub new {bless{},+shift}

sub parse {
    my ($self, $data_info) = @_;

	my (%results);
	my $step = 60;
	my @headers = qw/executions:DERIVE disk_reads:DERIVE buffer_gets:DERIVE 
		rows_processed:DERIVE cpu_time:DERIVE elapsed_time:DERIVE 
		iowait_delta:DERIVE int_bytes:DERIVE offload_returned:DERIVE/;

	$data_info->step($step);
	$data_info->is_remote(1);
	my $instance = $data_info->file_suffix;
	my $sec  = $data_info->start_time_sec->epoch;
	if (!$sec) {
		return;
	}

	open( my $in, $data_info->input_file ) || die "@!";
	my $row = 0;
	my $sql = '';
	while (my $line = <$in>) {
		# print $line;
		$row ++;
		if ($row <= 3 || $line!~/^\d/) {
			next;
		}
		$line=~s/(\r|\n)*//g;			# trim return code
		my @values = ();
		my ($tms, $inst, $sql_id, $executions, $disk_reads, $buffer_gets, 
			$rows_processed, $cpu_time, $elapsed_time, 
			$iowait_delta, $int_bytes, $offload_returned
				) = split(/\s*\|\s*/, $line);
		$sql = $sql_id;

		$cpu_time = int($cpu_time*1000);
		$elapsed_time = int($elapsed_time*1000);
		$iowait_delta = int($iowait_delta*1000);
		# print "($tms, $inst, $sql_id)\n";
		# print Dumper \@values;
		$sec = localtime(Time::Piece->strptime($tms, '%Y/%m/%d %H:%M:%S'))->epoch;
		$results{$inst}->{$sql_id}->{$sec} = sprintf("%d %d %d %d %d %d %d %d %d",
			$executions, $disk_reads, $buffer_gets, 
			$rows_processed, $cpu_time, $elapsed_time, 
			$iowait_delta, $int_bytes, $offload_returned);
	}
	close($in);
	# print Dumper \%results;
	for my $inst(keys %results) {
		for my $sql_id (keys %{$results{$inst}}) {
			my $instance = "instance${inst}";
			$data_info->regist_device($sql_id, 'Oracle', 'sql_load', $instance, undef, \@headers);
			my $output = "Oracle/${sql_id}/device/sql_load__${instance}.txt";	# Remote collection
			$data_info->simple_report($output, $results{$inst}->{$sql_id}, \@headers);
		}
	}

	return 1;
}

1;
