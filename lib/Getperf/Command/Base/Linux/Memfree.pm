package Getperf::Command::Base::Linux::Memfree;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use base qw(Getperf::Container);

#              total       used       free     shared    buffers     cached
# Mem:       1012292     941300      70992        948     155916     152644
# -/+ buffers/cache:     632740     379552
# Swap:      2031612      28920    2002692

sub new {bless{},+shift}

sub parse {
    my ($self, $data_info) = @_;

	my %results;
	my $step = 30;
	my @headers = qw/used free shared buffers cached/;

	$data_info->step($step);
	my $host = $data_info->host;
	my $sec  = $data_info->start_time_sec->epoch;
	open(my $in, $data_info->input_file ) || die "@!";
	my ($used, $free, $shared, $buffers, $cached);
	while (my $line = <$in>) {
		$line=~s/(\r|\n)*//g;	# trim return code

		# Fetch free, shared, buffers, cached from 1st row, fetch used from 2nd row.
		if ($line=~/^Mem:\s+(.*)/) {
			my @item = split(/\s+/, $1);
			(undef, undef, $free, $shared, $buffers, $cached) = @item;
		} elsif ($line=~/\-\/\+ buffers\/cache:\s+(.*)/) {
			my @item = split(/\s/, $1);
			$used = shift(@item);

			$results{$sec} = join(' ', ($used, $free, $shared, $buffers, $cached));
			$sec += $step;
		}
	}
	close($in);
	$data_info->regist_metric($host, 'Linux', 'memfree', \@headers);
	$data_info->simple_report('memfree.txt', \%results, \@headers);
	return 1;
}

1;
