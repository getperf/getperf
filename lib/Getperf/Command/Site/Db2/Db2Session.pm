package Getperf::Command::Site::Db2::Db2Session;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use base qw(Getperf::Container);
use Getperf::Command::Master::Db2;

sub new {bless{},+shift}

# Saving all output to "/home/zabbix/ptune/log/Db2/20200904/090000/db2_session__CAPA_D1.txt". Enter "record" with no arguments to stop it.
# +-----------------------+---------+--------+----------------+
# |   METRIC_TIMESTAMP    | DB_NAME | MEMBER | APPLS_CUR_CONS |
# +-----------------------+---------+--------+----------------+
# | 2020-09-04 09:00:00.0 | MMDB    | 0      | 74             |
# | 2020-09-04 09:00:00.0 | MMDB    | 1      | 69             |
# | 2020-09-04 09:00:00.0 | MMDB    | 2      | 74             |
# | 2020-09-04 09:00:00.0 | RTDDB   | 0      | 370            |
# | 2020-09-04 09:00:00.0 | RTDDB   | 1      | 44             |
# | 2020-09-04 09:00:00.0 | RTDDB   | 2      | 49             |
# | 2020-09-04 09:00:00.0 | SCHDB   | 0      | 1              |
# | 2020-09-04 09:00:00.0 | SCHDB   | 1      | 1              |
# | 2020-09-04 09:00:00.0 | SCHDB   | 2      | 1              |
# | 2020-09-04 09:00:00.0 | SMDB0   | 0      | 70             |
# | 2020-09-04 09:00:00.0 | SMDB1   | 0      | 12             |
# | 2020-09-04 09:05:00.0 | URADB   | 0      | 217            |
# | 2020-09-04 09:05:00.0 | URADB   | 1      | 32             |
# | 2020-09-04 09:05:00.0 | URADB   | 2      | 18             |
# +-----------------------+---------+--------+----------------+

sub parse {
    my ($self, $data_info) = @_;

    my $results;
    my $step = 600;
    my @headers = qw/applsCurCons/;

    $data_info->step($step);
    $data_info->is_remote(1);
    my $site = $data_info->file_suffix;
    my $sec  = $data_info->start_time_sec->epoch;

    open( my $in, $data_info->input_file ) || die "@!";
    while (my $line = <$in>) {
        $line=~s/(\r|\n)*//g;           # trim return code
        next if ($line!~/^\|\s*\d/);    # skip without "| 2020-09-...""
        $line =~s/,//g;                 # trim numeric comma : ','
        $line =~s/null/0/g;             # normalize null
        my @csv = split(/\s*\|\s*/, $line);
        shift(@csv);
        my ($date, $db, $member, @columns) = @csv;
        my $dat = join(" ", @columns);
        $results->{"${site}-${db}-${member}"}{$sec} = $dat;
        duplicateDat($results->{"${site}-${db}-${member}"}, $sec, $dat);
    }
    close($in);
    my $defalutDat = {$sec => "0"};
    duplicateDat($defalutDat, $sec, "0");
    my @databases = db_list(0);
    for my $db(@databases) {
    # for my $service(keys %{$results}) {
        my $service = "${site}-${db}";
        print $service. "\n"; 
        $data_info->regist_metric($service, 'Db2', 'db2_session', \@headers);
        my $output = "Db2/${service}/db2_session.txt";
        my $dat = (defined($results->{$service})) ?
                    $results->{$service} : $defalutDat;
        $data_info->simple_report($output, $dat, \@headers);
    }
    return 1;
}

1;
