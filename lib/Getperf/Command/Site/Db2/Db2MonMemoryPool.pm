package Getperf::Command::Site::Db2::Db2MonMemoryPool;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use base qw(Getperf::Container);
use Getperf::Command::Master::Db2;

my %metrics = (
# Overall physical and logical numbers
'MEMORY_POOL_USED', 'MEMORY_POOL_USED',
);

sub new {bless{},+shift}
sub parse {
    my ($self, $data_info) = @_;
    my $results;
    my $step = 600;
    $data_info->step($step);
    $data_info->is_remote(1);
    my $host_prefix = $data_info->file_suffix || $data_info->host;
    $host_prefix = lc $host_prefix;
    my $member = 0;
    my $host = sprintf("%s%02d", $host_prefix, $member + 1);
    my $sec  = $data_info->start_time_sec->epoch;

    open( my $in, $data_info->input_file ) || die "@!";
    my $device = 'Unkown';

    my $stats;
    while (my $line = <$in>) {
        # print "$host : $line";
        $line=~s/(\r|\n)*//g;           # trim return code
        next if ($line!~/^([A-Z][A-Z].+?)\s+(.+?)$/);
        my ($metric, $value) = ($1, $2);
        if ($metric eq 'MEMBER') {
            $host = sprintf("%s%02d", $host_prefix, $value + 1);
        } elsif ($metric eq 'MEMORY_SET_TYPE') {
            $device = $value;
        } elsif ($metric eq 'MEMORY_POOL_TYPE') {
            $device .= '_' . $value;
        } elsif ($metric eq 'MEMORY_POOL_USED') {
            $stats->{$host}->{"$metric|$device"}{$sec} = $value;
            # メモリセットタイプは 30 種類程あるので、集約して必要な項目のみに変換する処理を検討
            if ($device !~/(FMP_MISC|DATABASE_LOCK_MGR|DATABASE_PACKAGE_CACHE|DATABASE_DATABASE)/) {
 # print "NO HIT ${device}\n";
                $device = 'ETC';
            }
            $results->{$host}{$device}{$sec}{$metric} += $value;
        }
    }
    close($in);
    for my $host(keys %{$stats}) {
        my $options = {'enable_first_load' => 1, 'use_absolute_value' => 1};
        db2_update_stats($data_info, $host, 'mon_get_memory_pool', 
            $stats->{$host}, $options);
    }
    my @headers = qw/MEMORY_POOL_USED/;
    for my $host(keys %{$results}) {
        my $host_results = $results->{$host};
        for my $device(keys %{$results->{$host}}) {
            my $device_results = $results->{$host}{$device};
            print "regist metric $host,$device\n";
            $data_info->regist_device($host, 'Db2',
                'db2_mon_memory_pool', $device, undef, \@headers);
            my $output = "Db2/${host}/device/db2_mon_memory_pool__${device}.txt";
            $data_info->pivot_report($output, $device_results, \@headers);
            if ($device eq 'FMP_MISC') {
                print "FPM MISC Regist\n";
                $data_info->regist_metric($host, 'Db2', 'db2_mon_memory_pool_fpm_misc', \@headers);
                my $output = "Db2/${host}/db2_mon_memory_pool_fpm_misc.txt";
                $data_info->pivot_report($output, $device_results, \@headers);
            }
        }
    }

    return 1;
}

1;
