package Getperf::Command::Site::Linux::Vmstat;
use strict;
use warnings;
use Time::Piece;
use Data::Dumper;
use base qw(Getperf::Container);
use Getperf::Command::Master::Linux;

# procs -----------memory---------- ---swap-- -----io---- --system-- -----cpu-----
#  r  b   swpd   free  inact active   si   so    bi    bo   in   cs us sy id wa st
#  5  0  30120  75204 416300 375236    0    0     0     0   95  237  0  0 100  0  0
#  0  0  30120  75204 416308 375200    0    0     0    10  104  273  0  1 99  0  0

sub new {bless{},+shift}

my $db = $Getperf::Command::Master::Linux::db;

sub parse {
    my ($self, $data_info) = @_;

	my %results;
	my $step = 5;
	my @headers = qw/r b swpd free inact active si so bi bo in cs us sy id wa st/;

	$data_info->step($step);
	my $host = $data_info->host;
	if (!defined($db->{_node_dir}{$host})) {
		$data_info->regist_node_dir( $host, $db );
	}

	my $sec = $data_info->start_time_sec->epoch;
	open( my $in, $data_info->input_file ) || die "@!";
	while (my $line = <$in>) {
		$line=~s/(\r|\n)*//g;	# trim return code
		next if ($line=~/^[a-z\s-]+$/  || $line=~/^Date/);
		$results{$sec} = $line;
		$sec += $step;
	}
	close($in);
	# $nodepath, $domain, $metric, $headers
	$data_info->regist_metric($host, 'Linux', 'vmstat', \@headers);
	$data_info->simple_report('vmstat.txt', \%results, \@headers);

	return 1;
}

1;
