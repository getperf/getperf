package Getperf::Command::Site::Db2::Db2MonExtentLatchWait;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use base qw(Getperf::Container);
use Getperf::Command::Master::Db2;

sub new {bless{},+shift}

my %metrics = (
'TOTAL_EXTENDED_LATCH_WAIT_TIME',      'LATCH_WAIT_TIME:DERIVE',
'TOTAL_EXTENDED_LATCH_WAITS',          'LATCH_WAITS:DERIVE',
);

sub parse {
    my ($self, $data_info) = @_;

	my %results;
	my $step = 600;
	$data_info->step($step);
	$data_info->is_remote(1);
	my $host = $data_info->file_suffix || $data_info->host;
	my $sec  = $data_info->start_time_sec->epoch;
	my %header_metrics = reverse %metrics;
	my @headers = keys %header_metrics;
	my $host_prefix = $host;
	$host_prefix =~s/\d\d$//g;
	print "HOST:${host_prefix}\n";

	open( my $in, $data_info->input_file ) || die "@!";
	my $latch_name = 'Unkown';
	my $member = 0;
	my $stats;
	while (my $line = <$in>) {
		# print $line;
		$line=~s/(\r|\n)*//g;			# trim return code
		next if ($line!~/^([A-Z][A-Z].+?)\s+(.+?)$/);
		my ($metric, $value) = ($1, $2);
		next if ($metric eq 'TIMESTAMP');
		if ($metric eq 'MEMBER') {
			$member = $value;
			$host = sprintf("%s%02d", $host_prefix, $member + 1);
			# print "HOST:$host, $value\n";
		} elsif ($metric eq 'LATCH_NAME') {
			$latch_name = $value;
			$latch_name=~s/SQLO_LT_//g;
		} else {
			# my $device = "${latch_name},${service_superclass_name},${service_subclass_name}";
			# print "($host, $metric, $latch_name, $value)\n";
			$stats->{"$metric|${latch_name},${member}"}{$sec} = $value;
			my $header = $metrics{$metric};
			if ($header) {
				my $header2 = $header;
				$header2=~s/:.+//g;
				# print "($host, $metric, $header2, $value)\n";
				$results{$host}{$latch_name}{$sec}{$header2} = $value;
			}

		}
	}
	close($in);
	my $options = {'enable_first_load' => 1};
	db2_update_stats($data_info, $host, 'mon_get_extent_latch_wait', $stats, $options);
# print Dumper $stats;
	for my $host(keys %results) {
		for my $device(keys %{$results{$host}}) {
			my $device_results = $results{$host}{$device};
			$data_info->regist_device($host, 'Db2', 
				'mon_get_extent_latch_wait', $device, undef, \@headers);
			my $output = "Db2/${host}/device/mon_get_extent_latch_wait__${device}.txt";
print "$output\n";
			$data_info->pivot_report($output, $device_results, \@headers);
		}
	}

	return 1;
}

1;
