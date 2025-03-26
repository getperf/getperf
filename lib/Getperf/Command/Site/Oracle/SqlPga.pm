package Getperf::Command::Site::Oracle::SqlPga;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use base qw(Getperf::Container);
use Getperf::Command::Master::Oracle;

sub new {bless{},+shift}

sub parse {
    my ($self, $data_info) = @_;

	my $results;
	my $step = 600;
	my @headers = qw/allocated limit inuse/;

	$data_info->step($step);
	$data_info->is_remote(1);
	my $host_prefix = $data_info->file_suffix;

	my $sec  = $data_info->start_time_sec->epoch;
	if (!$sec) {
		return;
	}
	open( my $in, $data_info->input_file ) || die "@!";
	while (my $line = <$in>) {
		next if ($line=~/^Date:/);	# skip header
		$line=~s/(\r|\n)*//g;			# trim return code
		# print $line . "\n";
		next if ($line !~/^\d+/);
		my ($time, $inst_id, $name, $value) = split(/\s*\|\s*/, $line);
		# $sec = Time::Piece->strptime($time, '%Y/%m/%d %H:%M:%S')->localtime->epoch;
		if ($name=~/(allocated|inuse|limit)/) {
			my $metric = $1;
			my $host = "${host_prefix}-${inst_id}";
			$results->{$host}{$sec}{$metric} = $value;
			# print "($sec, $host, $metric, $value)\n";
		}
	}
	close($in);
	print Dumper $results;
	for my $instance(keys %{$results}) {
		$data_info->regist_metric($instance, 'Oracle', 'sql_pga', \@headers);
		my $output = "Oracle/${instance}/sql_pga.txt";
		$data_info->pivot_report($output, $results->{$instance}, \@headers);
	}
	return 1;
}

1;
