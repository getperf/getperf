package Getperf::Command::Site::Db2::Db2MonDatabase;
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

my %metrics_v3 = (
'TOTAL_CONNECT_REQUEST_TIME'     , 'ConnectReqTime:DERIVE',
'TOTAL_CONNECT_REQUEST_PROC_TIME'     , 'ConnectReqProcTime:DERIVE',
'TOTAL_CONNECT_REQUESTS'     , 'ConnectReq:DERIVE',
'TOTAL_CONNECT_AUTHENTICATION_TIME'     , 'ConnectAuthTime:DERIVE',
'TOTAL_CONNECT_AUTHENTICATION_PROC_TIME'     , 'ConnectAuthProcTime:DERIVE',
'TOTAL_CONNECT_AUTHENTICATIONS'     , 'ConnectAuth:DERIVE',
'TOTAL_CONNECT_WAIT_TIME'     , 'ConnectWaitTime:DERIVE',
);

sub regist_results {
	my ($res, $host, $host_prefix, $sec, $header, $value) = @_;

	my $header2 = $header;
	$header2 =~s/:.+//g;
	if (defined($res->{$host}{$sec}{$header2})) {
		$res->{$host}{$sec}{$header2} += $value;
	}else {
		$res->{$host}{$sec}{$header2} = $value;
	}
	if (defined($res->{$host_prefix}{$sec}{$header2})) {
		$res->{$host_prefix}{$sec}{$header2} += $value;
	}else {
		$res->{$host_prefix}{$sec}{$header2} = $value;
	}
}

sub parse {
    my ($self, $data_info) = @_;
	my (%results, %results_v2, %results_v3, %devices_v3);
	my $step = 600;
	$data_info->step($step);
	$data_info->is_remote(1);
	my $host = $data_info->file_suffix;
	if ($host!~/01$/) {
		return;
	}
	my $host_prefix = $host;
	$host_prefix =~s/\d\d$//g;
	print "HOST:${host_prefix}\n";

	my $sec  = $data_info->start_time_sec->epoch;
	my %header_metrics = reverse %metrics;
	my @headers = keys %header_metrics;
	my %header_metrics2 = reverse %metrics_v2;
	my @headers2 = keys %header_metrics2;
	my %header_metrics3 = reverse %metrics_v3;
	my @headers3 = keys %header_metrics3;

	open( my $in, $data_info->input_file ) || die "@!";
	my $stats;
	while (my $line = <$in>) {
		$line=~s/(\r|\n)*//g;			# trim return code
		next if ($line!~/^([A-Z].+?)\s+(.+?)$/);
		my ($metric, $value) = ($1, $2);
		if ($metric eq 'TIMESTAMP') {
			my $sec_str = $value;
			$sec_str=~s/\..*//g;
			$sec = localtime(Time::Piece->strptime($sec_str, '%Y-%m-%d %H:%M:%S'))->epoch;
			$sec = $sec - $step;
		}
		if ($metric eq 'MEMBER') {
			$host = sprintf("%s%02d", $host_prefix, $value + 1);
			print "HOST:$host, $value\n";
		}
		$value = 0 if ($value eq 'null');
		$stats->{$metric}{$sec} = $value;
		my $header = $metrics{$metric};
		if ($header) {
			$value = $value * 1;
			regist_results(\%results, $host, $host_prefix, $sec, $header, $value);
		}
		$header = $metrics_v2{$metric};
		if ($header) {
			$value = $value * 1;
			regist_results(\%results_v2, $host, $host_prefix, $sec, $header, $value);
		}
		$header = $metrics_v3{$metric};
		if ($header) {
			$value = $value * 1;
			my $header3 = $header;
			$header3 =~s/:.+//g;
			regist_results(\%results_v3, $host, $host_prefix, $sec, $header, $value);
			# $results_v3{$sec}{$header3} = $value;
			# HEADER:ConnectReqTime
			# HEADER:ConnectReqProcTime
			if ($header3 eq 'ConnectReqProcTime') {
				my $wait_time = $results_v3{$host}{$sec}{'ConnectReqTime'} - $value;
				regist_results(\%results_v3, $host, $host_prefix, $sec, 'ConnectWaitTime', $wait_time);
			}
		}
	}
	close($in);
	# print Dumper \%results_v3;
	db2_update_stats($data_info, $host, 'mon_get_database', $stats);

	for my $host(keys %results) {
		$data_info->regist_metric($host, 'Db2', 'db2_mon_database', \@headers);
		my $output = "Db2/${host}/db2_mon_database.txt";	# Remote collection
		$data_info->pivot_report($output, \%{$results{$host}}, \@headers);
	}

	for my $host(keys %results_v2) {
		$data_info->regist_metric($host, 'Db2', 'db2_mon_database2', \@headers2);
		my $output = "Db2/${host}/db2_mon_database2.txt";	# Remote collection
		$data_info->pivot_report($output, \%{$results_v2{$host}}, \@headers2);
	}

	for my $host(keys %results_v3) {
		$data_info->regist_metric($host, 'Db2', 'db2_mon_database3', \@headers3);
		my $output = "Db2/${host}/db2_mon_database3.txt";	# Remote collection
		$data_info->pivot_report($output, \%{$results_v3{$host}}, \@headers3);

		if ($host =~/\d$/) {
			print "DEVICE:$host\n";
			$data_info->regist_device($host_prefix, 'Db2', 'db2_mon_database3_dev', 
				$host, $host, \@headers3);
			my $output_dev = "Db2/${host_prefix}/device/db2_mon_database3_dev__${host}.txt";	# Remote collection
			$data_info->pivot_report($output_dev, \%{$results_v3{$host}}, \@headers3);
		}

	}

	return 1;
}

1;
