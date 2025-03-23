package Getperf::Command::Site::Db2::Db2PageReclaims;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use base qw(Getperf::Container);
use Getperf::Command::Master::Db2;

sub new {bless{},+shift}

# Saving all output to "/tmp/db2_page_reclaims.txt". Enter "record" with no arguments to stop it.
# +---------+------------------+-----------+---------+-------------------+--------------------------------+---------------------+
# | DB_NAME | METRIC_TIMESTAMP | TABSCHEMA | OBJTYPE | "PAGE_RECLAIMS_X" | "SPACEMAPPAGE_PAGE_RECLAIMS_X" | "RECLAIM_WAIT_TIME" |
# +---------+------------------+-----------+---------+-------------------+--------------------------------+---------------------+
# +---------+------------------+-----------+---------+-------------------+--------------------------------+---------------------+

sub parse {
    my ($self, $data_info) = @_;

    my $results;
    my $step = 600;
    my @headers = qw/pageReclX spaceMapPageReclX reclaimWaitTime/;

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
        my ($db, $date, $schema, $objType, @columns) = @csv;
        my $dat = join(" ", @columns);
        $results->{"${site}-${db}"}{"${schema}-${objType}"}{$sec} = $dat;
        duplicateDat($results->{"${site}-${db}"}{"${schema}-${objType}"}, $sec, $dat);
    }
    close($in);
    my $defalutDat = {$sec => "0 0 0"};
    duplicateDat($defalutDat, $sec, "0 0 0");
    # print Dumper $defalutDat; exit;
    my @databases = db_list(1);
    for my $db(@databases) {
        my $service = "${site}-${db}";
        $data_info->regist_node($service, 
                                'Db2', 
                                'info/node2', 
                                {node_path => "/$site/$db/$service"});
        my @defaultReclaimPages = alias_reclaim_page($db);
        for my $defaultReclaimPage(@defaultReclaimPages) {
            for my $objectType(qw/TABLE INDEX/) {
                my $schema = "${defaultReclaimPage}-${objectType}";
                $data_info->regist_device($service, 'Db2', 'db2_page_reclaims', $schema, undef, \@headers);
                my $output = "Db2/${service}/device/db2_page_reclaims__${schema}.txt";
                my $dat = (defined($results->{$service}{$schema})) ?
                            $results->{$service}{$schema} : $defalutDat;
                $data_info->simple_report($output, $dat, \@headers);
            }
        }
    }
    return 1;
}

1;
