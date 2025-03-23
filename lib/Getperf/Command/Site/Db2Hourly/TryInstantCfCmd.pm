package Getperf::Command::Site::Db2Hourly::TryInstantCfCmd;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use base qw(Getperf::Container);
use Getperf::Command::Master::Db2;

sub new {bless{},+shift}

# Saving..
# METRIC_TIMESTAMP           2024-06-01 01:00:00.0   
# TOTAL_CF_REQUESTS          41762211
# TOTAL_CF_CMD_TIME_MICRO    18471376

my %metrics = (
'TOTAL_CF_REQUESTS'       ,'CF_REQUESTS',
'TOTAL_CF_CMD_TIME_MICRO' ,'CF_CMD_TIME_MICRO',
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
		print $line;
		$line=~s/(\r|\n)*//g;			# trim return code
		next if ($line!~/^([A-Z].+?)\s+(.+?)$/);
		my ($metric, $value) = ($1, $2);
		$value = 0 if ($value eq 'null');
		my $header = $metrics{$metric};
		if ($metric eq 'METRIC_TIMESTAMP') {
			$value =~s/\.\d+\s*//g;
			$sec = localtime(Time::Piece->strptime($value, '%Y-%m-%d %H:%M:%S'))->epoch;
			print "TIME: $value,$sec\n";
		} elsif ($header) {
			$value = $value * 1;
			# print "($metric, $value)\n";
			my $header2 = $header;
			$header2 =~s/:.+//g;
			$results{$host}{$sec}{$header2} = $value;
		}
		$stats->{$metric}{$sec} = $value;
	}
	close($in);
	print Dumper $stats;
	for my $cfhost(keys %results) {
		my $cfresults = $results{$cfhost};
		$data_info->regist_metric($cfhost, 'Db2', 'try_instant_cf_cmd', \@headers);
		my $output = "Db2/${cfhost}/try_instant_cf_cmd.txt";	# Remote collection
		$data_info->pivot_report($output, $cfresults, \@headers);
	}
	# my $opt = {
	# 	'stat_threshold' => 3,
	# };
	my $options = {'enable_first_load' => 1, 'regist_abs' => 1};
	db2_update_stats($data_info, $host, 'mon_get_cf_cmd_tryinstant', $stats, $options);
	return 1;
}

1;
