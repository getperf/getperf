package Getperf::Command::Site::Solaris::Uptime;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use base qw(Getperf::Container);

#  5:03pm  up 1589 day(s),  3:03,  1 user,  load average: 2.47, 3.77, 4.48

sub new {bless{},+shift}

sub parse {
    my ($self, $data_info) = @_;

    my %results;
    my $step = 30;
    my @headers = qw/load1m load5m load15m/;

    $data_info->step($step);
    my $host = $data_info->host;
    my $sec  = $data_info->start_time_sec->epoch;
    if (!$sec) {
        return;
    }
    open( IN, $data_info->input_file ) || die "@!";
    while (my $line = <IN>) {
        next if ($line=~/^\s*[a-z]/);   # skip header
        $line=~s/(\r|\n)*//g;           # trim return code
        if ($line=~/load average: (\d.+)$/) {
            $line=$1 ;
            $line=~s/,/ /g;
            $results{$sec} = $line;
            $sec += $step;
        }
    }
    close(IN);
    $data_info->regist_metric($host, 'Solaris', 'loadavg', \@headers);
    $data_info->simple_report('loadavg.txt', \%results, \@headers);

    return 1;
}

1;
