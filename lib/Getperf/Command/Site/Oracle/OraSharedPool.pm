package Getperf::Command::Site::Oracle::OraSharedPool;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use base qw(Getperf::Container);
use Getperf::Command::Master::Oracle;

sub new {bless{},+shift}

sub parse {
    my ($self, $data_info) = @_;

	my %results;
	my $step = 600;
	my @headers = qw/byte/;

	$data_info->is_remote(1);
	$data_info->step($step);
	my $host = $data_info->file_suffix;
	my $sec  = $data_info->start_time_sec->epoch;
	open( IN, $data_info->input_file ) || die "@!";
	while (my $line = <IN>) {
		next if ($line=~/^Date:/);	# skip header
		$line=~s/(\r|\n)*//g;			# trim return code
		my @csv = split(/\s*[|]\s*/, $line);
		# print $line . "\n";
		next if (scalar(@csv) != 4 || $csv[0] eq 'TIME');
		my ($tms, $instance, $mem_area, $byte) = @csv;
		# $mem_area = camelize($mem_area);
		$byte =~s/,//g;
		$byte = 0 if (!defined($byte));
		$mem_area = lc $mem_area;
		$mem_area =~s/[\$\s]+/_/g;
		$mem_area =~s/[\(\)]//g;
		print "($tms, $instance, $mem_area, $byte)\n";
		$results{$instance}{$mem_area}{$sec} += $byte;
	}
	close(IN);
	# print Dumper \%results;
	for my $instance(keys %results) {
        my $host_suffix = $host;
        $host_suffix = "${host}_${instance}" if ($instance > 1);
		for my $mem_area(keys %{$results{$instance}}) {
			my $output = "Oracle/${host_suffix}/device/ora_shared_pool__${mem_area}.txt";
			$data_info->regist_device($host_suffix, 'Oracle', "ora_shared_pool", 
				$mem_area, undef, \@headers);
			$data_info->simple_report($output, $results{$instance}{$mem_area}, \@headers);
		}
	}
	return 1;
}

1;
