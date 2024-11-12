package Getperf::Command::Site::Oracle::OraTbs;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use base qw(Getperf::Container);
use Getperf::Command::Master::Oracle;

sub new {bless{},+shift}

# TABLESPACE_NAME           |  total_mb|   used_mb|     usage|available_mb|max_total_mb| max_usage
# BFT_DCP_SUM_TRX_DAT_2305  |   2474004|   1641904|     66.37|      832100|     2474004|     66.37
# BFT_DCP_SUM_TRX_DAT_2306  |   2015000|   1464300|     72.67|      550700|     2015000|     72.67

# RTIME               |NAME     |TBS_SIZE(GB)|TBS_MAXSIZE(GB)|TBS_USEDSIZE(GB)|  USAGE
# 08/04/2023 10:00:23 |INDX     |       0.098|         32.000|           0.001|   1.00
# 08/04/2023 10:00:23 |PERFDATA |       0.488|          0.488|           0.151|  30.95
# 08/04/2023 10:00:23 |PMDAT01  |       4.199|         32.000|           3.922|  93.39

sub parse {
    my ($self, $data_info) = @_;

	my (%results, %zabbix_send_data);
	my $step = 600;
	# my @headers = qw/total_mb used_mb usage available_mb/;
	my @headers = qw/total_gb max_gb usage used_gb/;

	$data_info->step($step);
	$data_info->is_remote(1);
	my $instance = $data_info->file_suffix;
	my $sec  = $data_info->start_time_sec->epoch;
	if (!$sec) {
		return;
	}

	open( my $in, $data_info->input_file ) || die "@!";
	while (my $line = <$in>) {
        print $line;
		$line=~s/(\r|\n)*//g;			# trim return code
		if ($line=~/Date:(.*)/) {		# parse time: 16/05/23 14:56:52
			$sec = localtime(Time::Piece->strptime($1, '%y/%m/%d %H:%M:%S'))->epoch;
			next;
		}
        my @csv = split(/\s*\|\s*/, $line);
        my $colnum = scalar(@csv);

        # 最新版使用率のみ
		if ($colnum == 2) {
			my ($tbs, $usage) = @csv;
			next if (!defined($tbs) || $tbs eq 'TABLESPACE_NAME' || $tbs eq 'NAME');
			my @values = (0,0, $usage, 0);
			$results{$tbs}{$sec} = join(' ', @values);
        # temp 表領域を含む新版SQL結果の解析
        } elsif ($colnum == 7) {
            my ($tbs, $total_mb, $used_mb, $usage, $available_mb, 
                $max_total_mb, $ max_usage) = @csv;
            my $total_gb = $total_mb / 1024.0;
            my $max_gb   = $max_total_mb / 1024.0;
            my $used_gb  = $used_mb / 1024.0;
			my @values = ($total_gb, $used_gb, $usage, $max_gb);
			$results{$tbs}{$sec} = join(' ', @values);
        # 旧版SQL結果の解析
        } elsif ($colnum == 6) {
            my ($date, $tbs, @values) = @csv;
            next if (!defined($tbs) || $tbs eq 'TABLESPACE_NAME' || $tbs eq 'NAME');
            my ($total_gb, $max_gb, $used_gb, $usage) = @values;
            @values = ($total_gb, $used_gb, $usage, $max_gb);
            $results{$tbs}{$sec} = join(' ', @values);
        }
	}
	close($in);
	print Dumper \%results;
	for my $tbs(keys %results) {
		$data_info->regist_device($instance, 'Oracle', 'ora_tbs', $tbs, undef, \@headers);
		my $output = "Oracle/${instance}/device/ora_tbs__${tbs}.txt";	# Remote collection
		$data_info->simple_report($output, $results{$tbs}, \@headers);
	}

	my %stats = ();
	my @tablespaces = keys %results;
	$stats{ora_tbs} = \@tablespaces;
	my $info_file = "info/ora_tbs__${instance}";
	$data_info->regist_node($instance, 'Oracle', $info_file, \%stats);

	return 1;
}

1;
