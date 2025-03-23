package Getperf::Command::Site::Db2::Db2MonCf;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use base qw(Getperf::Container);
use Getperf::Command::Master::Db2;

sub new {bless{},+shift}

my %metrics = (
'CURRENT_CF_GBP_SIZE'      ,'CURRENT_CF_GBP',
'CONFIGURED_CF_GBP_SIZE'   ,'CONFIGURED_CF_GBP',
'TARGET_CF_GBP_SIZE'       ,'TARGET_CF_GBP',
'CURRENT_CF_LOCK_SIZE'     ,'CURRENT_CF_LOCK',
'CONFIGURED_CF_LOCK_SIZE'  ,'CONFIGURED_CF_LOCK',
'TARGET_CF_LOCK_SIZE'      ,'TARGET_CF_LOCK',
'CURRENT_CF_SCA_SIZE'      ,'CURRENT_CF_SCA',
'CONFIGURED_CF_SCA_SIZE'   ,'CONFIGURED_CF_SCA',
'TARGET_CF_SCA_SIZE'       ,'TARGET_CF_SCA',
'CURRENT_CF_MEM_SIZE'      ,'CURRENT_CF_MEM',
'CONFIGURED_CF_MEM_SIZE'   ,'CONFIGURED_CF_MEM',
);

sub parse {
    my ($self, $data_info) = @_;

	my %results;
	my $step = 600;
	$data_info->step($step);
	$data_info->is_remote(1);
	my $host = $data_info->file_suffix;
	my $sec  = $data_info->start_time_sec->epoch;
	$sec = $sec - $step;
	my %header_metrics = reverse %metrics;
	my @headers = keys %header_metrics;

	open( my $in, $data_info->input_file ) || die "@!";
	my $stats;
	while (my $line = <$in>) {
		$line=~s/(\r|\n)*//g;			# trim return code
		next if ($line!~/^([A-Z].+?)\s+(.+?)$/);
		my ($metric, $value) = ($1, $2);
		if ($metric eq 'HOST_NAME') {
			$host = $value;
			$host=~s/\.local//g;
			$host=~s/k2/k1/g;
		}
		print "HOST:$host\n";
		$value = 0 if ($value eq 'null');
		my $header = $metrics{$metric};
		if ($header) {
			$value = $value * 1;
			# print "($metric, $value)\n";
			my $header2 = $header;
			$header2 =~s/:.+//g;
			$results{$host}{$sec}{$header2} = $value;
		}
		$stats->{$metric}{$sec} = $value;
	}
	close($in);
	# print Dumper \%results;
	for my $cfhost(keys %results) {
		my $cfresults = $results{$cfhost};
		$data_info->regist_metric($cfhost, 'Db2', 'db2_mon_cf', \@headers);
		my $output = "Db2/${cfhost}/db2_mon_cf.txt";	# Remote collection
		$data_info->pivot_report($output, $cfresults, \@headers);
	}
	# my $opt = {
	# 	'stat_threshold' => 3,
	# };
	db2_update_stats($data_info, $host, 'mon_get_cf', $stats);
	return 1;
}

1;
