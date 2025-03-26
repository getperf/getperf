package Getperf::Command::Site::Db2::Db2MonTablespace;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use base qw(Getperf::Container);
use Getperf::Command::Master::Db2;

my %metrics = (
'POOL_DATA_L_READS',     'DataLogicRds:DERIVE',
'POOL_DATA_P_READS',     'DataPhysRds:DERIVE',
'POOL_INDEX_L_READS',    'IndxLogicRds:DERIVE',
'POOL_INDEX_P_READS',    'IndxPhycRds:DERIVE',
'UNREAD_PREFETCH_PAGES', 'UnreadPages:DERIVE',
);

sub new {bless{},+shift}

sub parse {
    my ($self, $data_info) = @_;

	my %results;
	my $step = 600;
	my %header_metrics = reverse %metrics;
	my @headers = keys %header_metrics;
	my $keywords = db2_mon_get_filter_keywords('mon_get_tablespace');

	$data_info->step($step);
	$data_info->is_remote(1);
	my $host = $data_info->file_suffix || $data_info->host;
	my $sec  = $data_info->start_time_sec->epoch;
	$sec = $sec - $step;

	open( my $in, $data_info->input_file ) || die "@!";
	my $device = 'Unkown';
	my $stats;
	while (my $line = <$in>) {
		# print $line;
		$line=~s/(\r|\n)*//g;			# trim return code
		next if ($line!~/^([A-Z][A-Z].+?)\s+(.+?)\s*$/);
		my ($metric, $value) = ($1, $2);
		if ($metric eq 'TBSP_NAME') {
			$device = $value;
			# print "DEV:$device\n";
		} else {
			$stats->{"$metric|$device"}{$sec} = $value;
			$value = 0 if ($value eq 'null' || $value!~/\d+$/);
			my $header = $metrics{$metric};
			if ($header) {
				my $header2 = $header;
				$header2=~s/:.+//g;
				# print "($tabname, $metric, $header2, $value)\n";
				$results{$device}{$sec}{$header2} = $value;
			}
		}
	}
	close($in);

	db2_update_stats($data_info, $host, 'mon_get_tablespace', $stats);
	for my $device(keys %results) {
		my $device_results = $results{$device};
		$data_info->regist_device($host, 'Db2',
			'mon_get_tablespace', $device, undef, \@headers);
		my $output = "Db2/${host}/device/mon_get_tablespace__${device}.txt";
		$data_info->pivot_report($output, $device_results, \@headers);
	}
	return 1;
}

1;
