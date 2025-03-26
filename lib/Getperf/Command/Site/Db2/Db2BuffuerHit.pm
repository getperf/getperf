package Getperf::Command::Site::Db2::Db2BuffuerHit;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use base qw(Getperf::Container);
use Getperf::Command::Master::Db2;

sub new {bless{},+shift}

sub parse {
    my ($self, $data_info) = @_;

    my $results;
    my $step = 600;
    my @headers = qw/logicalRd physicalRd hit/;

    $data_info->step($step);
    $data_info->is_remote(1);
    my $site = $data_info->file_suffix;
    my $sec  = $data_info->start_time_sec->epoch;

    open( my $in, $data_info->input_file ) || die "@!";
    while (my $line = <$in>) {
        $line=~s/(\r|\n)*//g;           # trim return code
        next if ($line!~/^\|\s*\d/);    # skip without "| 2020-09-...""
        $line =~s/,//g;                 # trim numeric comma : ','
        $line =~s/null/NaN/g;             # normalize null
        my @csv = split(/\s*\|\s*/, $line);
        shift(@csv);
        my ($date, $db, $bp, $logicalRd, $physicalRd, $hit, $member) = @csv;
        my $dat = "$logicalRd $physicalRd $hit";
        $results->{"${site}-${db}-${member}"}{$bp}{$sec} = $dat;
        duplicateDat($results->{"${site}-${db}-${member}"}{$bp}, $sec, $dat);
    }
    close($in);
    my $defalutDat = {$sec => "0 0 0"};
    duplicateDat($defalutDat, $sec, "0 0 0");
    # print Dumper $results;
    my @databases = db_list(0);
    for my $db(@databases) {
    # for my $service(keys %{$results}) {
        my $service = "${site}-${db}";
        # print $service; exit;
        my $db2 = $db;
        $db2=~s/-\d//g;
        $data_info->regist_node($service, 
                                'Db2', 
                                'info/node', 
                                {node_path => "/$site/${db2}/$service"});

        # print Dumper \@bps;
        my @defaultBps = alias_bp($db2);
        for my $bp(@defaultBps) {
            $data_info->regist_device($service, 'Db2', 'db2_buffer_hit', $bp, undef, \@headers);
            my $output = "Db2/${service}/device/db2_buffer_hit__${bp}.txt";
            my $dat = (defined($results->{$service}{$bp})) ?
                        $results->{$service}{$bp} : $defalutDat;
                        # : {$sec => "0 0 0"};
            $data_info->simple_report($output, $dat, \@headers);
        }
    }
    return 1;
}

1;
