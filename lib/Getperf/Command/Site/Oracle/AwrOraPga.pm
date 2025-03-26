package Getperf::Command::Site::Oracle::AwrOraPga;
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
		next if (scalar(@csv) != 4 || $csv[0] eq 'DATE');
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

	my @metrics = qw/maximum_pga_allocated total_pga_inuse pga_aggregate_limit 
		aggregate_pga_target_parameter aggregate_pga_auto_target 
		total_freeable_pga_memory total_pga_allocated/;
	my @metrics2 = qw/total_pga_used_for_auto_workareas
		maximum_pga_used_for_manual_workareas
		maximum_pga_used_for_auto_workareas
		global_memory_bound/;
	my @metrics3 = qw/cache_hit_percentage/;

	for my $instance(keys %results) {
        my $host_suffix = $host;
        $host_suffix = "${host}_${instance}" if ($instance > 1);
        for my $mem_area(@metrics, @metrics2, @metrics3) {
        	if (!defined($results{$instance}{$mem_area})){
        		$results{$instance}{$mem_area} = { $sec => 0};
        	}
        }
		for my $mem_area(keys %{$results{$instance}}) {
			my $output = "Oracle/${host_suffix}/device/ora_pga__${mem_area}.txt";
			$data_info->regist_device($host_suffix, 'Oracle', "ora_pga", 
				$mem_area, undef, \@headers);
			$data_info->simple_report($output, $results{$instance}{$mem_area}, \@headers);
		}
	    $data_info->regist_devices_alias($host_suffix, 'Oracle', 'ora_pga', 
	        'ora_pga_main', \@metrics, undef);
	    $data_info->regist_devices_alias($host_suffix, 'Oracle', 'ora_pga', 
	        'ora_pga_workarea', \@metrics2, undef);
	    $data_info->regist_devices_alias($host_suffix, 'Oracle', 'ora_pga', 
	        'ora_pga_cachehit', \@metrics3, undef);

	}
	return 1;
}

1;
