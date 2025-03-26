package Getperf::Command::Site::Db2::Db2ReadRow;
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
    my @headers = qw/rowsRead rowsReturned readSelectRatio/;

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
    my $defalutDat = {$sec => "0 0 0"};
    duplicateDat($defalutDat, $sec, "0 0 0");
    my @databases = db_list(0);
    for my $db(@databases) {
    # for my $service(keys %{$results}) {
        my $service = "${site}-${db}";
        print $service. "\n"; 
        $data_info->regist_metric($service, 'Db2', 'db2_read_row', \@headers);
        my $output = "Db2/${service}/db2_read_row.txt";
        my $dat = (defined($results->{$service})) ?
                    $results->{$service} : $defalutDat;
        $data_info->simple_report($output, $dat, \@headers);
    }
    return 1;
}

1;
