package Getperf::Command::Site::JVM::Jvmlist;
use strict;
use warnings;
use Path::Class;
use Data::Dumper;
use Time::Piece;
use base qw(Getperf::Container);
use Getperf::Command::Master::JVM;

sub new {bless{},+shift}

#                              0      1      2      3        4        5         6
# NPW_FosbStockerOut_130809-1, S0C    S1C    S0U    S1U      EC       EU        OC
#          7        8      9     10      11      12     13       14
#          OU       PC     PU    YGC     YGCT    FGC    FGCT     GCT
# NPW_FosbStockerOut_130809-1,1088.0 1088.0  0.0   1088.0 36096.0  15543.0   76352
# .0    57827.2   17920.0 17791.6   8231   74.907  313    97.640  172.546
# NPW_FosbStockerOut_130809-1,1088.0 1088.0  0.0   1088.0 36096.0  17853.0   76352
# .0    57827.2   17920.0 17791.6   8231   74.907  313    97.640  172.546

sub parse {
    my ($self, $data_info) = @_;

	my %results;
	my $step = 60;
	my @headers = qw/eu ou pu ygc ygct fgc fgct/;

	$data_info->step($step);
	my $host = $data_info->host;

	my $start_sec  = $data_info->start_time_sec->epoch;
	if (!$start_sec) {
		return;
	}
	my $log_dir = $data_info->input_dir;
	open( my $in, $data_info->input_file ) || die "@!";
	while (my $line = <$in>) {
		$line=~s/(\r|\n)*//g;			# trim return code
		next if ($line!~/^(\d+),(.+)$/);
		my ($pid, $instance) = ($1, $2);
		my $jvmstat_file = file($log_dir, "${instance}.txt");
		next if (! -f $jvmstat_file);
		my $sec = $start_sec;
		open ( my $jvm_in, $jvmstat_file) || die "@!";
		while (my $jvm_line = <$jvm_in>) {
			next if ($jvm_line!~/^\d/);
			my @csvs  = split(' ', $jvm_line);
			my @datas = @csvs[5,7,9..13];
			for my $elapse_idx(4, 6) {
				$datas[$elapse_idx] = int($datas[$elapse_idx] * 1000);
			}
			my $instance_id = $instance;
			$instance_id =~s/_[0-9]{6}.*$//g;
			$results{$instance_id}{$sec} = join(' ', @datas);
			$sec += $step;
		}
		close ($jvm_in);
	}
	close($in);
	for my $instance_id(keys %results) {
		$data_info->regist_device($host, 'JVM', 'jvmstat', $instance_id, $instance_id, \@headers);
		my $output = "device/jvmstat__${instance_id}.txt";
		$data_info->simple_report($output, $results{$instance_id}, \@headers);
	}
	return 1;
}

1;
