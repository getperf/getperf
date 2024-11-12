package Getperf::Command::Site::Oracle::OraspEventDetail;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use base qw(Getperf::Container);
use Getperf::Command::Master::Oracle;
use Getperf::Command::Site::Oracle::AwrreportHeaderRac;

sub new {bless{},+shift}

sub camelize {
    my ($s) = @_;
    $s =~ s/(:|-)//g;
    $s =~ s/(_|\b)([a-z])/\u$2/g;
    $s =~ s/[\/\s\*\(\)]+//g;
    # (my $s = shift) =~ s/(?:\s+^|_|\s+|:)(.)/\U$1/g;
    $s;
}

sub parse {
    my ($self, $data_info) = @_;
	my $results;
	my $step = 600;
	my @headers = qw/elapse/;
	my $waitClasses = get_wait_classes();
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
	    $line =~ s/^ *(.*?) *$/$1/;		# LR trim

		if ($line=~/Date:(.*)/) {		# parse time: 16/05/23 14:56:52
			$sec = localtime(Time::Piece->strptime($1, '%y/%m/%d %H:%M:%S'))->epoch;
			next;
		}
        my @csv = split(/\s*\|\s*/, $line);
        my $colnum = scalar(@csv);
        # print "$colnum:$line\n"; 
        # 最新版使用率のみ
		if ($colnum == 9) {
			my ($instanceNo, $snapIdStart, $snapIdEnd, $event, $count, $elapse, $avgWait, $callTime, $waitClass) = @csv;
			next if (!defined($instanceNo) || $instanceNo!~/^[\d\s]+$/);
			# $sec = localtime(Time::Piece->strptime($tms, '%y/%m/%d %H:%M:%S'))->epoch;
			my $instance = $instancePrefix;
			$instance .= $instanceNo if ($instanceNo > 1);
			my $waitClassAlias = $waitClasses->{$waitClass} || "99_" . camelize($waitClass);
			$waitClassAlias=~s/^\d+_//g; # 先頭の数番を取り除く

            my $eventAlias = camelize($event);
			print "($instanceNo, $waitClass, $waitClassAlias, $event, $eventAlias, $elapse)\n";
			$results->{$instance}{$waitClassAlias}{$eventAlias}{'data'}{$sec} = $elapse;
			$results->{$instance}{$waitClassAlias}{$eventAlias}{'event'} = $event;
        }
	}
	close($in);
	# print Dumper $results;
	for my $instance(keys %{$results}) {
		print $instance . "\n";
		for my $waitClassAlias(keys %{$results->{$instance}}) {
			print $waitClassAlias . "\n";
            for my $eventAlias(keys %{$results->{$instance}{$waitClassAlias}}) {
                print "   " . $eventAlias . "\n";
    			# my $eventAlias
                my $metric = "orasp_bgevent_${waitClassAlias}";
                my $event = $results->{$instance}{$waitClassAlias}{$eventAlias}{'event'};
    			$data_info->regist_device($instance, 'Oracle', $metric, $eventAlias, $event, \@headers);
    			my $output = "Oracle/${instance}/device/${metric}__${eventAlias}.txt";
    			my $data = $results->{$instance}{$waitClassAlias}{$eventAlias}{'data'};
    			$data_info->simple_report($output, $data, \@headers);
            }
		}
	}
	return 1;
}

1;
