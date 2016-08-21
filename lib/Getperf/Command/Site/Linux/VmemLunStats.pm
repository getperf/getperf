package Getperf::Command::Site::Linux::VmemLunStats;
use strict;
use warnings;
use Path::Class;
use Data::Dumper;
use Time::Piece;
use base qw(Getperf::Container);

sub new {bless{},+shift}

sub parse {
    my ($self, $data_info) = @_;

	my %results;
	my $step = 5;
	my @headers = qw/kr_s rcmd_s rrs kw_s wcmd_s wrs/;

	$data_info->step($step);
	my $host = $data_info->host;
	my $sec  = $data_info->start_time_sec;
	if (!$sec) {
		return;
	}
	my $idir = file($data_info->file_path)->parent;
	my %luns = ();
	open(IN, "$idir/vmem_lun.txt") || die "Can't open $idir/vmem_lun.txt $!\n";
	while (<IN>) {
		chop;
		my @csvs = split(/,/, $_);
		my $lun_id   = $csvs[0];
		my $lun_name = $csvs[6];
		$luns{$lun_id} = $lun_name;
	}
	close(IN);

	open( IN, $data_info->input_file ) || die "@!";
	while (my $line = <IN>) {
		$line=~s/(\r|\n)*//g;			# trim return code
		my @csvs = split(/,/, $line);
		my $timestamp = shift(@csvs);
		my $localtime = localtime($timestamp/1000);
		#'%Y-%m-%dT%H:%M:%S'
		my $time_key  = $localtime->ymd("-") . "T" . $localtime->hms;
		my $lun_id    = shift(@csvs);
		my $interval  = shift(@csvs);

		next if ($interval ne '10000');
		for my $interface(qw/a b/) {
			if (defined(my $lun_name = $luns{$lun_id})) {
				my $group_key = "${lun_name}_${interface}";
				for my $item(qw/kr_s rcmd_s rrs kw_s wcmd_s wrs/) {
					my $value = shift(@csvs) || 0;
					$results{$group_key}{$time_key}{$item}  = $value;
					$results{$lun_name}{$time_key}{$item}  += $value;
				}
			}
		}
	}
	close(IN);
	for my $interface(keys %results) {
		my $output_file = "device/vmem_lun__${interface}.txt";
		$data_info->regist_device($host, 'Violin', 'vmem_lun', $interface, undef, \@headers);
		$data_info->pivot_report($output_file, $results{$interface}, \@headers);
	}
	return 1;
}

1;
