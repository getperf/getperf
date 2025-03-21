package Getperf::Command::Site::Oracle::OraSesCnt;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use base qw(Getperf::Container);
use Getperf::Command::Master::Oracle;

sub new {bless{},+shift}

sub parse {
    my ($self, $data_info) = @_;

	my (%results, %device_results);
	my $step = 600;
	my @headers = qw/session transaction actives/;
	$data_info->step($step);
	$data_info->is_remote(1);

	# get_lotstat_STARYYY.txt
	my $instance = 'URA0';
	if ( $data_info->file_name =~/^orasescnt_(.+)$/ ) {
		$instance = $1;
	} else {
		$instance = $data_info->file_suffix;
	}
    # $instance = "${instance}_RAT" if (is_rat_hostname($data_info->host));
	my $sec  = $data_info->start_time_sec->epoch;
	open( my $in, $data_info->input_file ) || die "@!";
	while (my $line = <$in>) {
		$line=~s/(\r|\n)*//g;			# trim return code
		if ($line=~/Date:(.*)/) {		# parse time: 16/05/23 14:56:52
			$sec = localtime(Time::Piece->strptime($1, '%y/%m/%d %H:%M:%S'))->epoch;
			next;
		}
		my ($item, @csvs) = split(/\s*\,\s*/, $line);
		map {
			my $ds = $_;
			my $value = shift(@csvs);
			$device_results{$item}{$sec}{$ds} = $value;
			$results{$sec}{$ds} += $value;
		} @headers;
	}
	close($in);
# print Dumper \%results; exit;
 # print Dumper \%results ;

	# $data_info->regist_metric($instance, 'Oracle', 'ora_session', \@headers);
	# my $output = "Oracle/${instance}/ora_session.txt";
	# $data_info->pivot_report($output, \%results, \@headers);

	for my $device(sort keys %device_results) {
		$data_info->regist_device($instance, 'Oracle', 'ora_session_detail', $device, undef, \@headers);
		my $output = "Oracle/${instance}/device/ora_session_detail__${device}.txt";
		$data_info->pivot_report($output, $device_results{$device}, \@headers);
	}

	return 1;
}

1;
