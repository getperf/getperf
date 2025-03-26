package Getperf::Command::Site::Db2::Db2ObjNum;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use base qw(Getperf::Container);
use Getperf::Command::Master::Db2;

sub new {bless{},+shift}

sub parse {
    my ($self, $data_info) = @_;

    my $stats;
    my $results;
    my $step = 600;
    my @headers = qw/count/;

    $data_info->step($step);
    $data_info->is_remote(1);
    my $db  = $data_info->file_suffix;
    my $sec = $data_info->start_time_sec->epoch;

    open( my $in, $data_info->input_file ) || die "@!";
    while (my $line = <$in>) {
        $line=~s/(\r|\n)*//g;           # trim return code
        # INDEX_OBJ_NUM  18260
        next if ($line!~/^INDEX_OBJ_NUM\s+(\d+)/);
        my $count = $1;
        $results->{$sec} = $count;
		$stats->{'count'}{$sec} = $count;
    }
    close($in);
    $data_info->regist_metric($db, 'Db2', 'db2_obj_num', \@headers);
    my $output = "Db2/${db}/db2_obj_num.txt";
    $data_info->simple_report($output, $results, \@headers);

    my $options = {'enable_first_load' => 1, 'use_absolute_value' => 1};
	db2_update_stats($data_info, $db, 'obj_num', $stats, $options);

    return 1;
}

1;
