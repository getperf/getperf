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
	my @headers = qw/ipackets opackets rbytes obytes rbytes64 obytes64 ierrors oerrors/;

	my @counter_headers = map { "$_:COUNTER" } @headers;

	$data_info->step($step);
	my $host = $data_info->host;
	open( IN, $data_info->input_file ) || die "@!";
	my $timestamp = undef;
	while (my $line = <IN>) {
		# print $line;
		$line=~s/(\r|\n)*//g;			# trim return code
		if ($line=~/^(\d+)$/) {
			$timestamp = $1;
		} elsif ($line=~/^(.+):(\d+):(.+):(.+)\s+(\d+)$/) {
			my ($device, $metric, $value) = ($3, $4, $5);
			next if ($device=~/vswl/ || $device eq 'net_dev');
			$results{$device}{$timestamp}{$metric} = $value;
		}
	}
	close(IN);
	# DEV:ipmp0
	# DEV:fm
	# DEV:statistics
	# DEV:ipmp1
	# DEV:phys
	for my $device(keys %results) {
		next if ($device =~/(fm|statistics|vnet|mac|phys)/);
		my $output_file = "device/kstat__${device}.txt";
		$data_info->regist_device($host, 'Solaris', 'kstat', $device, undef, \@counter_headers);
		$data_info->pivot_report($output_file, $results{$device}, \@headers);
	}
	return 1;
}

1;
