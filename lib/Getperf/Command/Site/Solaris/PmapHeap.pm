package Getperf::Command::Site::Solaris::PmapHeap;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use base qw(Getperf::Container);
use Getperf::Command::Master::Oracle;

sub new {bless{},+shift}

sub parse {
    my ($self, $data_info) = @_;

	my $results;
	my $step = 30;
	my @headers = qw/kb count/;

	my %memory_types = (
		'anon'   => 'anon', 
		'heap'   => 'heap' ,
		'stack'   => 'stack' ,
		'.so'    => 'dot_so',
		'shm'    => 'shm',
		'oracle' => 'oracle',
		'etc'    => 'etc'
	);

	my $memory_keyword = 'oracle';
	# my $memory_keyword = 'heap';
	$data_info->step($step);
        my $host = $data_info->host;
print "HOST:$host\n";
	$data_info->is_remote(1);

	my $sec  = $data_info->start_time_sec->epoch - $step;
	if (!$sec) {
		return;
	}
	open( my $in, $data_info->input_file ) || die "@!";
	my ($pid, $instance);
	while (my $line = <$in>) {
#print "LINE:$line";
		$line=~s/(\r|\n)*//g;			# trim return code
		if ($line=~/^(\d+):\s+(\S+)$/) {
			($pid, $instance) = ($1, $2);
			$instance =~s/ora_psp0_//g;
			$instance = "${host}__${instance}";
			print "($pid, $instance)\n";
		} elsif ($line=~/start pmap commands/) {
			$sec += $step;
		} elsif ($line=~/^([0-9A-F]+)\s+(\d+)K\s+(.+)$/) {
			my ($address, $kbyte, $line) = ($1, $2, $3);
#print "HIT($address, $kbyte, $line)\n";
			my $hit = 0;
			for my $keyword(keys %memory_types) {
				if ($line=~/${keyword}/) {
					my $metric = $memory_types{$keyword};
					$results->{$instance}{$metric}{$sec}{'kb'} += $kbyte;
					$results->{$instance}{$metric}{$sec}{'count'} ++;
					$hit = 1;
				}
			}
			if ($hit == 0) {
				$results->{$instance}{'etc'}{$sec}{'kb'} += $kbyte;
				$results->{$instance}{'etc'}{$sec}{'count'} ++;
				# print "BREAK:($address, $kbyte, $line)\n";
			}
		}
	}
	close($in);
#	 print Dumper $results;
	for my $instance(keys %{$results}) {
		for my $memory_type_label(keys %memory_types) {
			my $memory_type = $memory_types{$memory_type_label};
			my $device_results = $results->{$instance}{$memory_type};
			# print "${memory_type} ${memory_type_label}\n";
			$device_results = {$sec => {'kb' => 0, 'count' => 0}} if (!defined($device_results));
			my $output_file = "Oracle/${instance}/device/mem_ora_psr0__${memory_type}.txt";
			$data_info->regist_device($instance, 'Oracle', "mem_ora_psr0", 
				$memory_type, $memory_type_label, \@headers);
			$data_info->pivot_report($output_file, $device_results, \@headers);

			if ($memory_type eq 'heap') {
				my $output_file = "Oracle/${instance}/mem_ora_psr0_heap.txt";
				$data_info->regist_metric($instance, 'Oracle', "mem_ora_psr0_heap", 
					\@headers);
				$data_info->pivot_report($output_file, $device_results, \@headers);
#				print Dumper $device_results;
			}
		}
	}
	return 1;
}

1;
