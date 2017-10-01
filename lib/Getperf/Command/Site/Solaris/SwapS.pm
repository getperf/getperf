package Getperf::Command::Site::Solaris::SwapS;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use base qw(Getperf::Container);
use Getperf::Command::Master::Solaris;

#total: 312168k bytes allocated + 85824k reserved = 397992k used, 2971648k available
#total: 311208k bytes allocated + 85664k reserved = 396872k used, 2972856k available
#total: 311208k bytes allocated + 85664k reserved = 396872k used, 2972856k available

sub new {bless{},+shift}

sub parse {
    my ($self, $data_info) = @_;

	my %results;
	my $step = 30;
	my @headers = qw/alloc reserve used avail/;

	$data_info->step($step);

	my $host = $data_info->host;
	my $sec  = $data_info->start_time_sec->epoch;
	if (!$sec) {
		return;
	}
	open( IN, $data_info->input_file ) || die "@!";
	while (my $line = <IN>) {
#		next if ($line=~/^\s*[a-z]/);	# skip header
		$line=~s/(\r|\n)*//g;			# trim return code
		next if ($line!~/total: (\d+)k bytes allocated \+ (\d+)k reserved = (\d+)k used, (\d+)k available/);
		my ($alloc, $reserve, $used, $avail) = ($1, $2, $3, $4);
		$results{$sec} = "$alloc $reserve $used $avail";
		$sec += $step;
	}
	close(IN);
	$data_info->regist_metric($host, 'Solaris', 'swap_s', \@headers);
	$data_info->simple_report('swap_s.txt', \%results, \@headers);
	return 1;
}

1;
