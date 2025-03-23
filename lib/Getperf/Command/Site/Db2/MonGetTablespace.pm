package Getperf::Command::Site::Db2::MonGetTablespace;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use base qw(Getperf::Container);
use Getperf::Command::Master::Db2;

sub new {bless{},+shift}

sub parse {
    my ($self, $data_info) = @_;

	my (%results, %results_v2);
	my $step = 600;
	$data_info->step($step);
	$data_info->is_remote(1);
	my $host = $data_info->file_suffix || $data_info->host;
	my $sec  = $data_info->start_time_sec->epoch;

	open( my $in, $data_info->input_file ) || die "@!";
	my $device = 'Unkown';
	my $stats;
	while (my $line = <$in>) {
		# print $line;
		$line=~s/(\r|\n)*//g;			# trim return code
		next if ($line!~/^([A-Z][A-Z].+?)\s+(.+?)$/);
		my ($metric, $value) = ($1, $2);
		if ($metric eq 'TBSP_NAME') {
			$device = $value;
			# print "DEV:$device\n";
		}
		$stats->{"$metric|$device"}{$sec} = $value;
	}
	close($in);

	db2_update_stats($data_info, $host, 'mon_get_tablespace', $stats);

	# $data_info->regist_metric($host, 'Db2', 'db2_mon_database', \@headers);
	# my $output = "Db2/${host}/db2_mon_database.txt";	# Remote collection
	# $data_info->pivot_report($output, \%results, \@headers);

	# $data_info->regist_metric($host, 'Db2', 'db2_mon_database2', \@headers2);
	# $output = "Db2/${host}/db2_mon_database2.txt";	# Remote collection
	# $data_info->pivot_report($output, \%results_v2, \@headers2);
	return 1;
}

1;
