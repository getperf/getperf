package Getperf::Command::Site::Linux::DfK;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use base qw(Getperf::Container);

# Filesystem                   1K-blocks     Used Available Use% Mounted on
# /dev/mapper/ostrich--vg-root 114731592 96133332  12747124  89% /
# none                                 4        0         4   0% /sys/fs/cgroup
# udev                           3926640        4   3926636   1% /dev
# tmpfs                          2560000   274316   2285684  11% /tmp

sub new {bless{},+shift}

sub reform_mount_name {
	my ($self, $mount) = @_;

	return if (!$mount);
	if ($mount eq '/') {
		return 'root';
	} elsif ($mount=~/\/(.*)$/) {
		$mount = $1;
		$mount =~s/\s+/_/g;
		$mount =~s/[\/\(\)]/_/g;
		return $mount;
	} elsif ($mount=~/^(\w+):$/) {
		return $1;
	} else {
		return;
	}
}	

sub parse {
    my ($self, $data_info) = @_;

	my %results;
	my (@nodes, %nodes_key);
	my $row = 0;
	my $sec  = $data_info->start_time_sec->epoch;
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
		my $device = $self->reform_mount_name($path);
		if ($device) {
			my $output_file = "device/diskutil__${device}.txt";
			$data_info->regist_device($host, 'Linux', 'diskutil', $device, $path, \@headers);
	 		$results{$output_file}{$sec} = join(' ', ($capacity, $free_space, $used_space, $usage));
		}
	}
	close(IN);
	for my $output_file(keys %results) {
		$data_info->simple_report($output_file, $results{$output_file}, \@headers);
	}
	return 1;
}

1;
