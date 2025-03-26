package Getperf::Command::Site::Db2::Db2MonQcap;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use base qw(Getperf::Container);
use Getperf::Command::Master::Db2;

my %metrics = (
	'ROWS_PUBLISHED',      'trans',
	'TRANS_PUBLISHED',     'trans',
	'CHG_ROWS_SKIPPED',    'event',
	'DELROWS_SUPPRESSED',  'event',
	'ROWS_SKIPPED',        'event',
	'LOBS_TOO_BIG',        'event',
	'XMLDOCS_TOO_BIG',     'event',
	'QFULL_ERROR_COUNT',   'event',
	'MQ_BYTES',            'resource',
	'MQ_MESSAGES',         'trans',
	'MQPUT_TIME',          'mq',
);

sub new {bless{},+shift}
sub parse {
    my ($self, $data_info) = @_;
    my $results;
    my $step = 30;
    $data_info->step($step);
    $data_info->is_remote(1);
    my $host = $data_info->file_suffix || $data_info->host;
    my $sec  = $data_info->start_time_sec->epoch;

    my $header_groups;
    for my $metric(sort keys %metrics) {
        my $category = $metrics{$metric};
        push(@{$header_groups->{$category}}, $metric);
    }
    open( my $in, $data_info->input_file ) || die "@!";
    my $device = 'Unkown';

    my $stats;
    while (my $line = <$in>) {
        # print $line;
        $line=~s/(\r|\n)*//g;           # trim return code
        next if ($line!~/^([A-Z][A-Z|_].+?)\s+(.+?)$/);
        my ($metric, $value) = ($1, $2);
        # print "0:($metric, $value)\n";
        if ($metric eq 'SENDQ') {
            $device = $value;

        } elsif ($metric eq 'MONITOR_TIME') {
            my $tms = $value;
            $tms=~s/\.\d+//g;
            $sec = localtime(Time::Piece->strptime($tms, '%Y-%m-%d %H:%M:%S'))->epoch;
            # print "MONITOR_TIME : $tms,$sec\n";

        } else {
            # print " ($metric, $value)\n";
            if ($metrics{$metric}) {
                $results->{$device}{$metric}{$sec}{'value'} = $value;
            }
            $stats->{$host}->{"$metric|$device"}{$sec} = $value;
        }
    }
    close($in);
   #  print Dumper $results;
   #  for my $host(keys %{$stats}) {
   #      my $options = {'enable_first_load' => 1, 'use_absolute_value' => 1};
   #      db2_update_stats($data_info, $host, 'mon_get_irs', 
   #          $stats->{$host}, $options);
   #  }
    my @headers = qw/value/;
    for my $queue(keys %{$results}) {
			print "QUEUE: $queue\n";
        my $queue_results = $results->{$queue};
        for my $metric(keys %{$queue_results}) {
            my $metric_results = $queue_results->{$metric};
            $data_info->regist_device($queue, 'Db2',
                'db2_mon_qcap', $metric, undef, \@headers);
            my $output = "Db2/${queue}/device/db2_mon_qcap__${metric}.txt";
            # print "OUT: $output \n";
            $data_info->pivot_report($output, $metric_results, \@headers);
        }
        for my $category(keys %{$header_groups}) {
            my $metrics = $header_groups->{$category};
            $data_info->regist_devices_alias($queue, 'Db2', 
                'db2_mon_qcap',
                'db2_mon_qcap_by_' . $category,
                $metrics, undef);
        }
    }
    return 1;
}

1;
