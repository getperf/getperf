package Getperf::Command::Site::Db2::MonGetDatabase;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use base qw(Getperf::Container);
use Getperf::Command::Master::Db2;

sub new {bless{},+shift}

my %metrics = (
'LOCK_ESCALS',                    'LOCK_ESCALS:DERIVE',
'LOCK_TIMEOUTS',                  'LOCK_TMOUTS:DERIVE',
'LOCK_WAIT_TIME',                 'LOCK_WAIT_TM:DERIVE',
'LOCK_WAITS',                     'LOCK_WAITS:DERIVE',
'LOG_BUFFER_WAIT_TIME',           'LOG_BUFFER_WAIT_TM:DERIVE',
'LOG_DISK_WAIT_TIME',             'LOG_DISKWAIT_TM:DERIVE',
'LOG_DISK_WAITS_TOTAL',           'LOG_DISKWAIT_TOTAL:DERIVE',
'TOTAL_CPU_TIME',                 'CPU_TM:DERIVE',
'TOTAL_WAIT_TIME',                'WAIT_TM:DERIVE',
'CF_WAITS',                       'CF_WAITS:DERIVE',
'CF_WAIT_TIME',                   'CF_WAIT_TM:DERIVE',
'TOTAL_EXTENDED_LATCH_WAIT_TIME', 'EXTLATCH_WAIT_TM:DERIVE',
'TOTAL_EXTENDED_LATCH_WAITS',     'EXTLATCH_WAITS:DERIVE',
'TOTAL_SYNC_RUNSTATS_TIME',       'RUNSTATS_TM:DERIVE',
'TOTAL_SYNC_RUNSTATS_PROC_TIME',  'RUNSTATS_PROC_TM:DERIVE',
'TOTAL_SYNC_RUNSTATS',            'RUNSTATS:DERIVE',
);

my %metrics_v2 = (
'DEADLOCKS'	, 'DEADLOCKS:DERIVE',
);

sub parse {
    my ($self, $data_info) = @_;

	my (%results, %results_v2);
	my $step = 600;
	$data_info->step($step);
	$data_info->is_remote(1);
	my $host = $data_info->file_suffix || $data_info->host;
	my $sec  = $data_info->start_time_sec->epoch;
	my %header_metrics = reverse %metrics;
	my @headers = keys %header_metrics;
	my %header_metrics2 = reverse %metrics_v2;
	my @headers2 = keys %header_metrics2;

	open( my $in, $data_info->input_file ) || die "@!";
	my $stats;
	while (my $line = <$in>) {
		$line=~s/(\r|\n)*//g;			# trim return code
		next if ($line!~/^([A-Z][A-Z].+?)\s+(.+?)$/);
		my ($metric, $value) = ($1, $2);
		$stats->{$metric}{$sec} = $value;
		$value = 0 if ($value eq 'null');
		my $header = $metrics{$metric};
		if ($header) {
			$value = $value * 1;
			# print "($metric, $value)\n";
			my $header2 = $header;
			$header2 =~s/:.+//g;
			$results{$sec}{$header2} = $value;
		}
		$header = $metrics_v2{$metric};
		if ($header) {
			$value = $value * 1;
			my $header2 = $header;
			$header2 =~s/:.+//g;
			$results_v2{$sec}{$header2} = $value;
		}
	}
	close($in);
	print Dumper $stats;

	db2_update_stats($data_info, $host, 'mon_get_database', $stats);

	$data_info->regist_metric($host, 'Db2', 'db2_mon_database', \@headers);
	my $output = "Db2/${host}/db2_mon_database.txt";	# Remote collection
	$data_info->pivot_report($output, \%results, \@headers);

	$data_info->regist_metric($host, 'Db2', 'db2_mon_database2', \@headers2);
	$output = "Db2/${host}/db2_mon_database2.txt";	# Remote collection
	$data_info->pivot_report($output, \%results_v2, \@headers2);
	return 1;
}

1;
