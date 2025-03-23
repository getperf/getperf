package Getperf::Command::Site::Db2::Db2MonWorkload;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use base qw(Getperf::Container);
use Getperf::Command::Master::Db2;

sub new {bless{},+shift}

my %metrics = (
'TOTAL_CPU_TIME', 'TOTAL_CPU_TIME:DERIVE',
'ACT_COMPLETED_TOTAL', 'ACT_COMPLETED_TOTAL:DERIVE',
'ACT_ABORTED_TOTAL', 'ACT_ABORTED_TOTAL:DERIVE',
'ACT_REJECTED_TOTAL', 'ACT_REJECTED_TOTAL:DERIVE',
'APP_RQSTS_COMPLETED_TOTAL', 'APP_RQSTS_COMPLETED:DERIVE',
'WLM_QUEUE_ASSIGNMENTS_TOTAL', 'WLM_QUE_ASSIGNMENTS:DERIVE',
'ROWS_READ', 'ROWS_READ:DERIVE',
'ROWS_MODIFIED', 'ROWS_MODIFIED:DERIVE',
'ROWS_RETURNED', 'ROWS_RETURNED:DERIVE',
'DIRECT_READS', 'DIRECT_READS:DERIVE',
'DIRECT_WRITES', 'DIRECT_WRITES:DERIVE',
'LOCK_WAITS', 'LOCK_WAITS:DERIVE',
'LOCK_WAIT_TIME', 'LOCK_WAIT_TIME:DERIVE',
'LOCK_TIMEOUTS', 'LOCK_TIMEOUTS:DERIVE',
'LOCK_ESCALS', 'LOCK_ESCALS:DERIVE',
'DEADLOCKS', 'DEADLOCKS:DERIVE',
'THRESH_VIOLATIONS', 'THRESH_VIOLATIONS:DERIVE',
'TOTAL_SORTS', 'TOTAL_SORTS:DERIVE',
'SORT_OVERFLOWS', 'SORT_OVERFLOWS:DERIVE',
'TOTAL_HASH_GRPBYS', 'TOTAL_HASH_GRPBYS:DERIVE',
'HASH_GRPBY_OVERFLOWS', 'HASH_GRP_OVERFLOWS:DERIVE',
'TOTAL_APP_COMMITS', 'TOTAL_APP_COMMITS:DERIVE',
'TOTAL_COMMIT_TIME', 'TOTAL_COMMIT_TIME:DERIVE',
);

sub parse {
    my ($self, $data_info) = @_;
	my (%results, %results_v2);
	my $step = 600;
	my %header_metrics = reverse %metrics;
	my @headers = keys %header_metrics;
	my @headers_v2 = qw/SELECT_SQL_STMTS:DERIVE UID_SQL_STMTS:DERIVE/;
	my $keywords = db2_mon_get_filter_keywords('mon_get_workload');

	$data_info->step($step);
	$data_info->is_remote(1);
	my $host = $data_info->file_suffix || $data_info->host;
	my $sec  = $data_info->start_time_sec->epoch;

	open( my $in, $data_info->input_file ) || die "@!";
	my $device = 'Unkown';

	my $stats;
	while (my $line = <$in>) {
		# print $line;
		$line=~s/(\r|\n)*//g;			# trim return code
		next if ($line!~/^([A-Z][A-Z].+?)\s+(.+?)$/);
		my ($metric, $value) = ($1, $2);
		if ($metric eq 'WORKLOAD_NAME') {
			$device = $value;
		} else {
			$stats->{"$metric|$device"}{$sec} = $value;
			$value = 0 if ($value eq 'null' || $value!~/^\d+$/);
			my $header = $metrics{$metric};
			if ($header) {
				my $header2 = $header;
				$header2=~s/:.+//g;
				$device=~s/SYSDEFAULT//g;
				# print "($device, $metric, $header2, $value)\n";
				$results{$device}{$sec}{$header2} = $value;
			}
			if ($metric=~/(UID|SELECT)_SQL_STMTS/) {
				$results_v2{$device}{$sec}{$metric} = $value;
				# print "$metric,$line\n"; 
			}
		}
	}
	close($in);
	db2_update_stats($data_info, $host, 'mon_get_workload', $stats);
	for my $device(keys %results) {
		my $device_results = $results{$device};
		$data_info->regist_device($host, 'Db2', 
			'mon_get_workload', $device, undef, \@headers);
		my $output = "Db2/${host}/device/mon_get_workload__${device}.txt";
		$data_info->pivot_report($output, $device_results, \@headers);
	}
	print Dumper \%results_v2;
	for my $device(keys %results_v2) {
		my $device_results = $results_v2{$device};
		$data_info->regist_device($host, 'Db2', 
			'mon_get_workload_v2', $device, undef, \@headers_v2);
		my $output = "Db2/${host}/device/mon_get_workload_v2__${device}.txt";
		$data_info->pivot_report($output, $device_results, \@headers_v2);
	}
	return 1;
}

1;
