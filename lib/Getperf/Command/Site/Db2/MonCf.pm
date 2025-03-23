package Getperf::Command::Site::Db2::MonCf;
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
	my %header_metrics = reverse %metrics;
	my @headers = keys %header_metrics;

	$data_info->step($step);
	$data_info->is_remote(1);
	my $host = $data_info->file_suffix || $data_info->host;

	my $sec  = $data_info->start_time_sec->epoch;
	if (!$sec) {
		return;
	}
	open( my $in, $data_info->input_file ) || die "@!";
	while (my $line = <$in>) {
		$line=~s/(\r|\n)*//g;			# trim return code
		next if ($line!~/^([A-Z].+?)\s+(.+?)$/);
		my ($metric, $value) = ($1, $2);
		$value = 0 if ($value eq 'null');
		my $header = $metrics{$metric};
		if ($header) {
			my $header2 = $header;
			$header2=~s/:.+//g;
			print "($metric, $header2, $value)\n";
			$results{$sec}{$header2} = $value;
		}
	}
	close($in);
	print Dumper \%results;
	$data_info->regist_metric($host, 'Db2', 'mon_db_summary', \@headers);
	my $output = "Db2/${host}/mon_db_summary.txt";	# Remote collection
	$data_info->pivot_report($output, \%results, \@headers);
	return 1;
}

1;
