package Getperf::Command::Site::Oracle::SgaUtil;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use base qw(Getperf::Container);

sub new {bless{},+shift}

# Date:16/06/09 00:05:00
# DEFAULT buffer cache,16640
# KEEP buffer cache,10240
# java pool,1536
# keep_use_size,18646
# large pool,1792
# sga_max_size,98560
# shared pool,18176
# streams pool,512


sub parse {
    my ($self, $data_info) = @_;

    my %results;
    my $step = 600;
    my @headers = qw/keep_buffer default_buffer shared_pool large_pool java_pool keep_use sga_max/;
    my %labels = (
        'DEFAULT buffer cache' => 'default_buffer',
        'KEEP buffer cache'    => 'keep_buffer',
        'java pool'            => 'java_pool',
        'keep_use_size'        => 'keep_use',
        'large pool'           => 'large_pool',
        'sga_max_size'         => 'sga_max',
        'shared pool'          => 'shared_pool',
    );

    $data_info->is_remote(1);
    $data_info->step($step);
    my $host = $data_info->file_suffix;
    # $host=~s/^.+_//g;
    my $sec  = $data_info->start_time_sec->epoch;
    open( IN, $data_info->input_file ) || die "@!";
    while (my $line = <IN>) {
        print $line;
        next if ($line=~/^Date:/);  # skip header
        $line=~s/(\r|\n)*//g;           # trim return code
        my ($memory_area, $mbyte) = split(/\s*\|\s*/, $line);
        next if !defined($memory_area);
        if (defined(my $label = $labels{ $memory_area })) {
            $results{$sec}{$label} += $mbyte;
        }
    }
    close(IN);
    for my $header(@headers) {
        if (!defined($results{$header})) {
            $results{$sec}{$header} = 0;
        }
    }
    # for my $memory_area(keys %results) {
        my $output = "Oracle/${host}/ora_mem_sga.txt";
        # my $data   = $results{$memory_area};
        $data_info->regist_metric($host, 'Oracle', "ora_mem_sga", \@headers);
        $data_info->pivot_report($output, \%results, \@headers);
    # }
    return 1;
}

1;
