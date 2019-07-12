#!/usr/bin/perl
#
# AIX nmonログのバックアップ
#
use strict;

# パッケージ読込
BEGIN {
    my $pwd = `dirname $0`; chop($pwd);
    push(@INC, "$pwd/libs", "$pwd/");
}
#use CGI::Carp qw(carpout);
use File::Spec;
use Getopt::Long;
# use Param;

# 環境変数設定
$ENV{'LANG'}='C';
my $SRC='/siview/log/SMC/nmon/hourly';
my $QUEID='nmon_hourly';
my $GREP='nmon';
my $TARGET='.';
my $MTIME=30;
GetOptions ('--src=s' => \$SRC,
    '--id=s' => \$QUEID,
    '--grep=s' => \$GREP,
    '--target=s' => \$TARGET,
    '--mtime=s' => \$MTIME);

#$SRCPERF .= $QUEID;

# ディレクトリ設定
my $HOST=`hostname`; chop($HOST);
my $PWD = `dirname $0`; chop($PWD);     # ~mon/script
my $WORK = "$PWD/../_wk";           # ~mon/_wk
#$TARGET = File::Spec->rel2abs( $TARGET );


# ディレクトリチェック
if (!-d "$WORK"){
    `/bin/mkdir -p $WORK`;
}

# メイン
&main;
exit(0);

sub udatefile {
    my ($fname) = @_;

    warn("CHECK DATE[$fname]\n");
    my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks)
        = stat($fname);
    my ($ss, $mm, $hh, $DD, $MM, $YY, $wday, $yday, $isdst) = localtime($mtime);
    my $dt = sprintf("%04d%02d%02d%02d%02d.%02d",
        $YY + 1900, $MM + 1, $DD, $hh, $mm, $ss);
    warn("LAST UPDATE[$dt]\n");

    return($dt);
}

sub lasttime {
    my $mtime = time() - 60 * $MTIME;
    my ($ss, $mm, $hh, $DD, $MM, $YY, $wday, $yday, $isdst) = localtime($mtime);
    my $dt = sprintf("%04d%02d%02d%02d%02d.%02d",
        $YY + 1900, $MM + 1, $DD, $hh, $mm, $ss);
    return($dt);
}

sub main {
    # タイムスタンプチェック
    if (! -f "$WORK/lastupd_$QUEID") {
        my $last_upd = lasttime();
        my $cmd = "/bin/touch -t $last_upd $WORK/lastupd_$QUEID";
        warn("INIT:\n$cmd\n");
        system($cmd);
    }

    # ログファイル検索
    my $cmd="/bin/find $SRC -name \"*.*\" -newer $WORK/lastupd_$QUEID -prune";
    warn("FIND:\n$cmd\n");
    my @INFILES;
        open(IN, "$cmd|");
        while(<IN>) {
            chop;
            # 日次で生成されるファイルは除外する
            next if ($_=~/_2345\.nmon/);
            push(@INFILES, $_);
    }
    # 最新のファイルは取り除く
    pop(@INFILES);

    # 対象ファイルが10個以上の場合は最新の10個のみをコピーする
    while (scalar(@INFILES) > 10) {
        shift(@INFILES);
    }

    # 対象ファイルがない場合は終了
    die "No backup file" if (scalar(@INFILES) == 0);

    # タイムスタンプ作成
    unlink("$WORK/lastupd_$QUEID") if (-f "$WORK/lastupd_$QUEID");
    $cmd = "/bin/touch $WORK/lastupd_$QUEID";
    warn("TOUCH:\n$cmd\n");
    system($cmd);

    # 対象ファイルリスト作成
    my $srcfiles;
    open(OUT , "> $TARGET/list_$QUEID.txt");
    for my $file(sort @INFILES) {
        $file =~ s|$SRC|.|;
        if ($GREP) {
            next if ($file!~/$GREP/);
        }
	$file=~s/^\.//g;
	$file=~s/^\///g;
        $srcfiles .= " " . $file;
        print OUT "$file\n";
    }
    close(OUT);

    # 対象ファイルコピー
    # 対象ファイルコピー
    my $targetdir = "$TARGET/$QUEID";
    warn("mkdir $targetdir");
    `mkdir $targetdir` if (! -d $targetdir);
    my $cmd = "(cd $SRC; /bin/cp -p $srcfiles $targetdir)";
    warn("COPY:\n$cmd\n");
    system($cmd);
}


