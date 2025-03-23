package Getperf::Command::Site::Db2::Db2MonTable;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use base qw(Getperf::Container);
use Getperf::Command::Master::Db2;

sub new {bless{},+shift}

my %metrics = (
	'TABLE_SCANS'       , 'TABLE_SCANS:DERIVE',
	'ROWS_READ'         , 'ROWS_READ:DERIVE',
	'OVERFLOW_ACCESSES' , 'OVERFLOW_ACCESSES:DERIVE',
	'ROWS_INSERTED'     , 'ROWS_INSERTED:DERIVE',
	'ROWS_UPDATED'      , 'ROWS_UPDATED:DERIVE',
	'ROWS_DELETED'      , 'ROWS_DELETED:DERIVE',
);

sub parse {
    my ($self, $data_info) = @_;
print "SKIP monitoring for tuning 20230315\n";
return;


	my $results;
	my $step = 600;
	my %header_metrics = reverse %metrics;
	my @headers = keys %header_metrics;
	my $keywords = db2_mon_get_filter_keywords('mon_get_table');

	$data_info->step($step);
	$data_info->is_remote(1);
	my $host = $data_info->file_suffix || $data_info->host;
	my $sec  = $data_info->start_time_sec->epoch;

	open( my $in, $data_info->input_file ) || die "@!";
	my $tabschema = 'Unkown';
	my $tabname = 'Unkown';
	my $tabname_postfix;

	my $stats;
	my $ranks;
	my $schemas;
	while (my $line = <$in>) {
		# print $line;
		$line=~s/(\r|\n)*//g;			# trim return code
		next if ($line!~/^([A-Z][A-Z].+?)\s+(.+?)\s*$/);
		my ($metric, $value) = ($1, $2);
		if ($metric eq 'TABSCHEMA') {
			$tabschema = $value;
			$tabschema = 'Unkown' if ($tabschema=~/[<>]/);
		} elsif ($metric eq 'TABNAME') {
			$tabname = $value;
			$tabname = 'Unkown' if ($tabname=~/[<>]/);
			$tabname_postfix = $tabname;
			$tabname_postfix = $1 if ($tabname_postfix =~/^(.+)_\d\d\d\d+$/);
		} else {
			if ($tabschema =~/(IBMCOMPAT|Unkown|SYSIBM|SYSTOOLS|SYSPROC|\s+)/) {
				next;
			}
			my $device = "${tabschema},${tabname}";
			$schemas->{$device} = 1;
			# next if ($keywords && !$keywords->{$tabname});
			if ($value ne 'null') {
				$stats->{"$metric|$device"}{$sec} = $value;
			}
			$value = 0 if ($value eq 'null' || $value!~/^\d+$/);

			my $header = $metrics{$metric};
			if ($header) {
				my $header2 = $header;
				$header2=~s/:.+//g;
				# print "(${tabname_postfix}, $metric, $header2, $value)\n";
				my $device2 = "${tabschema},${tabname_postfix}";
				if (defined($results->{$device2}{$sec}{$header2})) {
					$results->{$device2}{$sec}{$header2} += $value;
				} else {
					$results->{$device2}{$sec}{$header2} = $value;
				}
				if ($header2 eq 'ROWS_READ') {
					$ranks->{$device2} = $value;
				}
			}
		}
	}
	close($in);
	# print Dumper $ranks;
	db2_update_stats($data_info, $host, 'mon_get_table', $stats);
	my $rank_n = 200;
	my @sorted_ranks = sort {$ranks->{$b} <=> $ranks->{$a}} keys %{$ranks};
	for my $device(@sorted_ranks) {
		last if (($rank_n--) <= 0);
		# print $device  . "\n";
		my $device_results = $results->{$device};
		# print Dumper $device_results;
		$data_info->regist_device($host, 'Db2',
			'mon_get_table', $device, undef, \@headers);
		my $output = "Db2/${host}/device/mon_get_table__${device}.txt";
		$data_info->pivot_report($output, $device_results, \@headers);
	}

	return 1;
}

1;
