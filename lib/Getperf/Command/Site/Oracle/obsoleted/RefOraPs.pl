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

# 環境変数設定
$ENV{'LANG'}='C';
my $ODIR='./tmp';
my $INTERVAL=30;
my %ORAPS;
my %ORASES;
my %DATELIST;

# 実行オプション
my $ODIR = $ENV{'PS_ODIR'} || '.';
my $IDIR = $ENV{'PS_IDIR'} || '.';
my $IFILE = $ENV{'PS_IFILE'} || 'psutil.txt';

GetOptions (
	'--idir=s'     => \$IDIR,
	'--ifile=s'    => \$IFILE,
	'--odir=s'     => \$ODIR,
	'--interval=i' => \$INTERVAL);

my $PSFILE = "$IDIR/$IFILE";

# Oracleプロセスオーナー
my $OSUSER = 'oracle';

# プロセス集計カテゴリ(スキーマ別)
my @USRCAT = (
	'RTDMGR',
	'STARSTATE',
	'PERFSTAT',
);
my $USRCAT_STR = join(',', @USRCAT);

# プロセス集計カテゴリ(プログラム別)
my @PROGCAT = (
	'oracle',
	'sqlplus',
	'JDBC',
	'.exe',
);
my $PROGCAT_STR = join(',', @PROGCAT);

# プロセス集計カテゴリ(ホスト別)
my @HOSTCAT = (
	'yiura',
	'yiwfm',
	'yyyis',
);
my $HOSTCAT_STR = join(',', @HOSTCAT);

# ディレクトリ設定
my $PWD = `dirname $0`; chop($PWD);     # ~mon/script
if (!-d $ODIR) {
	`/bin/mkdir -p $ODIR`;
}

# メイン
&main;
exit(0);

# 日時を秒に変換
sub time2sec {
        my ($time) = @_;
        my $day = 0;

        # 日付変換
        if ($time=~/(\d+)-(.*)/) {
                ($day, $time) = ($1, $2);
        }

        # 時刻変換
        my @hhmmss = split(/:/, $time);
        my $y = 0;
        for my $x(@hhmmss) {
                $y = 60 * $y + $x;
        }
        $y += 24 * 3600 * $day;

        return ($y);
}

# Oracleプロセスログ抽出
sub getoraps {
	my ($sec, $dt);
	my $cnt = 0;
	my %sesstat;	# セッション

	# psutil.txt の保存ディレクトリから該当ファイル検索
	my ($fname, $path, $suffix) = fileparse($PSFILE, qr{\.txt});

	# oraproc_XXX.txtファイル検索
	opendir ( DIR, $path ) || die "Can't open dir. $!\n";
	my @infiles = grep /oraproc_(.*)\.txt/, readdir(DIR);
	closedir( DIR ); 

	for my $infile(@infiles) {
		# ファイル読込
		$infile=~/oraproc_(.*)\.txt/;
		my $sid = $1;

		open(IN, $path . "/" . $infile);
		while (<IN>) {
			chop;
			my $line = $_;
			# 日付の抽出
			if ($_=~/^Date:(\d\d)\/(\d\d)\/(\d\d) (\d\d):(\d\d):(\d\d)$/) {
				my ($YY, $MM, $DD, $hh, $mm, $ss) = ($1, $2, $3, $4, $5, $6);
				$sec = timelocal($ss,$mm,$hh,$DD,$MM-1,$YY-1900+2000);
				$sec = 60 * int($sec / 60);
				my ($ss, $mm, $hh, $DD, $MM, $YY, $wday, $yday, $isdst) = localtime($sec);
				$dt = sprintf("%04d/%02d/%02d %02d:%02d:%02d", 
					$YY + 1900, $MM + 1, $DD, $hh, $mm, $ss);
			# データの抽出
			} else {
				my @vals =split(/,/, $line);
				# 簡易フォーマットチェック
				if (scalar(@vals) != 5) {
					next;
				} 
				# PIDをキーにハッシュ作成
				my $sesid = shift(@vals);
				my $pid = shift(@vals);
				my $key = join(",", ($pid));
				$ORASES{$key} = join(",", ($sid, @vals));
			}
		}
		close(IN);
	}

#	for my $key(sort keys %ORASES) {
#		my $line = join(",", ($key , $ORASES{$key}));
#		print $line . "\n";
#	}
}

