package Getperf::Command::Site::AIX::Psutil;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use base qw(Getperf::Container);
use Getperf::Command::Master::AIX;

sub new {bless{},+shift}

sub parse {
    my ($self, $data_info) = @_;

	my (%results, %cpus);
	my $step = 30;
	my @headers  = qw/cpu vsz rss/;

	$data_info->step($step);
	my $host   = $data_info->host;
	# my $jvms   = read_java_vm_list($self, $data_info);
	my $domain = 'Solaris';
	# if ($host=~/wfm/ && !$jvms) {
	# 	return;
	# }
	if ($host=~/sv/) {
		$domain = 'AIX';
	}
	my $sec    = $data_info->start_time_sec->epoch;
	open( IN, $data_info->input_file ) || die "@!";
	my $timestamp;
	my %nlwps;
	while (my $line = <IN>) {
		if ($line=~/^\s*(PID|OSNAME)/) {
			$sec += $step;
			next;
		}
		next if ($line=~/^Date/);
		$line=~s/(\r|\n)*//g;			# trim return code
		$line=~s/^\s+//g;
		my @csvs = split(' ', $line);
		my $n_csvs = scalar(@csvs);
		my ($pid, $ppid, $group, $user, $cputime, $nlwp, $rsz, $vsz, @cmds, $command);
		if ($domain eq 'AIX' && $n_csvs > 6) {
			($pid, $ppid, $group, $user, $cputime, $vsz, @cmds) = @csvs;
			$command = join(" ", @cmds);
			next if ($command=~/^\d+$/);
		} elsif ($domain eq 'Solaris' && $n_csvs > 7) {
			($pid, $ppid, $group, $user, $cputime, $nlwp, $vsz, @cmds) = @csvs;
			$command = join(" ", @cmds);
		} else {
			next;
		}
		my $category = 'etc';
		# if (defined($jvms->{$pid})) {
		# 	$category = alias_ps_jvm($jvms->{$pid}->{device});
		# } else {
    		$category = alias_ps($pid, $group, $user, $command);
		# }
print "$category : $pid, $group, $user, $command \n";
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
		# $nlwps{$category}{$sec}{nlwp} += $nlwp;
		$cpus{$pid} = $cpu;

		# parse vsz, rss
		my $curr_vsz = $results{$category}{$sec}{vsz} || 0;
		if ($curr_vsz < $vsz) {
			$results{$category}{$sec}{vsz} = $vsz;
		}
	}
	close(IN);
	for my $category(keys %results) {
		$data_info->regist_device($host, $domain, 'process', $category, undef, \@headers);
		my $output = "device/process__${category}.txt";	# Remote collection
		$data_info->pivot_report($output, $results{$category}, \@headers);
	}

	my @headers2 = qw/nlwp/;
	for my $category(keys %nlwps) {
		$data_info->regist_device($host, $domain, 'nlwp', $category, undef, \@headers2);
		my $output = "device/nlwp__${category}.txt";	# Remote collection
		$data_info->pivot_report($output, $nlwps{$category}, \@headers2);
	}
}

1;
