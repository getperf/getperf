package Getperf::Command::Master::Db2;
use strict;
use warnings;
use Exporter 'import';

# Db2 SQL ランク集計用マスター

our @EXPORT = qw/alias sql_rank_headers sql_rank_keys sql_rank_thresholds sql_rank_headers_alias sql_rank_filter/;

our $db = {
	_node_dir => undef,
};

# SQL ランクフィルター閾値
# 各メトリックで指定した閾値以下の場合は除外する
# my $sql_rank_thresholds = {
# 	'NUM_EXEC_WITH_METRICS' => 100,
# 	'TOTAL_CPU_TIME' => 100,
# };

sub sql_rank_thresholds {
	return {
		'NUM_EXEC_WITH_METRICS' => 2,
		'TOTAL_CPU_TIME' => 2,
	};
}

# SQL ランクグルーピングキー項目
# SQLランク採取SQLで GROUP BY している項目リスト
sub sql_rank_keys{
	return {
		'STMT_TYPE_ID' => 1,
		'PACKAGE_SCHEMA' => 2,
		'PACKAGE_NAME' => 3,
		'EFFECTIVE_ISOLATION' => 4,
		'PLANID' => 5,
		'CURRENT_TIME' => 6,
	};
}

sql_rank_keys
	};
}
# SQL ランクヘッダーリスト。履歴表に蓄積するキー項目
# 採取SQLのカラム名と同じにする
sub sql_rank_headers {
	return qw/STMTID MEMBER/;
}

# SQL ランクタイムスタンプヘッダーリスト。履歴表に蓄積するタイムスタンプ項目
# 採取SQLのカラム名と同じにする。
sub sql_rank_timestamps {
	return qw/LAST_METRICS_UPDATE/;
}

# SQL ランクヘッダーリストエイリアス
# RRDtool 登録用の別名リスト。RRDtoolの制約でカラム名は19文字以内にする
sub sql_rank_headers_alias {
	return qw/EXEC_TIME CPU_TIME EXEC/;
}

# SQL ランク閾値フィルター
# 各SQLランクメトリックで指定した閾値未満の場合は0、閾値以上の場合は1を返す
sub sql_rank_filter {
	my ($metric, $value) = @_;
	if (defined(my $th = $sql_rank_thresholds->{$metric})) {
		if ($value < $th) {
			return 0;
		}
	}
	return 1;
}

sub new {bless{},+shift}

1;
