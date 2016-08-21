#!/usr/bin/perl
use strict;
use FindBin;
use File::Copy;
use Data::Dumper;

# ディレクトリの設定
my $PWD    = $FindBin::Bin;
my $GPHOME = "${PWD}/..";
my $BINDIR = "${GPHOME}/bin";

# 実行引数チェック
my $USAGE  = "gpfDeployModule.pl, version : 2.5.0(UNIX)\n" .
	"Usage : gpfDeployModule.pl [zippath]\n";
die $USAGE if (scalar(@ARGV) != 1);

# 引数のzipパスをディレクトリとファイル名に分解
my ($zipdir, $zipfile) = ("$GPHOME/_wk", $ARGV[0]);

# zipディレクトリに stage.{PID} という一時ディレクトリ作成
my $stage = "$zipdir/stage.$$";
mkdir($stage);

# ディレクトリを移動し、「./getperfzip -u -b stage.{PID} {zipファイル}」実行
chdir($zipdir);
my $cmd = "$BINDIR/getperfzip -u -b $stage $zipfile";
print "\n\n[Exec] $cmd\n";
if (system($cmd) != 0) {
	die "exec error $cmd : $!";
}

# コアモジュールの場合はバイナリを.bakに移動
if ($zipfile=~/^getperf-([^-]*)-([^-]*)-(\d*)\.zip/) {
	move("$GPHOME/bin/getperf",     "$GPHOME/bin/getperf.bak" );
	move("$GPHOME/bin/getperfctl",  "$GPHOME/bin/getperfctl.bak" );
	move("$GPHOME/bin/getperfzip",  "$GPHOME/bin/getperfzip.bak" );
	move("$GPHOME/bin/getperfsoap", "$GPHOME/bin/getperfsoap.bak" );
}

# stage.{PID} 下のbinディレクトリを検索し、その下のファイル全てに実行権限を付与
my @bindirs = `find ${stage} -name bin -print`;
for my $bindir( @bindirs ) {
	chomp($bindir);
	next if ( ! -d $bindir );
	opendir( DIR, $bindir ) || die "Can't open $bindir : $@";
	my @binfiles = map { "$bindir/$_" } grep { -f "$bindir/$_" }  readdir(DIR);
	closedir(DIR);
	chmod 0755, @binfiles;
}

# stage.{PID} に移動して解凍したファイルをホームにコピー
$cmd = "cd ${stage} && cp -r * ${GPHOME}";
print "\n\n[Exec] $cmd\n";
if (system($cmd) != 0) {
	die "exec error $cmd : $!";
}

system("rm -r ${stage}");

print "update succeed!";
exit(0);
