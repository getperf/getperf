package Getperf::Command::Site::Oracle::OraspEvent;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use base qw(Getperf::Container);
use Getperf::Command::Master::Oracle;
use Getperf::Command::Site::Oracle::AwrreportHeaderRac;

sub new {bless{},+shift}

sub parse {
    my ($self, $data_info) = @_;

	my $results;
	my $step = 600;
	my $statspack_events = get_wait_classes();
	my @headers = sort values %{$statspack_events}; 

	$data_info->step($step);
	$data_info->is_remote(1);
	my $instancePrefix = $data_info->file_suffix;
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
        my @csv = split(/\s*\|\s*/, $line);
        my $colnum = scalar(@csv);
		if ($colnum == 4) {
			my ($instanceNo, $tms, $event, $usage) = @csv;
			# print "TMS:$tms\n";
			# $sec = localtime(Time::Piece->strptime($tms, '%y/%m/%d %H:%M:%S'))->epoch;
			next if (!defined($event) || $event eq 'WAIT_CLASS');
			my $instance = $instancePrefix;
			$instance .= $instanceNo if ($instanceNo > 1);
			my $eventAlias = $statspack_events->{$event} || "Other";
			$usage=~s/,//g;
			$results->{$instance}{$sec}{$eventAlias} = $usage;
        }
	}
	close($in);
	for my $instance(keys %{$results}) {
		print $instance . "\n";
		my $dat = $results->{$instance};
		$data_info->regist_metric($instance, 'Oracle', 'orasp_event', \@headers);
		my $output = "Oracle/${instance}/orasp_event.txt";
		$data_info->pivot_report($output, $dat, \@headers);
	}
	return 1;
}

1;
