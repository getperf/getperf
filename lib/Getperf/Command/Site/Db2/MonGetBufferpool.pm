package Getperf::Command::Site::Db2::MonGetBufferpool;
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
	my $bp_name = 'Unkown';

	my $stats;
	while (my $line = <$in>) {
		# print $line;
		$line=~s/(\r|\n)*//g;			# trim return code
		next if ($line!~/^([A-Z][A-Z].+?)\s+(.+?)$/);
		my ($metric, $value) = ($1, $2);
		if ($metric eq 'BP_NAME') {
			$bp_name = $value;
		} else {
			# my $device = "${bp_name}";
			$stats->{"$metric|${bp_name}"}{$sec} = $value;
		}
	}
	close($in);

	db2_update_stats($data_info, $host, 'mon_get_bufferpool', $stats);
	return 1;
}

1;
