package Getperf::Command::Master::Db2;
use strict;
use warnings;
use Data::Dumper;
use Getperf::Command::Master::Db2StatRegister;
use Exporter 'import';

# Db2 SQL ランク集計用マスター

# our @EXPORT = qw/alias sql_rank_headers sql_rank_keys sql_rank_thresholds 
# 	sql_rank_key_names sql_rank_headers_alias sql_rank_filter
# 	db2_sql_rank_hist_header
# 	db2_timestamp_column_keys/;

our @EXPORT = qw/
	alias
	sql_rank_thresholds
	sql_rank_keys
	db2_mon_get_filter_keywords
	db2_sql_rank_hist_header
	db2_timestamp_column_keys
	db2_update_stats/;

our $db = {
	_node_dir => undef,
};

our $mon_get_filter_keywords = {
	'mon_get_table' => {
		"SYSPLAN"              => 1,
		"SYSWORKACTIONS"       => 1,
		"SYSCONTEXTATTRIBUTES" => 1,
		"SYSVERSIONS"          => 1,
		"SYSSURROGATEAUTHIDS"  => 1,	
	},
};

sub db2_mon_get_filter_keywords {
	my ($mon_get_func) = @_;
	return $mon_get_filter_keywords->{$mon_get_func};
}

# SQL ランクフィルター閾値
# 各メトリックで指定した閾値以下の場合は除外する
sub sql_rank_thresholds {
	return {
	'NUM_EXEC_WITH_METRICS' => 100,
	'STMT_EXEC_TIME'      => 100,
	'TOTAL_ACT_WAIT_TIME' => 100,
	'LOCK_WAIT_TIME'      => 100,
	'LOCK_WAITS'          => 100,
	'DIRECT_READ_TIME'    => 100,
	'DIRECT_WRITE_TIME'   => 100,
	'ROWS_MODIFIED'       => 100,
	'ROWS_READ'           => 100,
	'FED_WAIT_TIME'       => 100,
	};
}

# SQL ランクグルーピングキー項目
# SQLランク採取SQLで GROUP BY している項目リスト
my %key_columns = (
	'STMT_TYPE_ID'        => 1,
	'PACKAGE_SCHEMA'      => 2,
	'PACKAGE_NAME'        => 3,
	'EFFECTIVE_ISOLATION' => 4,
	'PLANID'              => 5,
);

# 採取 SQL の時刻列のキー項目
# SQLランク採取SQLでto_char(column,'YYYY-MM-DD HH24:MI:SS') で
# 時刻文字列に変換している項目のリスト
my %timestamp_columns = (
	'LAST_UPDATE'  => 1,
	'INSERT_TIMESTAMP' => 2,
);

# SQL ランクグルーピングキー項目を返す
sub sql_rank_keys{
	return \%key_columns;
}

# SQL ランク表登録 SQL のヘッダー部を返す
sub db2_sql_rank_hist_header {
	my @columns = sort { $key_columns{$a} <=> $key_columns{$b} } 
				keys %key_columns;
	my $sql_part = join('`, `', @columns);
	$sql_part = "`$sql_part`";
	$sql_part = lc($sql_part);
	# print Dumper \$columns_str;
	return qq/
	REPLACE INTO `db2_sql_rank` 
		( `stmtid`, `member`, 
		$sql_part, 
		`metric`, `clock`, `value` ) /;
}

# 採取 SQL の時刻列のキーを返す
sub db2_timestamp_column_keys {
	return \%timestamp_columns;
}

sub sql_rank_key_names {
	my $sql_rank_keys = sql_rank_keys();
	my @names = keys %{$sql_rank_keys};
	return \@names;
	# for my $sql_rank_key(sort {$sql_rank_keys{$b} <=> $sql_rank_keys{$a}} keys %$sql_rank_keys) {
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

sub db2_update_stats {
	my ($data_info, $host, $schema, $stats, $options) = @_;
	return Getperf::Command::Master::Db2StatRegister::db2_update_stats($data_info, $host, $schema, $stats, $options);
}

sub new {bless{},+shift}

1;
