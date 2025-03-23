package Getperf::Command::Site::Db2::Db2MonBufferpool;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use base qw(Getperf::Container);
use Getperf::Command::Master::Db2;

my %metrics = (
# Overall physical and logical numbers
'POOL_DATA_L_READS',      'Data_Logical_Rds:DERIVE',
'POOL_DATA_P_READS',      'Data_Physical_Rds:DERIVE',
'POOL_INDEX_L_READS',     'Idx_Logical_Rds:DERIVE',
'POOL_INDEX_P_READS',     'Idx_Physical_Rds:DERIVE',
'POOL_TEMP_DATA_L_READS', 'Temp_D_Log_Rds:DERIVE',
'POOL_TEMP_DATA_P_READS', 'Temp_D_Phy_Rds:DERIVE',
# Direct IO stats
'DIRECT_READS',      'Direct_Rds:DERIVE',
'DIRECT_WRITES',     'Direct_Wri:DERIVE',
'DIRECT_READ_REQS',  'Direct_Rd_Req:DERIVE',
'DIRECT_WRITE_REQS', 'Direct_Wri_Req:DERIVE',
'DIRECT_READ_TIME',  'Direct_Rd_Tm:DERIVE',
'DIRECT_WRITE_TIME', 'Direct_Wri_Tm:DERIVE',
);

sub new {bless{},+shift}

sub parse {
    my ($self, $data_info) = @_;

	my %results;
	my $step = 600;
	my %header_metrics = reverse %metrics;
	my @headers = keys %header_metrics;
	my $keywords = db2_mon_get_filter_keywords('mon_get_bufferpool');

	$data_info->step($step);
	$data_info->is_remote(1);
	my $host = $data_info->file_suffix || $data_info->host;
	my $sec  = $data_info->start_time_sec->epoch;
	$sec = $sec - $step;
	open( my $in, $data_info->input_file ) || die "@!";
	my $bp_name = 'Unkown';

	my $stats;
	my $pools;
	while (my $line = <$in>) {
		# print $line;
		$line=~s/(\r|\n)*//g;			# trim return code
		next if ($line!~/^([A-Z][A-Z].+?)\s+(.+?)\s*$/);
		my ($metric, $value) = ($1, $2);
		if ($metric eq 'BP_NAME') {
			$bp_name = $value;
		} else {
			# my $bp_name = "${bp_name}";
			$stats->{"$metric|${bp_name}"}{$sec} = $value;
			# next if ($keywords && !$keywords->{$tabname});
			next if ($bp_name=~/(IBMSYSTEM|Unkown)/);
			$value = 0 if ($value eq 'null' || $value!~/\d+$/);
			my $header = $metrics{$metric};
			if ($header) {
				my $header2 = $header;
				$header2=~s/:.+//g;
				# print "($tabname, $metric, $header2, $value)\n";
				$results{$bp_name}{$sec}{$header2} = $value;
			}
		}
	}
	close($in);
# print Dumper \%results;
	db2_update_stats($data_info, $host, 'mon_get_bufferpool', $stats);
	for my $device(keys %results) {
		my $device_results = $results{$device};
		$data_info->regist_device($host, 'Db2',
			'mon_get_bufferpool', $device, undef, \@headers);
		my $output = "Db2/${host}/device/mon_get_bufferpool__${device}.txt";
		$data_info->pivot_report($output, $device_results, \@headers);
	}

	return 1;
}

1;
