package Getperf::Command::Site::Db2::Db2SqlText;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use base qw(Getperf::Container);
use Getperf::Command::Master::Db2;

sub new {bless{},+shift}

sub parse {
    my ($self, $data_info) = @_;

	# RRDファイル更新間隔パラメータ[秒]
	my %results;
	my $step = 60;

	$data_info->step($step);
	# SQL テキストパス名のサフィックスからDB名を取得。
	# サフィックスがない場合は替りに採取ホスト名にする。
	my $host = $data_info->file_suffix || $data_info->host;

	my $sec  = $data_info->start_time_sec->epoch;
	if (!$sec) {
		return;
	}
	# SQL テキストの解析結果の宣言。stmtid, metric をキーとする
	my $results;
	my ($stmtid, $last_update, $sql_text);
	open( my $in, $data_info->input_file ) || die "@!";
	while (my $line = <$in>) {
		# print "LINE:$line";
		$line=~s/(\r|\n)*//g;			# 改行の削除

		if ($line=~/^(STMTID|LAST_METRICS_UPDATE|STMT_TEXT)(\s+)(.+)$/) {
			my ($metric, $value) = ($1, $3);
			if ($metric eq 'STMTID') {
				if (defined($stmtid)) {
					# print "EOL\n";
					$results->{$stmtid} = [$host, $stmtid, $last_update, $sql_text];
				}
				$stmtid = $value;
			} elsif ($metric eq 'LAST_METRICS_UPDATE') {
				$last_update = Time::Piece->strptime($value, '%Y-%m-%d %H:%M:%S')->localtime->epoch;
			} elsif ($metric eq 'STMT_TEXT') {
				$sql_text = $value;
			}
			# print "$metric, $value\n";
		} elsif ($line eq '') {
			# print "EOL\n";
		} else {
			$sql_text .= $line . "\n";
		}
	}
	close($in);

	my $dml = qq/
		REPLACE INTO `db2_sql_text` 
			( `db_name`, `stmtid`, `last_update`, `sql_text`) 
		VALUES 
			( ?, ?, ?, ?)/;

	for my $stmtid(keys %{$results}) {
		my @values = @{$results->{$stmtid}};
		my $res = $data_info->cacti_db_dml($dml, {},
			$values[0], $values[1], $values[2], $values[3]);
		print "regist $values[0],$values[1],result: $res\n";
	}

	# 過去の更新されていない SQL テキストを削除する
	my $purge_sec = time() - 180*24*3600;
	print "$purge_sec\n";
	my $purge_dml = qq/
		DELETE FROM `db2_sql_text` WHERE `last_update` < $purge_sec
	/;
	$data_info->cacti_db_dml($purge_dml);

	return 1;
}

1;
