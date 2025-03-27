package Getperf::Command::Site::AIX::IndoubtCount;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use base qw(Getperf::Container);
use Getperf::Command::Master::AIX;

sub new {bless{},+shift}

sub parse {
    my ($self, $data_info) = @_;

	my %results;
	my $step = 60;
	my @headers = qw/count/;

	$data_info->is_remote(1);
	$data_info->step($step);
	my $host = $data_info->host;
	$host=~s/\d+$//g;
	# print $host;

	# 2020-08-04 19:28,0
	# 2020-08-04 19:29,5
	# 2020-08-04 19:30,0

	my $sec  = $data_info->start_time_sec->epoch;
	if (!$sec) {
		return;
	}
	open( my $in, $data_info->input_file ) || die "@!";
	while (my $line = <$in>) {
		$line=~s/(\r|\n)*//g;			# trim return code
		my @csv = split(/,/, $line);
		$sec = localtime(Time::Piece->strptime($csv[0], '%Y-%m-%d %H:%M'))->epoch;
		$results{$sec} = $csv[1];
	}
	close($in);
	print Dumper \%results;
	$data_info->regist_metric($host, 'AIX', 'indoubt_count', \@headers);

	my $output = "AIX/${host}/indoubt_count.txt";	# Remote collection

	$data_info->simple_report($output, \%results, \@headers);
	return 1;
}

1;
