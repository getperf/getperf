package Getperf::Command::Site::Db2::Db2LockWait;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use base qw(Getperf::Container);
use Getperf::Command::Master::Db2;

sub new {bless{},+shift}

# Saving all output to "/home/zabbix/ptune/log/Db2/20200904/090000/db2_lock_wait__CAPA_D1.txt". Enter "record" with no arguments to stop it.
# +---------+------------------+--------+------------------+-----------+-------------+---------------+----------------+------------+-------------------+-----------------------+----------------------+----------------------+----------------------+--------------------+
#
# DB_NAME | METRIC_TIMESTAMP | MEMBER | LOCK_LIST_IN_USE | DEADLOCKS | LOCK_ESCALS | LOCK_TIMEOUTS | LOCK_WAIT_TIME | LOCK_WAITS | LOCK_WAITS_GLOBAL | LOCK_WAIT_TIME_GLOBAL | LOCK_TIMEOUTS_GLOBAL | LOCK_ESCALS_MAXLOCKS | LOCK_ESCALS_LOCKLIST | LOCK_ESCALS_GLOBAL |
# +---------+------------------+--------+------------------+-----------+-------------+---------------+----------------+------------+-------------------+-----------------------+----------------------+----------------------+----------------------+--------------------+
# +---------+------------------+--------+------------------+-----------+-------------+---------------+----------------+------------+-------------------+-----------------------+----------------------+----------------------+----------------------+--------------------+

sub parse {
    my ($self, $data_info) = @_;

    my $results;
    my $step = 600;
    my @headers = qw/lockListInUse deadlocks lockEscals lockTimeouts lockWaitTime lockWaits lockWaitsGlobal lockWaitTimeGlobal lockTimeoutsGlobal lockEscalsMaxlocks lockEscalsLocklist lockEscalsGlobal/;

    $data_info->step($step);
    $data_info->is_remote(1);
    my $site = $data_info->file_suffix;
    my $sec  = $data_info->start_time_sec->epoch;

    open( my $in, $data_info->input_file ) || die "@!";
    while (my $line = <$in>) {
        $line=~s/(\r|\n)*//g;           # trim return code
        next if ($line!~/^\|.*\d\s*\|$/);    # skip without "| ... 0 |"
        $line =~s/,//g;                 # trim numeric comma : ','
        $line =~s/null/0/g;             # normalize null
        my @csv = split(/\s*\|\s*/, $line);
        shift(@csv);
        my ($db, $date, $member, @columns) = @csv;

        my $dat = join(" ", @columns);
        $results->{"${site}-${db}-${member}"}{$sec} = $dat;
        duplicateDat($results->{"${site}-${db}-${member}"}, $sec, $dat);
    }
    close($in);

    my $defalutDat = {$sec => "0 0 0 0 0 0 0 0 0 0 0 0"};
    duplicateDat($defalutDat, $sec, "0 0 0 0 0 0 0 0 0 0 0 0");
    my @databases = db_list(0);
    for my $db(@databases) {
    # for my $service(keys %{$results}) {
        my $service = "${site}-${db}";
        # print $service; exit;
        $data_info->regist_metric($service, 'Db2', 'db2_lock_wait', \@headers);
        my $output = "Db2/${service}/db2_lock_wait.txt";
        my $dat = (defined($results->{$service})) ?
                    $results->{$service} : $defalutDat;
        $data_info->simple_report($output, $dat, \@headers);
    }
    return 1;
}

1;
