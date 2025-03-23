package Getperf::Command::Site::Db2::Db2MonIndex;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use base qw(Getperf::Container);
use Getperf::Command::Master::Db2;

my %metrics = (
	'INDEX_SCANS'      , 'INDEX_SCANS:DERIVE',
	'KEY_UPDATES'      , 'KEY_UPDATES:DERIVE',
	'PSEUDO_DELETES'   , 'PSEUDO_DELETES:DERIVE',
	'DEL_KEYS_CLEANED' , 'DEL_KEYS_CLEANED:DERIVE',
);

sub new {bless{},+shift}

sub parse {
    my ($self, $data_info) = @_;
print "SKIP monitoring for tuning 20230315\n";
return;


	my $results;
	my $step = 600;
	my %header_metrics = reverse %metrics;
	my @headers = keys %header_metrics;
	my $keywords = db2_mon_get_filter_keywords('mon_get_index');

	$data_info->step($step);
	$data_info->is_remote(1);
	my $host = $data_info->file_suffix || $data_info->host;
	my $sec  = $data_info->start_time_sec->epoch;
	$sec = $sec - $step;

	open( my $in, $data_info->input_file ) || die "@!";
	my $tabschema = 'Unkown';
	my $tabname = 'Unkown';
	my $indname = 'Unkown';
	my $tabname_postfix;

	my $schemas;
	my $ranks;
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
			$tabname_postfix = $tabname;
			$tabname_postfix = $1 if ($tabname_postfix =~/^(.+)_\d\d\d\d+$/);
		} elsif ($metric eq 'INDNAME') {
			$indname = $value;
		} else {
			if ($tabschema =~/(IBMCOMPAT|Unkown|SYSIBM|SYSTOOLS|SYSPROC|\s+)/) {
				next;
			}
			$schemas->{$tabschema} = 1;
			my $device = "${tabschema},${tabname},${indname}";

			# next if ($keywords && !$keywords->{$tabname});
			next if ($value eq 'null');
			$stats->{"$metric|$device"}{$sec} = $value;

			$value = 0 if ($value!~/^\d+$/);
			my $header = $metrics{$metric};
			if ($header) {
				my $header2 = $header;
				$header2=~s/:.+//g;
				# print "(${tabname_postfix}, $indname, $metric, $header2, $value)\n";
				my $device2 = "${tabschema},${tabname_postfix},${indname}";
				if (defined($results->{$device2}{$sec}{$header2})) {
					$results->{$device2}{$sec}{$header2} += $value;
				} else {
					$results->{$device2}{$sec}{$header2} = $value;
				}
				if ($header2 eq 'INDEX_SCANS') {
					$ranks->{$device2} = $value;
				}
			}

		}
	}
	close($in);
	db2_update_stats($data_info, $host, 'mon_get_index', $stats);
	my $rank_n = 200;
	my @sorted_ranks = sort {$ranks->{$b} <=> $ranks->{$a}} keys %{$ranks};
	for my $device(@sorted_ranks) {
		last if (($rank_n--) <= 0);
		# print "DEVICE:$device\n";
		my $device_results = $results->{$device};
		$data_info->regist_device($host, 'Db2',
			'mon_get_index', $device, undef, \@headers);
		my $output = "Db2/${host}/device/mon_get_index__${device}.txt";
		$data_info->pivot_report($output, $device_results, \@headers);
	}

	return 1;
}

1;
