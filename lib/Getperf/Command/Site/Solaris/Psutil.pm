package Getperf::Command::Site::Solaris::Psutil;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use base qw(Getperf::Container);
use Getperf::Command::Master::Process;

sub new {bless{},+shift}

sub parse {
    my ($self, $data_info) = @_;

	my (%results, %cpus);
	my $step = 30;
	my @headers  = qw/cpu vsz nlwp/;

	$data_info->step($step);
	my $host = $data_info->host;
	my $sec = $data_info->start_time_sec->epoch;
	open( IN, $data_info->input_file ) || die "@!";
	my $timestamp;
	while (my $line = <IN>) {
		next if ($line=~/^Date:/);
		if ($line=~/^\s*(PID|OSNAME)/) {
			$sec += $step;
			next;
		}
		$line=~s/(\r|\n)*//g;			# trim return code
		$line=~s/^\s+//g;
		my ($pid, $ppid, $group, $user, $cputime, $nlwp, $vsz, @cmds) = split(/\s+/, $line);
		my $command = join(" ", @cmds);
		my $category = alias_ps($user, $command);
		my $output_file = "device/ps__${category}.txt";

		# parse cpu
		my $cpu = 0;
		if ($cputime=~/^(\d+)-(\d.+)$/) {
			$cpu = 24 * 3600 * $1;
			my $cputime = $2;
		}
		$cpu += $1 * 3600 + $2 * 60 + $3 if ($cputime=~/^(\d+):(\d+):(\d+)$/);
		my $cpu_diff = 0;
		if (defined(my $cpu_old = $cpus{$pid})) {
			$cpu_diff = $cpu - $cpu_old;
		}
		$results{$category}{$sec}{cpu} += $cpu_diff;
		$cpus{$pid} = $cpu;

		# parse vsz, nlwp
		my $curr_vsz = $results{$category}{$sec}{vsz} || 0;
		if ($curr_vsz < $vsz) {
			$results{$category}{$sec}{vsz} = $vsz;
		}
		my $curr_nlwp = $results{$category}{$sec}{nlwp} || 0;
		if ($curr_nlwp < $nlwp) {
			$results{$category}{$sec}{nlwp} = $nlwp;
		}
	}
	close(IN);
	for my $category(keys %results) {
		$data_info->regist_device($host, 'Solaris', 'process', $category, undef, \@headers);
		my $output = "device/process__${category}.txt";	# Remote collection
		$data_info->pivot_report($output, $results{$category}, \@headers);
	}

	return 1;
}

1;
