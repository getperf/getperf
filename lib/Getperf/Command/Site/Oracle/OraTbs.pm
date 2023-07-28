package Getperf::Command::Site::Oracle::OraTbs;
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
	my $step = 600;
	my @headers = qw/total_gb max_gb usage used_gb/;

	$data_info->step($step);
	$data_info->is_remote(1);
	my $instance = $data_info->file_suffix;
	my $sec  = $data_info->start_time_sec->epoch;
	if (!$sec) {
		return;
	}

	open( my $in, $data_info->input_file ) || die "@!";
	while (my $line = <$in>) {
		$line=~s/(\r|\n)*//g;			# trim return code
		# print " ${line}\n";
		$line=~s/,//g;
		next if ($line=~/^RTIME\s+/);
		next if ($line=~/^\s*TABLESPACE_NAME\s+/);
		# print " ${line}\n";
		my (@values) = split(/\s*\|\s*/, $line);
		my $n_col = scalar(@values);
		if ($n_col == 5) {
			my ($tbs, $total_gb, $used_gb, $usage, $max_gb) = split(/\s*\|\s*/, $line);
			$results->{$tbs}{$sec} = "${total_gb} ${max_gb} ${usage} ${used_gb}";
			# print "${tbs} : ${total_gb} ${max_gb} ${used_gb} ${usage}\n\n";
		} else {
			my ($date, $tbs, $total_gb, $max_gb, $used_gb, $usage) = split(/\s*\|\s*/, $line);
			$tbs = '' if !defined($tbs);
			next if ($tbs eq '');
			$results->{$tbs}{$sec} = "${total_gb} ${max_gb} ${usage} ${used_gb}";
			# print "${tbs} : ${total_gb} ${max_gb} ${used_gb} ${usage}\n\n";
		}
	}
	close($in);
    for my $tbs(keys %{$results}) {
        $data_info->regist_device($instance, 'Oracle', 'ora_tbs', $tbs, undef, \@headers);
        my $output = "Oracle/${instance}/device/ora_tbs__${tbs}.txt";
        $data_info->simple_report($output, $results->{$tbs}, \@headers);
    }
	return 1;
}

1;
