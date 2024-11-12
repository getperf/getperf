package Getperf::Command::Site::Solaris::Kstat2;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use base qw(Getperf::Container);
use Getperf::Command::Master::Solaris;

sub new {bless{},+shift}

# Date:2016/09/21 14:00:00
# vmem:302:segkp:fail     0
# vmem:302:segkp:mem_inuse        1920368640
# vmem:302:segkp:mem_total        2147483648

sub parse {
    my ($self, $data_info) = @_;

	my %results;
	my $step = 30;
	my @headers = qw/fail mem_inuse mem_total/;

	$data_info->step($step);
	my $host = $data_info->host;

	my $sec  = $data_info->start_time_sec->epoch;
	open( my $in, $data_info->input_file ) || die "@!";
	while (my $line = <$in>) {
		$line=~s/(\r|\n)*//g;			# trim return code
		if ($line =~/(fail|mem_inuse|mem_total)\s+(\d+)$/) {
			my ($item, $value) = ($1, $2);
			$results{$sec}{$item} = $value;
			$sec += $step if ($item eq 'mem_total');
		}
	}
	close($in);

	$data_info->regist_metric($host, 'Solaris', 'kstat2', \@headers);
	my $output = "kstat2.txt";
	$data_info->pivot_report('kstat2.txt', \%results, \@headers);

	return 1;
}

1;
