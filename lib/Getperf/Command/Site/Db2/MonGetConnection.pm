package Getperf::Command::Site::Db2::MonGetConnection;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use base qw(Getperf::Container);
use Getperf::Command::Master::Db2;

sub new {bless{},+shift}

sub parse {
    my ($self, $data_info) = @_;
	my %results;
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
		if ($metric eq 'APPLICATION_HANDLE') {
			$device = $value;
		} else {
			$stats->{"$metric|$device"}{$sec} = $value;
		}
	}
	close($in);
	my $options = {'enable_first_load' => 1};
	db2_update_stats($data_info, $host, 'mon_get_connection', $stats, $options);

	return 1;
}

1;
