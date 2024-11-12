package Getperf::Command::Site::Oracle::OraLatchLibCache;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use base qw(Getperf::Container);

sub new {bless{},+shift}

# SAMPLE_TIME         latch_ccont   UL_count session_count
# ------------------- ----------- ---------- -------------
# 2022/11/11 12:06:09           3          0             0
# 2022/11/11 12:06:19           5          0             0
# 2022/11/11 12:06:29           5          0             0
# 2022/11/11 12:06:39           5          0             0
# 2022/11/11 12:06:49           5          0             0

sub parse {
    my ($self, $data_info) = @_;

	my %results;
	my $step = 10;
	my @headers = qw/latch_ccont UL_count session/;

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
		if ($line=~/Date:(.*)/) {		# parse time: 16/05/23 14:56:52
			$sec = localtime(Time::Piece->strptime($1, '%y/%m/%d %H:%M:%S'))->epoch;
			next;
		}
		print $line . "\n";
		if ($line=~/^([\d\/]+)\s(.+)$/) {
			my ($date, $body) = ($1, $2);
			# print "(DATE: $date BODY: $body)\n";
			my ($tms, @values) = split(/\s*[\|,\s]\s*/, $body);
			# print "(TMS: $tms)\n";
			$sec = localtime(Time::Piece->strptime("$date $tms", '%Y/%m/%d %H:%M:%S'))->epoch;
			$results{$sec} = join(' ', @values);
		}
	}
	close($in);
	# print Dumper \%results;
	$data_info->regist_metric($instance, 'Oracle', 'ora_latch_lib_cache', \@headers);
	my $output = "Oracle/${instance}/ora_latch_lib_cache.txt";	# Remote collection
	$data_info->simple_report($output, \%results, \@headers);

	return 1;
}

1;
