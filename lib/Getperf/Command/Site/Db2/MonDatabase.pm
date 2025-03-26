package Getperf::Command::Site::Db2::MonDatabase;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use base qw(Getperf::Container);
use Getperf::Command::Master::Db2;
use Storable;

sub new {bless{},+shift}

my %metrics = (
'LOCK_ESCALS'          ,'LOCK_ESCALS',
'LOCK_TIMEOUTS'        ,'LOCK_TIMEOUTS',
'LOCK_WAIT_TIME'       ,'LOCK_WAIT_TM',
'LOCK_WAITS'           ,'LOCK_WAITS',
'LOG_BUFFER_WAIT_TIME' ,'LOG_BUFFER_WAIT_TM',
'LOG_DISK_WAIT_TIME'   ,'LOG_DISK_WAIT_TM',
'LOG_DISK_WAITS_TOTAL' ,'LOG_DISK_WAITS',
'TOTAL_CPU_TIME'       ,'TOTAL_CPU_TM',
'TOTAL_WAIT_TIME'      ,'TOTAL_WAIT_TM',
'CF_WAITS'             ,'CF_WAITS',
'CF_WAIT_TIME'         ,'CF_WAIT_TM',
'TOTAL_EXTENDED_LATCH_WAIT_TIME' ,'EXT_LATCH_WAIT_TM',
'TOTAL_EXTENDED_LATCH_WAITS'     ,'EXT_LATCH_WAITS',
'TOTAL_SYNC_RUNSTATS_TIME'       ,'RUNSTATS_TM',
'TOTAL_SYNC_RUNSTATS_PROC_TIME'  ,'RUNSTATS_PROC_TM',
'TOTAL_SYNC_RUNSTATS'            ,'RUNSTATS',
);

# 前回実行した SQL テキスト解析結果保存用のファイルパス取得
sub db2_mon_database_datastore {
	my ($data_info, $host) = @_;
	my $storage_dir = $data_info->absolute_storage_dir;
	return $storage_dir . sprintf('/db2_mon_database_%s.dat', $host);
}

# SQL 解析結果から指定したキー値を取得する。キー値がない場合は 0 を返す
sub retrieve_value {
	my ($result, $member, $group_key, $metric) = @_;
	return $result->{$member}{$group_key}{$metric} || 0;
}

sub regist_hist {
	my ($data_info, $table_name, $member, $group_key, $metric, $sec, $value) =@_;
	my $group_key_str = $group_key;
	$group_key_str =~s/\|/','/g;

	my $dml = qq/REPLACE INTO $table_name VALUES ( '$member', '$group_key_str',
		'$metric', '$sec', $value )/;
	my $res = $data_info->cacti_db_dml($dml);
	# print "DML:$dml,RES:$res\n";
}


sub parse {
    my ($self, $data_info) = @_;

	my %results;
	my $step = 600;
	my %header_metrics = reverse %metrics;
	my @headers = keys %header_metrics;

	$data_info->step($step);
	$data_info->is_remote(1);
	my $host = $data_info->file_suffix || $data_info->host;

	my $sec  = $data_info->start_time_sec->epoch;
	if (!$sec) {
		return;
	}
	my $stats;
	open( my $in, $data_info->input_file ) || die "@!";
	while (my $line = <$in>) {
		$line=~s/(\r|\n)*//g;			# trim return code
		next if ($line!~/^([A-Z].+?)\s+(.+?)$/);
		my ($metric, $value) = ($1, $2);

		$value = 0 if ($value eq 'null');
		if ($value!~/^\d+$/) {
			next;
		}
		$stats->{$metric} = $value;
		my $header = $metrics{$metric};
		if ($header) {
			my $header2 = $header;
			$header2=~s/:.+//g;
			print "($metric, $header2, $value)\n";
			$results{$sec}{$header2} = $value;
		}
	}
	close($in);
	$data_info->regist_metric($host, 'Db2', 'mon_database', \@headers);
	my $output = "Db2/${host}/mon_database.txt";	# Remote collection
	$data_info->pivot_report($output, \%results, \@headers);

	# SQL 解析結果ファイルのパス設定
	my $db2_mon_database = db2_mon_database_datastore($data_info, $host);

	# 前回実行した、SQLテキスト解析結果の読み込み
	my $last_stats;
	if (-f $db2_mon_database) {
		$last_stats = retrieve( $db2_mon_database ) ;
	}
	if ($stats) {
		store $stats, $db2_mon_database;
	}
	print Dumper $last_stats;

	print Dumper $stats;
	for my $metric(keys \%{$stats}) {
		my $value = $stats->{$metric};
		regist_hist($data_info, 'db2_stat', $host, 'mon_database', $metric, $sec, $value);
		# print "$host, db2_stat, $metric, $sec, $value\n";
	}
	return 1;
}

1;
