package Getperf::Command::Site::Solaris::Vmstat;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use base qw(Getperf::Container);
use Getperf::Command::Master::Solaris;

# kthr      memory            page            disk          faults      cpu
# r b w   swap  free  re  mf pi po fr de sr f0 s0 s1 --   in   sy   cs us sy id
# 0 0 0 3050580 2326832 30 121 4 3  2  0 10 -0  2  0  0  336  432  218  1  4 95
# 0 0 0 3015132 2269600 52 631 0 0  0  0  0  0  0  0  0  348 1464  251  2  3 96
# 0 0 0 3015052 2269520 0  1  0  0  0  0  0  0  0  0  0  335  289  207  0  6 94

sub new {bless{},+shift}

my $db = $Getperf::Command::Master::Solaris::db;

sub parse {
    my ($self, $data_info) = @_;

	my %results;
	my $step = 5;
	my @headers = qw/r b w swap free pi po sr us sy id/;

	$data_info->step($step);
	my $host = $data_info->host;
	if (!defined($db->{_node_dir}{$host})) {
		$data_info->regist_node_dir( $host, $db );
	}

    my $sec  = $data_info->start_time_sec->epoch;

	open( IN, $data_info->input_file ) || die "@!";
	while (my $line = <IN>) {
		next if ($line=~/^\s*[a-z]/);
		$line=~s/(\r|\n)*//g;	# trim return code
		$line=~s/^\s+|\s+$//g;
		my @cols = split(' ', $line);
		my $n = scalar(@cols);
		$results{$sec} = join(" ", map {$cols[$_]} (0, 1, 2, 3, 4, 7,8, 11, $n-3, $n-2, $n-1));
		$sec += $step;
	}
	close(IN);
	# $nodepath, $domain, $metric, $headers
	$data_info->regist_metric($host, 'Solaris', 'vmstat', \@headers);
	$data_info->simple_report('vmstat.txt', \%results, \@headers);
	return 1;
}

1;
