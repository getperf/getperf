package Getperf::Command::Base::Linux::NetDev;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use base qw(Getperf::Container);

# Inter-|   Receive                                                |  Transmit
#  face |bytes    packets errs drop fifo frame compressed multicast|bytes    packets errs drop fifo colls carrier compressed
#     lo: 6398558   26526    0    0    0     0          0         0  6398558   26526    0    0  0     0       0          0
#   eth0: 29407399  66848    0    0    0     0          0         0  6927092   36543    0    0  0     0       0          0

sub new {bless{},+shift}

sub representative_device {
	my ($devices) = @_;
	my $device = '';
	for $device(sort { $devices->{$a} <=> $devices->{$b}} keys %$devices) {
		if ($device=~/eth/) {
			return $device;
		}
	}
	return $device;
}

sub parse {
    my ($self, $data_info) = @_;

	my (%results, %devices);
	my $step = 30;
    my $sec  = $data_info->start_time_sec->epoch;
	my @headers = qw/
		inBytes    inPackets  inErrs  inDrop  inFifo  inFrame inCompressed inMulticast
		outBytes   outPackets outErrs outDrop outFifo outColls outCarrier outCompressed
	/;
	my @counter_headers = map { "$_:COUNTER" } @headers;
	$data_info->step($step);
	my $host = $data_info->host;

	my $row = 1;
	open(my $in, $data_info->input_file ) || die "@!";
	while (my $line = <$in>) {
		$line=~s/(\r|\n)*//g;	# trim return code

		if ($line=~/^\s*(\w.*)\s*:\s*(\d.*\d)$/) {
			my ($device, $body) = ($1, $2);
			my $output_file = "device/netDev__${device}.txt";
			$results{$output_file}{device}  = $device;
			$devices{$device} = scalar(keys %devices) + 1 if (!exists($devices{$device}));
			my @values = split(/\s+/, $body);
			for my $header(@headers) {
				my $value = shift(@values);
				$results{$output_file}{out}{$sec}{$header} = $value;
			}
		}
		if ($row++ > 1 && $line=~/^Inter/) {
	        $sec += $step;
		}
	}
	close($in);
	my $representative_device = representative_device(\%devices);
	for my $output_file(sort keys %results) {
		my $device  = $results{$output_file}{device};
		if ($device eq $representative_device) {
			$data_info->regist_metric($host, 'Linux', 'netDevTotal', \@counter_headers);
			$data_info->pivot_report('netDevTotal.txt', $results{$output_file}{out}, \@headers);
		} 
		$data_info->regist_device($host, 'Linux', 'netDev', $device, undef, \@counter_headers);
		$data_info->pivot_report($output_file, $results{$output_file}{out}, \@headers);
	}
	return 1;
}

1;
