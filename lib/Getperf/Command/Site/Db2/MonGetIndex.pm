package Getperf::Command::Site::Db2::MonGetIndex;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use base qw(Getperf::Container);
use Getperf::Command::Master::Db2;

sub new {bless{},+shift}

my %metrics = (
'INDEX_SCANS'      , 'INDEX_SCANS:DERIVE',
'KEY_UPDATES'      , 'KEY_UPDATES:DERIVE',
'PSEUDO_DELETES'   , 'PSEUDO_DELETES:DERIVE',
'DEL_KEYS_CLEANED' , 'DEL_KEYS_CLEANED:DERIVE',
);

sub parse {
    my ($self, $data_info) = @_;

	my %results;
	my $step = 600;
	my %header_metrics = reverse %metrics;
	my @headers = keys %header_metrics;
	my $keywords = db2_mon_get_filter_keywords('mon_get_index');

	$data_info->step($step);
	$data_info->is_remote(1);
	my $host = $data_info->file_suffix || $data_info->host;
	my $sec  = $data_info->start_time_sec->epoch;

	open( my $in, $data_info->input_file ) || die "@!";
	my $tabschema = 'Unkown';
	my $tabname = 'Unkown';
	my $iid = 0;

	my $stats;
	while (my $line = <$in>) {
		# print $line;
		$line=~s/(\r|\n)*//g;			# trim return code
		next if ($line!~/^([A-Z][A-Z].+?)\s+(.+?)\s*$/);
		my ($metric, $value) = ($1, $2);
		if ($metric eq 'TABSCHEMA') {
			$tabschema = $value;
		} elsif ($metric eq 'TABNAME') {
			$tabname = $value;
		} elsif ($metric eq 'IID') {
			$iid = $value;
		} else {
			my $device = "${tabschema},${tabname},${iid}";
			$stats->{"$metric|$device"}{$sec} = $value;

			next if ($keywords && !$keywords->{$tabname});
			$value = 0 if ($value eq 'null' || $value!~/^\d+$/);
			my $header = $metrics{$metric};
			if ($header) {
				my $header2 = $header;
				$header2=~s/:.+//g;
				print "($tabname, $metric, $header2, $value)\n";
				$results{$device}{$sec}{$header2} = $value;
			}
		}
	}
	close($in);

	db2_update_stats($data_info, $host, 'mon_get_index', $stats);

	for my $device(keys %results) {
		my $device_results = $results{$device};
		$data_info->regist_device($host, 'Db2', 
			'mon_get_index', $device, undef, \@headers);
		my $output = "Db2/${host}/device/mon_get_index__${device}.txt";
		$data_info->pivot_report($output, $device_results, \@headers);
	}

	return 1;
}

1;
