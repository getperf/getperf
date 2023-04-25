#!/usr/bin/perl
# RRDtool 値入力の最大値設定のメンテナンススクリプト
# 指定したディレクトリ下に保存したRRDファイルの入力最大値を設定します
use strict;
use utf8;
use Encode;
use Data::Dumper;
use Getopt::Long;

my $KEYWORD  = '';
my $RESTORE  = 0;
my $DEBUG    = 0;
my $CLEAR    = 0;
my $IDIR     = "./storage/Db2";
my $USAGE    = "rrd_tune, version : 0.0.1\n" .
	"Usage : rrd_tune.pl [--idir=s] [--keyword=s] [--clear] [--restore] [--debug]\n";

GetOptions('--idir=s' => \$IDIR, '--keyword=s' => \$KEYWORD, 
	'--clear' => \$CLEAR, '--restore' => \$RESTORE, '--debug' => \$DEBUG ) || die $USAGE;
if (! -d $IDIR) {
	die "rrdtool storage dir not found $IDIR\n$USAGE";
}
&main();
exit;

# RRD ファイルの入力最大値の設定を定義し、指定した条件の最大値を返します
# 以下の3つの入力パラメータを指定し、その項目の入力最大値を返します
#     RRDファイル名($rrdname), 
#     RRD項目名($datasource), 
#     最大値規定値($dafault_value)
sub check_datasource_max {
	my ($rrdname, $datasource, $default_value) = @_;
	# 最大値をリセットする場合は'U'を指定
	if ($CLEAR) {
		return 'U';
	# SQL ランクグラフ(sql_top)の場合、項目名別に最大値を指定
	} elsif ($rrdname=~/sql_top/) {
		if ($datasource eq 'CPU_TIME') {
			return 100000000000; # M補正あり
		} elsif ($datasource eq 'EXEC_TIME' or $datasource eq 'ACT_WAIT_TIME') {
			return 100000000; # K補正あり
		} elsif ($datasource eq 'ROWS_READ') {
			return 1000000000000;
		} elsif ($datasource eq 'ROWS_MODIFIED') {
			return 100000000000;
		}
		return 10000000; # 1000,000,000,000
	# Db2 CF 統計用 "mon_get_cf" の場合
	} elsif ($rrdname=~/mon_get_cf/) {
		return 100000000000;
	# Db2 統計用 "mon_get" の場合(mon_get が含まれるRRDファイル名すべて)
	} elsif ($rrdname =~/mon_get/) {
		return 100000000;
	# それ以外のRRDファイルの場合、規定値を指定
	} else {
		return $default_value;
	}
}

# RRD ファイルの項目定義を検索して項目リストを返します
sub get_rrdtool_ds_info {
	my ($rrdfile) = @_;
	open( my $in, "rrdtool info $rrdfile | grep max |") || die
		"cant't read $rrdfile : $!";
	my @ds = ();
	while (my $line = <$in>) {
		# print $line;
		if ($line=~/ds\[(.+?)\]/) {
			push @ds, $1;
		}
	}
	close($in);
	return @ds;
}

# RRDファイル最大値指定コマンドを返します
sub get_rrdtool_tune_command {
	my ($rrdname, $rrdfile, $ref_ds_list, $max_value) = @_;
	my @cmds;
	push @cmds, "rrdtool tune ${rrdfile}";
	for my $ds(@{$ref_ds_list}) {
		my $max_value2 = check_datasource_max(
			$rrdname, $ds, $max_value
		);
		push @cmds, "--minimum ${ds}:0 --maximum ${ds}:${max_value2}";
	}
	my $cmd = join(" \\\n", @cmds);
	return $cmd . "\n";
}

# 指定コマンドを実行して終了コードを返します
sub spawn {
	my ($cmd) = @_;
	my $rc = 0;
	if ($DEBUG) {
		print $cmd . "\n";
	} else {
		$rc = system($cmd);
		die "$cmd error: $rc" if ($rc != 0);
	}
	return $rc;
}

# RRDファイルのダンプリストアコマンドをバッチ実行します
sub dump_restore_rrdfile {
	my ($rrdfile) = @_;
	my $rrdname = $rrdfile;
	$rrdname=~s/.+\///g;
	my $rc = 0;
	my $cmd = "cp ${rrdfile} /tmp/${rrdname}";
	$rc = spawn($cmd);
	my $cmd = "rrdtool dump /tmp/${rrdname} /tmp/${rrdname}.xml";
	$rc = spawn($cmd);
	my $cmd = "mv /tmp/${rrdname} /tmp/${rrdname}.old";
	$rc = spawn($cmd);
	my $cmd = "rrdtool restore /tmp/${rrdname}.xml /tmp/${rrdname} -r";
	$rc = spawn($cmd);
	my $cmd = "cp /tmp/${rrdname} ${rrdfile}";
	$rc = spawn($cmd);
	my $cmd = "rm /tmp/${rrdname}*";
	$rc = spawn($cmd);
	return $rc;
}

# RRDファイルの入力最大値設定コマンドを実行します
sub tune_rrdfile_max {
	my ($rrdfile, $max_value, $restore) = @_;
	my $rrdname = $rrdfile;
	$rrdname=~s/.+\///g;
	my @ds_list = get_rrdtool_ds_info($rrdfile);
	# print Dumper \@ds_list;
	my $rrd_tune_cmd = get_rrdtool_tune_command(
		$rrdname, $rrdfile, \@ds_list, $max_value);
	my $rc = spawn($rrd_tune_cmd);
	$rc = dump_restore_rrdfile($rrdfile) if ($restore);
	print "[$rc] ${rrdfile}\n";
}

# 指定したディレクトリ下のRRDファイルを検索して、入力最大値を設定します
sub main {
	open (my $in2, "find ${IDIR} -name \"*.rrd\" | ") ||
		die "find error ${IDIR} : $!";
	while (my $rrdfile = <$in2>) {
		chomp $rrdfile;
		if ($KEYWORD && $rrdfile!~/$KEYWORD/) {
			next;
		}
		tune_rrdfile_max($rrdfile, 10000000, $RESTORE);
	}
	close($in2);
}
