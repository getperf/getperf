#!/usr/local/bin/perl
use strict;

# パラメータ読込
BEGIN { 
    my $pwd = `dirname $0`; chop($pwd);
    push(@INC, "$pwd/libs", "$pwd/"); 
}
use Time::Local;
use Getopt::Long;
use File::Basename;
use File::Spec;

# 共通変数
my @SCHEMA=('APCMAIN', 'QDCMAIN');		# スキーマ識別種別

# 環境変数設定
$ENV{'LANG'}='C';
my $ODIR = $ENV{'PS_ODIR'} || '.';
my $IDIR = $ENV{'PS_IDIR'} || '.';
my $IFILE = $ENV{'PS_IFILE'} || 'oraseg.txt';
my $SCHEMAS = '';

GetOptions (
	'--schema=s' => \$SCHEMAS,
	'--ifile=s' => \$IFILE,
	'--idir=s' => \$IDIR,
	'--odir=s' => \$ODIR);

if ($SCHEMAS) {
	@SCHEMA = split(/,/, $SCHEMAS);
}

# ディレクトリ設定
my $PWD = `dirname $0`; chop($PWD);     # ~mon/script
if (!-d $ODIR) {
	`/bin/mkdir -p $ODIR`;
}

# メイン
&main;
exit(0);

# スキーマチェック
sub check_user {
	my ($usr) = @_;

	my $res = 'ETC';
	for my $key(@SCHEMA) {
		if ($key eq $usr) {
			$res = $key;
		}
	}
	return($res);
};

# ログ生成
sub mkoraseglog {
	my ($infile) = @_;
	my ($sec, $dt);
	my $cnt = 0;
	my %tbs;	# テーブルサイズ
	my %tbssum;
	my %tms;	# 時系列

	# 出力ファイル名作成
	$infile=~/oraseg_(.*)\.txt/;
	my $sid = $1;
	my ($fname, $path, $suffix) = fileparse($infile, qr{\.txt});
	my $ofile = $ODIR . "/OraSize_" . $sid . ".txt";

print "OUT $ofile\n";

	open(OUT, ">$ofile");

print "IN $IDIR/$infile\n";

	open(IN, "$IDIR/$infile");

	print OUT "Time               ,USER,TYPE,MB,TBS\n";

	while (<IN>) {
		chop;
		my $line = $_;
		if ($_=~/^Date:(\d\d)\/(\d\d)\/(\d\d) (\d\d):(\d\d):(\d\d)$/) {
			my ($YY, $MM, $DD, $hh, $mm, $ss) = ($1, $2, $3, $4, $5, $6);
			$sec = timelocal($ss,$mm,$hh,$DD,$MM-1,$YY-1900+2000);
			my ($ss, $mm, $hh, $DD, $MM, $YY, $wday, $yday, $isdst) = localtime($sec);
			$dt = sprintf("%04d/%02d/%02d %02d:%02d:%02d", 
				$YY + 1900, $MM + 1, $DD, $hh, $mm, $ss);
			$tms{$dt} = 1;
		} else {
			my ($user, $type, $mb, $tbs) = split(/,/, $line);
			my $usercat = check_user($user);
			my $key = join(" ", ($dt, $usercat, $type));
			my $key2 = join(" ", ($dt, $type));

			$tbs{$key} += $mb;
			$tbssum{$key2} += $mb;
			print OUT $dt . "," . $line . "\r\n" if ($cnt > 0);
			$cnt ++;
		}
	}
	close(IN);
	close(OUT);

	# ヘッダー
	my $head = "Time                    Total ";
	for my $stat((@SCHEMA, 'ETC')) {
		$head .= sprintf(" %10s", $stat);
	}

	# 表サイズレポート
	for my $usercat((@SCHEMA, 'ETC')) {
		my ($line, $size);
		for my $tm(sort keys %tms) {
			$line .= $tm;
			my $key1 = join(" ", ($tm, $usercat, 'TABLE'));
			my $key2 = join(" ", ($tm, $usercat, 'TABLE PARTITION'));
			$size = $tbs{$key1} + $tbs{$key2};
			$line .= sprintf(" %10.2f\n", $size);
		}
		if ($size > 0) {
			my $fname = join('_', ('orasize_tbl', $sid, $usercat)) . '.txt';
			open(OUT, ">$ODIR/$fname");
			print OUT sprintf("time %10s\n", $usercat);
			print OUT $line;
			close(OUT);
		}
	}

	# 索引サイズレポート
	for my $usercat((@SCHEMA, 'ETC')) {
		my ($line, $size);
		for my $tm(sort keys %tms) {
			$line .= $tm;
			my $key1 = join(" ", ($tm, $usercat, 'INDEX'));
			my $key2 = join(" ", ($tm, $usercat, 'INDEX PARTITION'));
			$size = $tbs{$key1} + $tbs{$key2};
			$line .= sprintf(" %10.2f\n", $size);
		}
		if ($size > 0) {
			my $fname = join('_', ('orasize_idx', $sid, $usercat)) . '.txt';
			open(OUT, ">$ODIR/$fname");
			print OUT sprintf("time %10s\n", $usercat);
			print OUT $line;
			close(OUT);
		}
	}
}

sub main {
print "IDIR $IDIR\n";
        opendir ( DIR, $IDIR ) || die "Can't open dir. $!\n";
        my @infiles = grep /oraseg_(.*)\.txt/, readdir(DIR);
        closedir( DIR );

        for my $infile(@infiles) {
print "INFILE $infile\n";
                mkoraseglog($infile);
        }
}