# プロセスIDからOracleセッションをチェック
sub check_proc {
	my ($pid, $grp, $usr, $cmd) = @_;
	my $key;

	if ($usr ne $OSUSER) {
		$key = join(",", ('others', undef, undef, undef));
		return($key);
	}

	# Oracleプロセスのチェック
	if ($ORASES{$pid}) {
		my @orases = split(",", $ORASES{$pid});
		shift(@orases);

		# ユーザカテゴリチェック
		my $schema = shift(@orases);	# ユーザ
		$schema = 'ETC' if ($schema eq '');	# ユーザがnullの場合
		my $usercat = 'ETC';
		for my $key(@USRCAT) {
			if ($schema=~/$key/) {
				$usercat = $key;
			}
		}
		$usercat = $schema;

		# ホストカテゴリチェック
		my $host = shift(@orases);	# ホスト
		$host=~s/[0-9|\\|.].*//g;	# サフィックスを削除
		my $hostcat = 'ETC';
		for my $key(@HOSTCAT) {		
			if ($host=~/$key/) {
				$hostcat = $key;
			}
		}
		$hostcat = $host;

		# Programカテゴリチェック
		my $prog = shift(@orases);	# プログラム
		my $progcat = 'ETC';
		for my $key(@PROGCAT) {
			if ($prog=~/$key/) {
				$progcat = $key;
			}
		}

		$key = join(",", ($hostcat, $usercat, $progcat, $prog));
	# その他の場合のチェック
	} else {
		$key = join(",", ('ETC', 'ETC', 'ETC', 'ETC'));
	}

	return($key);
}

# Pivot変換 縦軸：日付、横軸：slist
sub ps_pivot {
	my ($dt, $slist, %dat) = @_;
	my $line = $dt;

	my @cat = split(',', $slist);
	for my $ps(@cat) {
		my $key = $dt . "," . $ps;
		# 1秒当りのCPU時間*100；CPU利用率に換算
		$line .= " " . sprintf("%8.2f", $dat{$key} * 100.0 / $INTERVAL);
	}
	return($line);
}

# CPU時間集計レポート
sub mklogfile {
	my ($fname, $slist, %dat) = @_;

	# ファイルオープン
	my $outfile = "$ODIR/$fname";
	print("MKLOG : $outfile\n");
	open(OUT, ">$outfile") || die "Can't open $outfile : $1";

	# 集計ヘッダ作成
	my @cat = split(',', $slist);
	push(@cat, 'ETC');
	$slist = join(',', @cat);

	# ヘッダ出力
	my $line = 'DATE     TIME    ';
	for my $ps(@cat) {
		$line .= " " . sprintf("%8s", $ps);
	}
	print OUT $line . "\n";

	for my $dt(sort keys %DATELIST) {
		print OUT ps_pivot($dt, $slist, %dat) . "\n";
	}
	close(OUT);
}

sub mkorapslog {
	my (%cpu_wk);
	my (%pscpu_host, %pscpu_prog, %pscpu_usr);
	my ($sec);
	my $cnt = 0;

	# ファイル出力設定
	my $outfile = "$ODIR/orapsutil.txt";
	print("MKLOG : $outfile\n");
	open(OUT, ">$outfile") || die "Can't open $outfile : $1";

	# ファイル入力設定
	die "$PSFILE not found : $!" if (!-f $PSFILE);
	open(IN, $PSFILE);

	my ($dt, $pid, $ppid, $grp, $usr, $tms, $nlwp, $vsz, $arg);
	while (<IN>) {
		chop;

		# 日時抽出
		if ($_=~/^Date:(.*)$/) {
			$dt = $1;
			$DATELIST{$dt} = 1 if ($cnt > 0);
			$cnt ++;
			next;
		}
		# ヘッダは除外
		next if ($_=~/\s+PID/);

		# データ行抽出
		my @args = split(/\s+/, $_);
		if (!$args[0]) {
			shift(@args);
		}
		my ($pid, $ppid, $grp, $usr, $tms, $nlwp, $vsz, $cmd) = @args;
		next if ($cmd eq '');	# 簡易フォーマットチェック

		# カテゴリチェック
		my ($orahost, $orausr, $oracat, $oraprog)
			= split(/,/, check_proc($pid, $grp, $usr, $cmd));

		# CPU時間算出
		my $pid_key = join(",", ($pid, $ppid));
		my $cputm = time2sec($tms);
		my $cpusec = 0;
		if ($cpu_wk{$pid_key}) {
			$cpusec = $cputm - $cpu_wk{$pid_key};
		} else {
			$cpusec = $cputm;
		}
		$cpu_wk{$pid_key} = $cputm;

		next if ($orahost eq 'others');		# Oracle 以外のプロセスは読み飛ばす

		# OracleプロセスのCPU時間出力、集計
		if ($cnt > 1) {
			print OUT join(",", 
				($dt,$orahost,$oracat,$oraprog,$pid,$usr,$nlwp,$vsz,$cpusec,$cmd)) . "\n";
			# 日付、ホスト名でCPU時間集計
			my $key = $dt . ',' . $orahost;
			$pscpu_host{$key} += $cpusec * 1.0;
			# 日付、ユーザ名でCPU時間集計
			my $key = $dt . ',' . $orausr;
			$pscpu_usr{$key} += $cpusec * 1.0;
			# 日付、Programカテゴリ名でCPU時間集計
			my $key = $dt . ',' . $oracat;
			$pscpu_prog{$key} += $cpusec * 1.0;
		}
	}

	close(IN);
	close(OUT);

	mklogfile('orapshost.txt', $HOSTCAT_STR, %pscpu_host);
	mklogfile('orapsusr.txt', $USRCAT_STR, %pscpu_usr);
	mklogfile('orapsprog.txt', $PROGCAT_STR, %pscpu_prog);

}

sub main {
	getoraps();
	mkorapslog();
}
