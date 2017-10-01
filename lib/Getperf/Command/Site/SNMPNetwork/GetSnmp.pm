package Getperf::Command::Site::SNMPNetwork::GetSnmp;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use base qw(Getperf::Container);
use Getperf::Command::Master::SNMPNetwork;

sub new {bless{},+shift}

sub parse {
    my ($self, $data_info) = @_;

	my %results;
	my $step = 60;
	my @headers = qw/ifOperStatus ifInOctets ifOutOctets
		ifInUcastPkts ifOutUcastPkts ifInNUcastPkts ifOutNUcastPkts
		ifInDiscards ifInErrors ifOutDiscards ifOutErrors/;
	my @counter_headers = map { "$_:COUNTER" } @headers;

	$data_info->step($step);
	$data_info->is_remote(1);

	my $host = $data_info->file_suffix();
	open( my $in, $data_info->input_file ) || die "@!";
	$data_info->skip_header( $in );
	while (my $line = <$in>) {
		$line=~s/(\r|\n)*//g;			# trim return code
		next if ($line=~/Date\s+Time/);
		# parse these line;
		# 2016/08/09 13:01:41 151060487 {body}
		my ($date, $time, $device, @csvs) = split(' ', $line);
		my $tms = $date . ' ' . $time;
		my $sec = localtime(Time::Piece->strptime($tms, '%Y/%m/%d %H:%M:%S'))->epoch;
		$results{$device}{$sec} = join(' ', @csvs);
	}
	close($in);

	for my $device(keys %results) {
        my $output_file = "SNMPNetwork/${host}/device/snmp_network_port__${device}.txt";
        $data_info->regist_device($host, 'SNMPNetwork', 'snmp_network_port', $device,
        	                      undef, \@counter_headers);
        $data_info->simple_report($output_file, $results{$device}, \@headers);
	}
	return 1;
}

1;
