#!/usr/bin/perl
#
# ログのバックアップ
# 
# 使用例：
#  perl bkapllog.pl --src=/var/log --target=/home/psadmin/work/sfw/tmp --grep=logwatch
#
use strict;

# パッケージ読込
use File::Spec;
use Getopt::Long;
use Data::Dumper;

# 環境変数設定
$ENV{'LANG'}='C';
my $SRC='/var/log';
my $QUEID='';
my $GREP='';
my $TARGET='.';
my $MTIME=30;
GetOptions (
	'--src=s'    => \$SRC,
	'--id=s'     => \$QUEID,
	'--grep=s'   => \$GREP,
	'--target=s' => \$TARGET,
	'--mtime=s'  => \$MTIME);

# ディレクトリ設定
my $PWD = `dirname $0`; chop($PWD);
my $WORK = File::Spec->rel2abs("$PWD/../_wk");
$TARGET = File::Spec->rel2abs( $TARGET );


# ディレクトリチェック
if (!-d "$WORK"){
    `/bin/mkdir -p $WORK`;
}

# メイン
&main;
exit(0);

# ファイルの最終更新日付を取得
sub lastupdate {
    my ($fname) = @_;

	my @fstat = stat( $fname );
	return $fstat[9];		# 最終更新日付
}

sub main {
    # タイムスタンプチェック
	my $last_timestamp = ($QUEID eq '') ? "$WORK/last_upd_${GREP}" : "$WORK/last_upd_${QUEID}";
	my $tms = (-f $last_timestamp) ? lastupdate( $last_timestamp ) : time() - $MTIME * 24*60;

    # ログファイル検索
    opendir DIR, $SRC;
	my @filelist = ();
	map { 
		my $timestamp = lastupdate( "$SRC/$_" );
		push(@filelist,  $_) if ($timestamp > $tms);
	} grep ( /^[^.]/ && /$GREP/ && -f "$SRC/$_", readdir DIR );
	close DIR;
	
	# 対象ファイルがない場合は終了
	die "No backup file\n" if (scalar(@filelist) == 0);

	# タイムスタンプ作成
	my $cmd = "touch ${last_timestamp}";
	warn("TOUCH:\n$cmd\n");
	system($cmd);

    # 対象ファイルコピー
	my $sources = join(" ", @filelist);
	my $targets = "${TARGET}/${QUEID}";
	system("mkdir $targets") if (! -d $targets);
	$cmd = "(cd $SRC; /bin/cp -p $sources $targets)";
	warn("COPY:\n$cmd\n");
	system($cmd);

	# ファイルリスト作成
	if ($QUEID ne '') {
		open OUT, ">${targets}.txt" || die "Can't open ${targets}.txt @?\n";
		print OUT $sources;
		close(OUT);
	}
}

