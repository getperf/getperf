package Getperf::Command::Site::Db2::MonDbSummary;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use base qw(Getperf::Container);
use Getperf::Command::Master::Db2;

sub new {bless{},+shift}

my %metrics = (
'TOTAL_APP_COMMITS'                       ,'APP_COMMITS:DERIVE',
'TOTAL_APP_ROLLBACKS'                     ,'APP_ROLLBACKS:DERIVE',
'ACT_COMPLETED_TOTAL'                     ,'ACT_COMPLETED:DERIVE',
'APP_RQSTS_COMPLETED_TOTAL'               ,'APP_RQSTS_COMPLETED:DERIVE',
'AVG_RQST_CPU_TIME'                       ,'AVG_RQST_CPU_TIME',
'ROUTINE_TIME_RQST_PERCENT'               ,'ROUTINE_RQST_PCT',
'RQST_WAIT_TIME_PERCENT'                  ,'RQST_WAIT_PCT',
'ACT_WAIT_TIME_PERCENT'                   ,'ACT_WAIT_PCT',
'IO_WAIT_TIME_PERCENT'                    ,'IO_WAIT_PCT',
'LOCK_WAIT_TIME_PERCENT'                  ,'LOCK_WAIT_PCT',
'AGENT_WAIT_TIME_PERCENT'                 ,'AGENT_WAIT_PCT',
'NETWORK_WAIT_TIME_PERCENT'               ,'NETWORK_WAIT_PCT',
'SECTION_PROC_TIME_PERCENT'               ,'SECTION_PCT',
'SECTION_SORT_PROC_TIME_PERCENT'          ,'SECTION_SORT_PCT',
'COMPILE_PROC_TIME_PERCENT'               ,'COMPILE_PCT',
'TRANSACT_END_PROC_TIME_PERCENT'          ,'TRANSACT_END_PCT',
'UTILS_PROC_TIME_PERCENT'                 ,'UTILS_PCT',
'AVG_LOCK_WAITS_PER_ACT'                  ,'AVG_LOCK_WAITS',
'AVG_LOCK_TIMEOUTS_PER_ACT'               ,'AVG_LOCK_TIMEOUTS',
'AVG_DEADLOCKS_PER_ACT'                   ,'AVG_DEADLOCKS',
'AVG_LOCK_ESCALS_PER_ACT'                 ,'AVG_LOCK_ESCALS',
'ROWS_READ_PER_ROWS_RETURNED'             ,'ROWS_READ_PER_ROWS',
'TOTAL_BP_HIT_RATIO_PERCENT'              ,'TOTAL_BP_HIT',
'TOTAL_GBP_HIT_RATIO_PERCENT'             ,'TOTAL_GBP_HIT',
'TOTAL_CACHING_TIER_HIT_RATIO_PERCENT'    ,'TOTAL_CACHING_HIT',
'CF_WAIT_TIME_PERCENT'                    ,'CF_WAIT_PCT',
'RECLAIM_WAIT_TIME_PERCENT'               ,'RECLAIM_WAIT_PCT',
'SPACEMAPPAGE_RECLAIM_WAIT_TIME_PERCENT'  ,'SMAP_RECLAIM_PCT',
);

sub parse {
    my ($self, $data_info) = @_;

	my %results;
	my $step = 5;
	my %header_metrics = reverse %metrics;
	my @headers = keys %header_metrics;

	$data_info->step($step);
	$data_info->is_remote(1);
	my $host = $data_info->file_suffix || $data_info->host;

	my $sec  = $data_info->start_time_sec->epoch;
	if (!$sec) {
		return;
	}
	open( my $in, $data_info->input_file ) || die "@!";
	while (my $line = <$in>) {
		$line=~s/(\r|\n)*//g;			# trim return code
		next if ($line!~/^([A-Z].+?)\s+(.+?)$/);
		my ($metric, $value) = ($1, $2);
		$value = 0 if ($value eq 'null');
		my $header = $metrics{$metric};
		if ($header) {
			my $header2 = $header;
			$header2=~s/:.+//g;
			print "($metric, $header2, $value)\n";
			$results{$sec}{$header2} = $value;
		}
	}
	close($in);
	print Dumper \%results;
	$data_info->regist_metric($host, 'Db2', 'mon_db_summary', \@headers);
	my $output = "Db2/${host}/mon_db_summary.txt";	# Remote collection
	$data_info->pivot_report($output, \%results, \@headers);
	return 1;
}

1;
