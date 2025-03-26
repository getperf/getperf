package Getperf::Command::Master::Db2StatRegister;
use strict;
use warnings;
use Scalar::Util qw(looks_like_number);
use DateTime;
use Data::Dumper;
use Storable;
use Exporter 'import';

# MySQL テーブルの有無チェック
sub check_db2_stat_schema {
	my ($data_info, $schema) = @_;
	my $rows = $data_info->cacti_db_query("SHOW TABLES LIKE '$schema'");
    return (@{$rows}) ? 1: 0;
}

# パーティション作成SQL 取得
sub get_alter_partition_sql {
    my ($schema) = @_;
    my $dt = DateTime->now(locale => 'ja' , time_zone => 'local');
    my $partition_name = 'p' . $dt->ymd('_');
    my $partition_range = $dt->add(days => 1)->ymd('-');
    my $sql = qq/
    ALTER TABLE $schema PARTITION BY RANGE ( clock)
        (PARTITION ${partition_name} VALUES LESS THAN (UNIX_TIMESTAMP("${partition_range} 00:00:00")) ENGINE = InnoDB);
    /;
}

# MySQL 統計履歴表の作成
sub prepare_db2_stat_schema {
	my ($data_info, $schema) = @_;
    if (my $table_exist = check_db2_stat_schema($data_info, $schema)) {
        print "table_exist:$table_exist\n";
        return;
    }
    my @create_stat_table_sqls;
    push @create_stat_table_sqls, qq/
        DROP TABLE IF EXISTS `$schema`;
    /;
    push @create_stat_table_sqls, qq/
        CREATE TABLE `$schema` (
            `node`      varchar(100) NOT NULL,
            `device`    varchar(100)     DEFAULT '',
            `metric`    varchar(100)     DEFAULT ''       NOT NULL,
            `clock`     integer          DEFAULT '0'      NOT NULL,
            `num_value` DOUBLE PRECISION DEFAULT '0.0000' NOT NULL,
            `str_value` varchar(100)
        ) ENGINE=InnoDB;
    /;
    push @create_stat_table_sqls, qq/
        alter table `$schema` add PRIMARY KEY(
            `clock`, `node`, `device`, `metric`
        );
    /; 
    push @create_stat_table_sqls, get_alter_partition_sql($schema);

    for my $create_stat_table_sql(@create_stat_table_sqls) {
    	$data_info->cacti_db_dml($create_stat_table_sql);
    }
}

# MySQL 統計履歴表に値登録
sub update_stat {
    my ($data_info, $schema, $node, $column_keys, $clock, $num_value, $str_value) = @_;
	my $dml = qq/
		REPLACE INTO `${schema}` 
			( `node`, `device`, `metric`, `clock`, `num_value`, `str_value`) 
		VALUES 
			( ?, ?, ?, ?, ?, ?)/;

    # カラムキーの解析、文字列を "{メトリック名}|{デバイス名}" に分解する
    my $device = '';
    my $metric = $column_keys;
    if ($metric=~/^(.+?)\|(.+)$/) {
        ($metric, $device) = ($1, $2);
    }
    my $res = $data_info->cacti_db_dml($dml, {}, $node, $device, $metric, 
                                       $clock, $num_value, $str_value);
    print "UPD:$res, $node, $metric, $device, $clock, $num_value, $str_value\n";
}

# 前回登録値の保存ファイルパス "storage/stat__{スキーマ}_{ノード}.dat" 取得
sub get_datastore {
    my ($data_info, $node, $schema) = @_;
	my $storage_dir = $data_info->absolute_storage_dir;
	return "${storage_dir}/stat__${schema}_${node}.dat";
}

# 前回登録した値を取得。値、最終登録時刻を返す。
sub get_last_value {
    my ($results, $column_keys) = @_;
    my ($values, $last_clock);
    for my $clock (sort keys %{$results->{$column_keys}}) {
        $values = $results->{$column_keys}{$clock};
        $last_clock = $clock;
    }
    return ($values, $last_clock);
}

# 統計値登録。メイン処理
sub db2_update_stats {
	my ($data_info, $node, $schema, $results, $options) = @_;

    # MySQL 履歴表初期化
    prepare_db2_stat_schema($data_info, $schema);

    # 前回実行のDB2統計値取得
	my $last_results;
    my $datastore = get_datastore($data_info, $node, $schema);
	if (-f $datastore) {
		$last_results = retrieve( $datastore ) ;
	}

	# DB統計の保存
	if ($results) {
		store $results, $datastore;
	}

	# 前回実行のDB統計結果ファイルがない場合は終了する
	return if (!($options->{enable_first_load}) && !$last_results);

    # カラムキー順に統計値登録
    my $use_zero_value_filter = 1;
    # print Dumper $results;
    for my $column_keys (keys %{$results}) {
        for my $clock(keys %{$results->{$column_keys}}) {
            my $value = $results->{$column_keys}{$clock};

            # 文字列の null undef の場合はスキップ
            if ($value eq 'null') {
                next;
            }

            my ($last_value, $last_clock) = get_last_value($last_results, $column_keys);
            # print "LAST:($last_value, $last_clock)\n";
            # 前回登録がない初回で、enable_first_load オプションの場合 
            if (!$last_clock && $options->{enable_first_load}) {
                if (looks_like_number($value)) {
                    update_stat($data_info, $schema, $node, $column_keys, 
                                $clock, $value, '');
                } else {
                    update_stat($data_info, $schema, $node, $column_keys, 
                                $clock, 0, $value);
                }
                next;
            }

            # 前回登録時刻が現時刻以上の場合は登録しない
            next if ($use_zero_value_filter && (!$last_clock || $last_clock >= $clock));
            my $store_num_value = 0;
            my $store_str_value = '';

            # 数値の場合は、前回登録値との差分を計算し、0より大きい場合はデータ登録
            if (looks_like_number($value)) {
                if (!$use_zero_value_filter || ($value - $last_value) > 0) {
                    # print "DIFF: $value, $last_value\n";
                    $store_num_value = $value - $last_value;
                    # print "DIFF2: $store_num_value\n";
                    update_stat($data_info, $schema, $node, $column_keys, $clock, $store_num_value, '');
                }
            # 数値以外は文字列としてデータ登録
            } else {
                update_stat($data_info, $schema, $node, $column_keys, $clock, 0, $value);
            }
        }
    }
    # print "DATASTORE:$datastore\n";
}

sub new {bless{},+shift}

1;
