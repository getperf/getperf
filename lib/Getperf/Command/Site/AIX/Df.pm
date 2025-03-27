package Getperf::Command::Site::AIX::Df;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use base qw(Getperf::Container);
use Getperf::Command::Master::AIX;

sub new {bless{},+shift}

# Filesystem    1024-blocks      Free %Used    Iused %Iused Mounted on
# /dev/hd4          1048576    951296   10%     5321     3% /

sub parse {
    my ($self, $data_info) = @_;

    my %results;
    my (@nodes, %nodes_key);
    my $row = 0;
    my $sec = $data_info->start_time_sec->epoch;
    if (!$sec) {
        return;
    }
    my @headers = qw/capacity free_space free_inode usage iusage/;

    $data_info->step(3600);
    my $host = $data_info->host;
    open( IN, $data_info->input_file ) || die "@!";
    while (my $line = <IN>) {
        $row++;
        next if ($row < 1);
        $line=~s/(\r|\n)*//g;	# trim return code
        # Reverse extract for root '/' partition doesn't have 1st column.
        my @cols = split(/\s+/, $line);
        next if (scalar(@cols) < 7);
        my ($filesystem, $iusage, $free_inode, $usage, $free_space, $capacity, $path) = reverse @cols;
        $usage =~s/\%//g;
        $iusage =~s/\%//g;
        next if ($usage eq '-');
        my $device = alias_df_k($host, $filesystem) || '';
        if ($device) {
            $data_info->regist_device($host, 'AIX', 'diskutil', $device, $path, \@headers);
             $results{$device}{$sec} = join(' ', ($capacity, $free_space, $free_inode, $usage, $iusage));
        }
    }
    close(IN);
    for my $device(keys %results) {
        my $output_file = "device/diskutil__${device}.txt";
        $data_info->simple_report($output_file, $results{$device}, \@headers);
    }
    return 1;
}

1;
