package Getperf::Command::Site::Db2::Db2MonIrs;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use base qw(Getperf::Container);
use Getperf::Command::Master::Db2;

my %metrics = (
    'APPLY_LATENCY',        'latency',
    'CAPTURE_LATENCY',      'latency',
    'CURRENT_MEMORY',       'resource',
    'DEADLOCK_RETRIES',     'event',
    'DEPENDENCY_DELAY',     'waittime',
    'END2END_LATENCY',      'latency',
    'HEARTBEAT_LATENCY',    'latency',
    'JOB_DEPENDENCIES',     'depend',
    'KEY_DEPENDENCIES',     'depend',
    'MCGSYNC_DELAY',        'event',
    'MONSTER_TRANS',        'event',
    'MQ_BYTES',             'resource',
    'NUM_DBMS_COMMITS',     'mq',
    'NUM_MQGETS',           'mq',
    'NUM_MQMSGS',           'mq',
    'OKSQLSTATE_ERRORS',    'event',
    'Q_PERCENT_FULL',       'event',
    'QDEPTH',               'mqdepth',
    'QLATENCY',             'latency',
    'RI_DEPENDENCIES',      'depend',
    'RI_RETRIES',           'event',
    'ROWS_APPLIED',         'rows',
    'ROWS_LOADED',          'rows',
    'ROWS_NOT_APPLIED',     'rows',
    'ROWS_PROCESSED',       'rows',
    'ROWS_PROCESSED_MRI',   'rows',
    'SPILLED_ROWS',         'count',
    'SPILLEDROWSAPPLIED',   'count',
    'STMTS_PREPARED',       'count',
    'TABLE_DEPENDENCIES',   'count',
    'TABLES_LOADED',        'count',
    'TRANS_APPLIED',        'trans',
    'TRANS_READ',           'trans',
    'TRANS_SERIALIZED',     'trans',
    'TRANS_STREAM_BEGIN',   'trans',
    'TRANS_STREAM_COMMIT',  'trans',
    'TRANS_STREAMING',      'trans',
    'UNAVAIL_RES_RETRIES',  'count',
    'UNIQ_DEPENDENCIES',    'depend',
    'UNIQ_RETRIES',         'count',
    'WORKQ_WAIT_TIME',      'waittime',
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
        if ($metric eq 'RECVQ') {
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
    # print Dumper $results;
    for my $host(keys %{$stats}) {
        my $options = {'enable_first_load' => 1, 'use_absolute_value' => 1};
        db2_update_stats($data_info, $host, 'mon_get_irs', 
            $stats->{$host}, $options);
    }
    my @headers = qw/value/;
    for my $queue(keys %{$results}) {
        my $queue_results = $results->{$queue};
        for my $metric(keys %{$queue_results}) {
            my $metric_results = $queue_results->{$metric};
            $data_info->regist_device($queue, 'Db2',
                'db2_mon_irs', $metric, undef, \@headers);
            my $output = "Db2/${queue}/device/db2_mon_irs__${metric}.txt";
            # print "OUT: $output \n";
            $data_info->pivot_report($output, $metric_results, \@headers);
        }
        for my $category(keys %{$header_groups}) {
            my $metrics = $header_groups->{$category};
            $data_info->regist_devices_alias($queue, 'Db2', 
                'db2_mon_irs',
                'db2_mon_irs_by_' . $category,
                $metrics, undef);
        }
    }
    return 1;
}

1;
