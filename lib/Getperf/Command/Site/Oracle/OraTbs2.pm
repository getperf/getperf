package Getperf::Command::Site::Oracle::OraTbs2;
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
	my @headers = qw/total_gb max_gb used_gb usage/;

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
        if ($line=~/^Date/ || $line !~/\d$/) {
            next;
        }

	# my @headers = qw/total_gb max_gb used_gb usage/;
        my @csv = split(/\s*\|\s*/, $line);
        my $colnum = scalar(@csv);
		# print "$line:$colnum\n";

		# temp 表領域を含む新版SQL結果の解析
		if ($colnum == 7) {
			my ($tbs, $total_mb, $used_mb, $usage, $available_mb, 
				$max_total_mb, $ max_usage) = @csv;
			my $total_gb = $total_mb / 1024.0;
			my $max_gb   = $max_total_mb / 1024.0;
			my $used_gb  = $used_mb / 1024.0;
			$results->{$tbs}{$sec} = "${total_gb} ${max_gb} ${used_gb} ${usage}";
		# 旧版SQL結果の解析
		} elsif ($colnum == 4) {
			my ($date, $tbs, @values) = @csv;
			$results->{$tbs}{$sec} = join(' ', @values);
		}
	}
	close($in);
	# print Dumper $results;
    for my $tbs(keys %{$results}) {
        $data_info->regist_device($instance, 'Oracle', 'ora_tbs2', $tbs, undef, \@headers);
        my $output = "Oracle/${instance}/device/ora_tbs2__${tbs}.txt";
        $data_info->simple_report($output, $results->{$tbs}, \@headers);
    }
	return 1;
}

1;
