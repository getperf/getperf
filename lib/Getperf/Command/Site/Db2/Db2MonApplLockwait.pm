package Getperf::Command::Site::Db2::Db2MonApplLockwait;
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
	my $service_superclass_name = 'Unkown';
	my $service_subclass_name = 'Unkown';
	my $application_handle = 0;

	my $stats;
	while (my $line = <$in>) {
		print $line;
		$line=~s/(\r|\n)*//g;			# trim return code
		next if ($line!~/^([A-Z][A-Z].+?)\s+(.+?)$/);
		my ($metric, $value) = ($1, $2);
		if ($metric eq 'SERVICE_SUPERCLASS_NAME') {
			$service_superclass_name = $value;
		} elsif ($metric eq 'SERVICE_SUBCLASS_NAME') {
			$service_subclass_name = $value;
		} elsif ($metric eq 'APPLICATION_HANDLE') {
			$application_handle = $value;
		} else {
			my $device = "${application_handle},${service_superclass_name},${service_subclass_name}";
			$stats->{"$metric|$device"}{$sec} = $value;
		}
	}
	close($in);
	my $options = {'enable_first_load' => 1};
	db2_update_stats($data_info, $host, 'mon_get_appl_lockwait', $stats, $options);

	return 1;
}

1;
