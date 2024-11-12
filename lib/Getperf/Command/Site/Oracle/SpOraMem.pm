package Getperf::Command::Site::Oracle::SpOraMem;
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
		next if (scalar(@csv) != 4 || $csv[2] eq 'NAME');
		my ($tms, $instance, $mem_area, $byte) = @csv;
		# $mem_area = camelize($mem_area);
		$byte =~s/,//g;
		$byte = 0 if (!defined($byte));
		$mem_area = lc $mem_area;
		$mem_area =~s/[\$\s]+/_/g;
		print "($tms, $instance, $mem_area, $byte)\n";
		$results{$instance}{$mem_area}{$sec} += $byte;
	}
	close(IN);
	for my $instance(keys %results) {
        my $host_suffix = $host;
        $host_suffix = "${host}_${instance}" if ($instance > 1);
		for my $mem_area(keys %{$results{$instance}}) {
			my $output = "Oracle/${host_suffix}/device/ora_mem__${mem_area}.txt";
			$data_info->regist_device($host_suffix, 'Oracle', "ora_mem", 
				$mem_area, undef, \@headers);
			$data_info->simple_report($output, $results{$instance}{$mem_area}, \@headers);
		}
	}
	return 1;
}

1;
