package Getperf::Command::Site::Db2::Db2SqlRank;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use Path::Class;
use base qw(Getperf::Container);
use Getperf::Command::Master::Db2;
use Getperf::Command::Site::Db2::Db2SqlRankGraph;
use Storable;
use YAML::Tiny;

# Db2 SQL ランク採取結果を集計して、RRDファイルにロードする

sub new {bless{},+shift}

# 前回実行した SQL テキスト解析結果保存用のファイルパス取得
sub db2_sql_rank_datastore {
	my ($data_info, $host) = @_;
	my $storage_dir = $data_info->absolute_storage_dir;
	return $storage_dir . sprintf('/db2_sql_rank_%s.dat', $host);
}

# 前回実行した SQL テキスト解析結果保存用のファイルパス取得
=pod
# SQLランキング集計履歴表の登録で除外する SQL の STMTID リスト
stmtid_white_lists:
 - 7258484911038481250
 - -8618034861244996018

 ～

 - -8618034861244996019

select * from db2_sql_rank where stmtid = -8618034861244996018;

=cut


sub get_stmtid_whitelists {
	my $file = file($ENV{"HOME"}, 'share', 'stmtid.yml')->stringify;
	if (!-f $file) {
		print "not found $file. skip.\n";
		return;
	}
	my $messages;
	eval {
		$messages = YAML::Tiny->read($file);
	};
	if ($@) {
		print "$@ $file. skip.\n";
		return;
	}
	my $yaml = $messages->[0];
	my $stmtid_white_lists;
	for my $id (@{$yaml->{stmtid_white_lists}}) {
		$stmtid_white_lists->{$id} = 1;
	}
	return $stmtid_white_lists;
}

# SQL 解析結果から指定したキー値を取得する。キー値がない場合は 0 を返す
sub retrieve_value {
	my ($result, $member, $group_key, $stmtid, $metric) = @_;
	return $result->{$member}{$metric}{$group_key}{$stmtid} || 0;
}

sub regist_hist_daily {
    my ($data_info, $member, $stmtid, $metric, $sec, $value) =@_;
    my $sec_daily = int ($sec / (24*3600)) * 24 * 3600;
    # print "SEC2:$sec_daily\n";
    my $query = "select `max_value`, `sum_value` from `db2_sql_rank_daily` ". 
                " where `clock` = $sec_daily ".
                " and `member` = '$member' ".
                " and `stmtid` = $stmtid ".
                " and `metric` = '$metric'";
    # print "query:$query\n";
    my $rows = $data_info->cacti_db_query($query);
    # print Dumper $rows;
    my ($max_value, $sum_value) = (0, 0);
    if (@{$rows}) {
        my ($tmp_max_value, $tmp_sum_value) = @{$rows->[0]};
        $max_value = $value if ($tmp_max_value > $value);
        $sum_value = $tmp_sum_value + $value;
        # print "ROW : $max_value, $sum_value\n";
    }
    my $dml2 = "REPLACE INTO `db2_sql_rank_daily` " .
                "( `stmtid`, `member`, `metric`, `clock`, `max_value`, `sum_value` ) " . 
                "VALUES " .
                "( $stmtid, '$member', '$metric', $sec_daily, $max_value, $sum_value)";
    # print "DML2:$dml2\n";
    my $res2 = $data_info->cacti_db_dml($dml2);
    # print "DML2:$dml2,RES:$res2\n";
}

sub regist_hist {
	my ($data_info, $sql_header, $member, $stmtid, $group_key, $metric, $sec, $value) =@_;
	my $group_key_str = $group_key;
	$group_key_str =~s/\|/','/g;
	$group_key_str = "'$group_key_str'";

	my $dml = qq/$sql_header VALUES ( $stmtid, '$member', $group_key_str,
		'$metric', '$sec', $value )/;
	my $res = $data_info->cacti_db_dml($dml);
	# print "DML:$dml,RES:$res\n";
	if ($group_key_str=~/DML/ && $metric=~/^(TOTAL_CPU_TIME|STMT_EXEC_TIME)/) {
    	# print "!!!!DML:$dml,RES:$res,METRIC:${metric},GROUP_KEY:${group_key_str}\n";
        regist_hist_daily($data_info, $member, $stmtid, $metric, $sec, $value);
    }
}

