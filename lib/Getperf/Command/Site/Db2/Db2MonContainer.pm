package Getperf::Command::Site::Db2::Db2MonContainer;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use base qw(Getperf::Container);
use Getperf::Command::Master::Db2;

sub new {bless{},+shift}

my %metrics = (
'POOL_READ_TIME' ,  'POOL_READ_TIME:DERIVE',
'POOL_WRITE_TIME' , 'POOL_WRITE_TIME:DERIVE',
);

sub parse {
    my ($self, $data_info) = @_;

	my %results;
	my $step = 600;
	my %header_metrics = reverse %metrics;
	my @headers = keys %header_metrics;
	my $keywords = db2_mon_get_filter_keywords('mon_get_container');

	$data_info->step($step);
	$data_info->is_remote(1);
	my $host = $data_info->file_suffix || $data_info->host;
	my $sec  = $data_info->start_time_sec->epoch;
	$sec = $sec - $step;

	open( my $in, $data_info->input_file ) || die "@!";
	my $tbsp_name = 'Unkown';
	my $container_name = 'Unkown';
	my $container_name_suffix = 'Unkown';

	my $stats;
	while (my $line = <$in>) {
		# print $line;
		$line=~s/(\r|\n)*//g;			# trim return code
		next if ($line!~/^([A-Z][A-Z].+?)\s+(.+?)$/);
		my ($metric, $value) = ($1, $2);
		if ($metric eq 'TBSP_NAME') {
			$tbsp_name = $value;
		} elsif ($metric eq 'CONTAINER_NAME') {
			$container_name = $value;
			$container_name_suffix = $value;
			$container_name_suffix=~s/^.*NODE\d+\///g;
		} else {
			my $device = "${tbsp_name},${container_name}";
			$stats->{"$metric|${device}"}{$sec} = $value;

			my $device2 = "${tbsp_name},${container_name_suffix}";
			next if ($keywords && !$keywords->{$tbsp_name});
			$value = 0 if ($value eq 'null' || $value!~/^\d+$/);
			my $header = $metrics{$metric};
			if ($header) {
				my $header2 = $header;
				$header2=~s/:.+//g;
				# print "($tbsp_name, $metric, $header2, $value)\n";
				$results{$device2}{$sec}{$header2} = $value;
			}

		}
	}
	close($in);
	# print Dumper \%results;
	db2_update_stats($data_info, $host, 'mon_get_container', $stats);
	for my $device(keys %results) {
		my $device_results = $results{$device};
		$data_info->regist_device($host, 'Db2', 
			'mon_get_container', $device, undef, \@headers);
		my $output = "Db2/${host}/device/mon_get_container__${device}.txt";
		$data_info->pivot_report($output, $device_results, \@headers);
	}

	return 1;
}

1;
