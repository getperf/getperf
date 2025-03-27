package Getperf::Command::Site::AIX::Siviewbusy;

use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use base qw(Getperf::Container);

sub new {bless{},+shift}

sub parse {
    my ($self, $data_info) = @_;

    my %results;
    my $step = 60;
    my @headers = qw/pct/;

    $data_info->step($step);
    my $host = $data_info->host;

    my $sec  = $data_info->start_time_sec->epoch-$step;
    if (!$sec) {
        return;
    }
    open( my $in, $data_info->input_file ) || die "@!";
#   $data_info->skip_header( $in );
    while (my $line = <$in>) {
        $line=~s/(\r|\n)*//g;           # trim return code
        if ($line=~/",(\d.+)$/) {
            my @col = split(/,/, $line);
            $results{$sec} = $col[1];
        }
        $sec += $step;
    }
    close($in);
    my $output_file = "Siviewbusy.txt";
    $data_info->regist_metric($host, 'AIX', 'Siviewbusy', \@headers);
    $data_info->simple_report($output_file, \%results, \@headers);
    return 1;
}

1;