# メイン処理。SQL ランク採取結果を集計して、RRDファイルにロードする
sub parse {
    my ($self, $data_info) = @_;

	# RRDファイル更新間隔パラメータ[秒]
	my $step = 600;
	$data_info->step($step);

	# SQLランクヘッダーリスト、マスター定義ファイル Db2.pm から読み込み
	# my @headers = sql_rank_headers();
	# my @timestamp_headers = sql_rank_timestamps();

	# リモートからの採取データの集計モードに変更
	$data_info->is_remote(1);

	# SQL テキストパス名のサフィックスからDB名を取得。
	# サフィックスがない場合は替りに採取ホスト名にする。
	my $host = $data_info->file_suffix || $data_info->host;

	# SQL 実行タイムスタンプを取得
	my $sec  = $data_info->start_time_sec->epoch;

	# SQL テキストの解析結果の宣言。member, stmtid, metric をキーとする
	my $results;

	# SQL テキスト解析結果のキー変数(複合キー)を宣言
	# my ($stmtid, $member, $stmt_type_id, $package_schema,
	#     $package_name, $effective_isolation, $planid, $current_time);
	my ($stmtid, $member);

	my $timestamp_keys = db2_timestamp_column_keys();
	my $sql_rank_key_names = sql_rank_keys();
	my $sql_rank_keys;
# print Dumper $sql_rank_key_names; exit;
	# 採取 SQL テキストの解析。以下形式のテキストから値を抽出する
	open( my $in, $data_info->input_file ) || die "@!";
	while (my $line = <$in>) {
		# print $line;
		$line=~s/(\r|\n)*//g;			# 改行の削除
		if ($line=~/^([A-Z][A-Z].+?)(\s+)(.+)$/) {
			my ($metric, $value) = ($1, $3);

			# 時刻カラムは UNIX タイムスタンプに変換
			if (defined($timestamp_keys->{$metric})) {
				$value = Time::Piece->strptime($value, '%Y-%m-%d %H:%M:%S')->localtime->epoch;
			}
			# キー項目の MEMBER と STMTID をセット
			if ($metric eq 'MEMBER') {
				$member = sprintf("%s-%s", $host, $value);
			} elsif ($metric eq 'STMTID') {
				$stmtid = $value;
			# グループキー項目をセット
			} elsif (defined(my $seq = $sql_rank_key_names->{$metric})) {
				$sql_rank_keys->{$seq} = $value;

			# MEMBER, STMTID, グループキー項目をキーに値をセット
			} else {
				my @key_values;
				for my $sql_rank_key(sort keys %$sql_rank_keys) {
					my $key_value = $sql_rank_keys->{$sql_rank_key};
					push @key_values, $key_value;
				}
				my $group_key = join('|', @key_values);
				# print Dumper $group_key;
				$results->{$member}{$metric}{$group_key}{$stmtid} = $value;
			}
		}
	}
	close($in);

	# SQL 解析結果ファイルのパス設定
	my $datastore_db2_sql_rank = db2_sql_rank_datastore($data_info, $host);

	# 前回実行した、SQLテキスト解析結果の読み込み
	my $last_results;
	if (-f $datastore_db2_sql_rank) {
		$last_results = retrieve( $datastore_db2_sql_rank ) ;
	}
	# SQLテキスト解析結果の保存
	if ($results) {
		store $results, $datastore_db2_sql_rank;
	}
	# 前回実行の　SQL　テキスト解析結果ファイルがない場合は終了する
	return if (!$last_results);

	# 前回実行の差分値を抽出して、ランキングを集計
	# MEMBER, METRIC をキーに指定した上位 n までのSTMTID を SQL ランク表
	# に登録する
	my $rank_thresholds = sql_rank_thresholds();

	# my $stmtid_whitelists = {
	# 	'-8618034861244996019' => 1,
	# };
	my $stmtid_whitelists = get_stmtid_whitelists();
	# print Dumper $stmtid_whitelists; exit;

	my $filterd_results;
	my $filterd_stmtids;
	my $member_results;
	for my $member(keys %{$results}) {
		# print "MEMBER:$member\n";
		for my $metric(keys %{$results->{$member}}) {
			my %values = ();
			for my $group_key(keys %{$results->{$member}{$metric}}) {
				for my $stmtid(keys %{$results->{$member}{$metric}{$group_key}}) {
					print "STMTID:$stmtid\n";
					if (defined($stmtid_whitelists->{$stmtid})) {
						print "HIT !!!!\n";
						$filterd_stmtids->{$member}{$stmtid} = 1;
					}
					my $value = $results->{$member}{$metric}{$group_key}{$stmtid};
					my $last_value = retrieve_value($last_results, $member,
													$group_key, $stmtid, $metric);

					# 時刻列でないメトリックは差分に変換
					if (!defined($timestamp_keys->{$metric})) {
						$value = $value - $last_value;
					}
					# print "METRIC:$member,$metric,$group_key,$stmtid=$value\n";
					if (defined($values{$stmtid})) {
						$values{$stmtid} += $value;
					} else {
						$values{$stmtid} = $value;
					}
					$filterd_results->{$member}{$stmtid}{$group_key}{$metric} = $value;
					# 集計前処理のサマリ結果セット
					if (defined($rank_thresholds->{$metric})) {
						if (defined($member_results->{$member}{$metric})) {
							$member_results->{$member}{$metric} += $value;
						} else {
							$member_results->{$member}{$metric} = $value;
						}
					}
				}
			}
			my $th = $rank_thresholds->{$metric};
			if ($th) {
				for my $stmtid(sort {$values{$b} <=> $values{$a}} keys %values) {
					$filterd_stmtids->{$member}{$stmtid} = 1;
					my $value = $values{$stmtid};
					$th --;
					last if ($th < 0);
					# print "STMTID:$member,$metric,$stmtid,$value\n";
				}
			}
		}
	}
	for my $member_result(keys %{$member_results}) {
		for my $metric(sort keys %{$member_results->{$member_result}}) {
			my $value = $member_results->{$member_result}{$metric};
			print "Preoperation summary: $member_result, $metric, $value\n";
		}
	}
	# MySQL SQL ランク履歴表に集計値を登録
	my $inserted = 0;
	my $insert_sql_header = db2_sql_rank_hist_header();

	my $reports;
	for my $member(keys %{$filterd_stmtids}) {
		for my $stmtid(keys %{$filterd_stmtids->{$member}}) {
			my $results = $filterd_results->{$member}{$stmtid};
			for my $group_key(keys %{$results}) {
				for my $metric(keys %{$results->{$group_key}}) {
					my $value = $results->{$group_key}{$metric};
					if ($value > 0) {
						regist_hist($data_info, $insert_sql_header,
							$member, $stmtid, $group_key, $metric, 
							$sec, $value);
						$inserted ++;
						$reports->{'inserted'} ++;
					} else {
						$reports->{'skip_zero_value'} ++;
					}
					# print "REG: $member,$stmtid,$metric,$value\n";
				}
			}
		}
	}
	print "$inserted rows inserted.\n";

	# SQL ランク表の検索。デバッグ用
	my $test = Getperf::Command::Site::Db2::Db2SqlRankGraph->new;
	$test->parse($data_info);

	# ゼロ値スキップカウンターレポート
	my $report_file = file($data_info->absolute_summary_dir, "report2__${host}.txt");
	print "REPORT: $report_file\n";
	my $writer = $report_file->open('w') or die $!;
	for my $key(sort keys %{$reports}) {
		my $value = $reports->{$key};
		$writer->print("$key,$value\n");
	}
	$writer->close;

	return 1;
}

1;
