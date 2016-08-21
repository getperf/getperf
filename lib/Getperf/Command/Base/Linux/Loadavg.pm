package Getperf::Command::Base::Linux::Loadavg;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use base qw(Getperf::Container);

sub new {bless{},+shift}

sub parse {
    my ($self, $data_info) = @_;

	my %results;
	my $step = 5;
	my @headers = qw/load1m load5m load15m/;

	$data_info->step($step);

	my $host = $data_info->host;
	my $sec  = $data_info->start_time_sec->epoch;
	open( my $in, $data_info->input_file ) || die "@!";
	while (my $line = <$in>) {
		next if ($line=~/^\s*[a-z]/);	# skip header
		$line=~s/(\r|\n)*//g;			# trim return code
		$line=$1 if ($line=~/^(\S+\s+\S+\s+\S+)\s+/);
		$results{$sec} = $line;
		$sec += $step;
	}
	close($in);
	$data_info->regist_metric($host, 'Linux', 'loadavg', \@headers);
	$data_info->simple_report('loadavg.txt', \%results, \@headers);
	return 1;
}

1;
