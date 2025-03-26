package Getperf::Command::Site::Oracle::Dbmemsize;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use base qw(Getperf::Container);

sub new {bless{},+shift}

# Date:16/06/09 00:05:00
# DEFAULT buffer cache,16640
# KEEP buffer cache,10240
# java pool,1536
# keep_use_size,18646
# large pool,1792
# sga_max_size,98560
# shared pool,18176
# streams pool,512

sub parse {
    my ($self, $data_info) = @_;

	my %results;
	my $step = 3600;
	my @headers = qw/mbyte/;

	$data_info->is_remote(1);
	$data_info->step($step);
	my $host = $data_info->file_suffix;
	my $sec  = $data_info->start_time_sec->epoch;
	open( IN, $data_info->input_file ) || die "@!";
	while (my $line = <IN>) {
		next if ($line=~/^Date:/);	# skip header
		$line=~s/(\r|\n)*//g;			# trim return code
		my @csv = split(/\s*[\,|]\s*/, $line);
		next if (scalar(@csv) != 2 || $csv[0] eq 'NAME');
		my ($memory_area, $mbyte) = @csv;
		$mbyte = 0 if (!defined($mbyte));
		$memory_area = lc $memory_area;
		$memory_area =~s/\s+/_/g;
		$results{$memory_area}{$sec} += $mbyte;
	}
	close(IN);
	my @metric_size = qw/keep_use_size keep_buffer_size/;
	my @metric_usage = qw/keep_buffer_cache default_buffer_cache shared_pool
		large_pool java_pool/;
	# for my $memory_area(keys %results) {
	for my $memory_area(@metric_size , @metric_usage) {
		# print "KEY:$memory_area\n";
		my $output = "Oracle/${host}/device/ora_mem_sga__${memory_area}.txt";
		my $data   = $results{$memory_area};
		$data = {$sec => 0} if !($data);
		# print Dumper $data;
		$data_info->regist_device($host, 'Oracle', "ora_mem_sga", $memory_area, undef, \@headers);
		$data_info->simple_report($output, $data, \@headers);
	}
    $data_info->regist_devices_alias($host, 'Oracle', 'ora_mem_sga', 
        'ora_mem_sga_by_size', \@metric_size, undef);
    $data_info->regist_devices_alias($host, 'Oracle', 'ora_mem_sga', 
        'ora_mem_sga_by_usage', \@metric_usage, undef);
	return 1;
}

1;
