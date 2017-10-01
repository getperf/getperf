package Getperf::Command::Site::Solaris::Kstat;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use base qw(Getperf::Container);
use Getperf::Command::Master::Solaris;

# 1440923439
# e1000g:0:e1000g0:brdcstrcv      0
# e1000g:0:e1000g0:brdcstxmt      0

sub new {bless{},+shift}

sub parse {
    my ($self, $data_info) = @_;

	my %results;
	my $step = 5;
	my @headers = qw/ipackets opackets rbytes obytes rbytes64 obytes64 ierrors oerrors collisions/;

	my @counter_headers = map { "$_:COUNTER" } @headers;

	$data_info->step($step);
	my $host = $data_info->host;
	open( IN, $data_info->input_file ) || die "@!";
	my $timestamp = undef;
	while (my $line = <IN>) {
		$line=~s/(\r|\n)*//g;			# trim return code
		if ($line=~/^(\d+)$/) {
			$timestamp = $1;
		} elsif ($line=~/^(.+):(\d+):(.+):(.+)\s+(\d+)$/) {
			my ($device, $metric, $value) = ($3, $4, $5);
			$results{$device}{$timestamp}{$metric} = $value;
		}
	}
	close(IN);
	for my $device(keys %results) {
		my $output_file = "device/kstat__${device}.txt";
		$data_info->regist_device($host, 'Solaris', 'kstat', $device, undef, \@counter_headers);
		$data_info->pivot_report($output_file, $results{$device}, \@headers);
	}
	return 1;
}

1;
