package Getperf::Command::Site::Solaris::Mpstat;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use base qw(Getperf::Container);

sub new {bless{},+shift}

# CPU minf mjf xcal  intr ithr  csw icsw migr smtx  srw syscl  usr sys  wt idl
#   0  174   0  301   732  202  881    9  189   21    0  1021    2   1   0  97
#   1  167   0  342   637  204  940   10  165   21    0  1094    2   1   0  97
#   2  243   0  240   452  171  716    8  152   24    0  1542    3   1   0  95
#   3  103   0  421   644  357  713    7  144   20    0  1247    3   1   0  96
#   4  177   0  223   633  346  705    8  148   22    0  1393    3   1   0  96
#   5  171   0  247   457  173  716    9  145   22    0  1427    4   1   0  95
#   6  250   0  239   462  171  717    8  155   25    0  1630    4   1   0  95
#   7  104   0  243   471  175  717    8  151   20    0  1263    3   1   0  96

sub parse {
    my ($self, $data_info) = @_;

	my %results;
	my $step = 30;
	my @headers = qw/usr sys wt idl/;

	$data_info->step($step);
	my $host = $data_info->host;

	my $sec  = $data_info->start_time_sec->epoch - $step;
	if (!$sec) {
		return;
	}
	open( my $in, $data_info->input_file ) || die "@!";
	while (my $line = <$in>) {
		$line=~s/(\r|\n)*//g;			# trim return code
		next if ($line=~/^Date/);
		if ($line=~/^\s*CPU/) {
			$sec += $step;
			next;
		}
		my @cols = split(' ', $line);
		my $n = scalar(@cols);

		# Extract the four rows behind; 'usr sys wt idl'
		for my $idx(0..3) {
			$results{$sec}{$headers[$idx]} += $cols[$n - 4 + $idx];
		}
	}
	close($in);
	$data_info->regist_metric($host, 'Solaris', 'mpstat', \@headers);
	my $output = "mpstat.txt";
	$data_info->pivot_report('mpstat.txt', \%results, \@headers);
	return 1;
}

1;
