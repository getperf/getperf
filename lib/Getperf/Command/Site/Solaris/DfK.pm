package Getperf::Command::Site::Solaris::DfK;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use base qw(Getperf::Container);
use Getperf::Command::Master::Solaris;

sub new {bless{},+shift}

sub parse {
    my ($self, $data_info) = @_;

	my %results;
	my (@nodes, %nodes_key);
	my $row = 0;
	my $sec = $data_info->start_time_sec->epoch;
	if (!$sec) {
		return;
	}
	my @headers = qw/capacity free_space used_space usage/;

	$data_info->step(300);
	my $host = $data_info->host;
	open( IN, $data_info->input_file ) || die "@!";
	while (my $line = <IN>) {
		next if ($row++ < 1);
		$line=~s/(\r|\n)*//g;	# trim return code
		# Reverse extract for root '/' partition doesn't have 1st column.
		my @cols = split(/\s+/, $line);
		next if (scalar(@cols) < 6);
		my ($path, $usage, $free_space, $used_space, $capacity, $filesystem) = reverse @cols;
		$usage =~s/\%//g;
		my $device = alias_df_k($host, $path) || '';
		if ($device) {
			$data_info->regist_device($host, 'Solaris', 'diskutil', $device, $path, \@headers);
	 		$results{$device}{$sec} = join(' ', ($capacity, $free_space, $used_space, $usage));
		}
	}
	close(IN);
	for my $device(keys %results) {
		my $output_file = "device/diskutil__${device}.txt";
		$data_info->simple_report($output_file, $results{$device}, \@headers);
	}
	return 1;
}

1;
