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
use DBI;

# 実行オプション
$ENV{'LANG'}='C';
my $ODIR = $ENV{'PS_ODIR'} || '.';
my $IDIR = $ENV{'PS_IDIR'} || '.';
my $IFILE = $ENV{'PS_IFILE'} || 'orases.txt';

my %refmetric = (
	'execute count'            => 'exec',
	'physical reads'           => 'disk',
	'db block gets'            => 'buff',
	'consistent gets'          => 'buff',
	'table fetch by rowid'     => 'row',
	'redo synch time'          => 'redo',
	'user I/O wait time'       => 'iowait',
	'CPU used by this session' => 'cpu',
	'user commits'             => 'commit',
);

my (%TMS, %RMC, %DAT, %SID);

GetOptions (
	'--idir=s'     => \$IDIR,
	'--ifile=s'    => \$IFILE,
	'--odir=s'     => \$ODIR,
) || die "Usage : $0 [--idir=dir] [--odir=dir]\n";

# ディレクトリ設定
my $PWD  = `dirname $0`; chop($PWD);    # ~mon/script
my $WORK = "$PWD/../_wk";               # ~mon/_wk
if (!-d $ODIR) {
	`/bin/mkdir -p $ODIR`;
}

# ファイルオープン
# /analysis/auto_s/HW/20100512/1500/
die if ($IDIR!~m|/*analysis/*(.*?)/*ORACLE_DET/*(\d*)/*(\d*)/|);
my ($HOST, $DT, $TM) = ($1, $2, $3);
print "Host:$HOST\n";

# DB環境設定
my $SQLDB  = "$WORK/vsql_rmc.db";
my $CPUDB  = "$WORK/pscpu_rmc.db";
my $SQLITE = "/usr/local/bin/sqlite3";

print "$SQLDB:$SQLDB:$SQLITE\n";

# データ
my (%TMS, %MOD);
my (%DAT, %VSQL);

# メイン
&main;
exit(0);

# SQLDB初期化。失敗した場合は強制終了する。
# 戻り値：なし

sub initdb {
	# テーブル作成
	my $cresql =  join(" ", qw (
		CREATE TABLE vsql \(
			upd_date   TEXT NOT NULL ,
			upd_time   TEXT NOT NULL ,
			hostname   TEXT NOT NULL ,
			process    TEXT NOT NULL ,
			row        REAL ,
			exec       REAL ,
			commits    REAL ,
			cpu        REAL ,
			iowait     REAL ,
			buff       REAL ,
			disk       REAL ,
			redo       REAL ,
			elapse     REAL ,
			PRIMARY KEY\(upd_date, upd_time, hostname, process\) 
		\);

		CREATE TABLE vsql_diff \(
			upd_date   TEXT NOT NULL ,
			upd_time   TEXT NOT NULL ,
			hostname   TEXT NOT NULL ,
			process    TEXT NOT NULL ,
			row        REAL ,
			exec       REAL ,
			commits    REAL ,
			cpu        REAL ,
			iowait     REAL ,
			buff       REAL ,
			disk       REAL ,
			redo       REAL ,
			elapse     REAL ,
			PRIMARY KEY\(upd_date, upd_time, hostname, process\) 
		\);
	));

	# DBの有無確認とテーブルの有無の確認
	if (-f $SQLDB) {
		my $cmd = "$SQLITE $SQLDB \".schema vsql\"";
		my $buf = `$cmd`;

		# 終了コードが0場合は何もしない
		return if ($buf=~/^CREATE TABLE vsql/);
	}

	# テーブル作成
	my $cmd = "$SQLITE $SQLDB \"$cresql\"";
	my $ret = system($cmd);
}

# 指定した時間より過去のデータを削除する
sub trandat {
	# ロック待ちエラー発生時にリトライする。
	my $succ  = 0;
	my $retry = 5;
	my %vsql_last;

	while ($succ == 0 && $retry > 0) {
		$succ = 1;
		$retry --;

		# データーベースに接続する
		my $hDB;
		$hDB = DBI->connect( "dbi:SQLite:dbname=$SQLDB", "", "" );
		die "$DBI::errstr : $!" if ( !$hDB );

		# 1時間前のデータは削除
		my $sthd = $hDB->prepare(
			"DELETE FROM vsql " .
			"WHERE upd_date||upd_time <= " .
			"STRFTIME( '%Y%m%d%H%M', datetime('now', 'localtime', '-24 hours'))||'00'");
		die "$DBI::errstr : $!" if ( !$sthd );
		my $ret  = $sthd->execute();
		die "$hDB->errstr : $!" if ( !$ret );
		$sthd->finish;
		undef($sthd);

		my $sthd2 = $hDB->prepare(
			"DELETE FROM vsql_diff " .
			"WHERE upd_date||upd_time <= " .
			"STRFTIME( '%Y%m%d%H%M', datetime('now', 'localtime', '-24 hours'))||'00'");
		die "$DBI::errstr : $!" if ( !$sthd2 );
		my $ret  = $sthd2->execute();
		die "$hDB->errstr : $!" if ( !$ret );
		$sthd2->finish;
		undef($sthd2);

		$hDB->disconnect;
	}
}

# 集計したファイルリストを履歴DBに更新済みとして登録する
# 入力値：{日付|時刻|ホスト|プロセス}をキーにした{Exec|Buf|Row|Cpu|Elapse}の配列
sub updvsql {
	# ロック待ちエラー発生時にリトライする。
	my $succ  = 0;
	my $retry = 5;
	my %vsql_last;

	while ($succ == 0 && $retry > 0) {
		$succ = 1;
		$retry --;

		# データーベースに接続する
		my $hDB;
		$hDB = DBI->connect( "dbi:SQLite:dbname=$SQLDB", "", "" );
		die "$DBI::errstr : $!" if ( !$hDB );

		# 直前のデータを検索
		my $sql = "select hostname,process, " .
			"row,exec,commits,cpu,iowait,buff,disk,redo,elapse " .
			"from vsql " .
			"where upd_date||upd_time = (select max(upd_date||upd_time) from vsql)" ;
		my $sths = $hDB->prepare( $sql );
		die "$DBI::errstr : $!" if ( !$sths );
		my $ret  = $sths->execute();
		die "$hDB->errstr : $!" if ( !$ret );
		while ( my @res = $sths->fetchrow_array ) {
			my ($hostname, $process, $row, $exec, $commit, $cpu, $iowait, $buff, $disk, 
				$redo, $elapse) = @res;
			my $key = $hostname . ','. $process . ',';
			$vsql_last{$key . 'row'}    = $row;
			$vsql_last{$key . 'exec'}   = $exec;
			$vsql_last{$key . 'commit'} = $commit;
			$vsql_last{$key . 'cpu'}    = $cpu;
			$vsql_last{$key . 'iowait'} = $iowait;
			$vsql_last{$key . 'buff'}   = $buff;
			$vsql_last{$key . 'disk'}   = $disk;
			$vsql_last{$key . 'redo'}   = $redo;
			$vsql_last{$key . 'elapse'} = $elapse;
		}
		$sths->finish;
		undef($sths);

		# dt,tm,host,processをキーにcpuを登録
		my $sthr = $hDB->prepare(
			"replace into vsql values(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");
		die "$DBI::errstr : $!" if ( !$sthr );
		my $sthr2 = $hDB->prepare(
			"replace into vsql_diff values(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");
		die "$DBI::errstr : $!" if ( !$sthr2 );

		for my $module (keys %MOD) {
			for my $host (keys %SID) {
				for my $tm(sort keys %TMS) {
					my ($upd_date, $upd_time);
					if ($tm=~m|^(\d+)/(\d+)/(\d+) (\d+):(\d+):(\d+)$|) {
						my ($YY, $MM, $DD, $HH, $MI, $SS) = ($1, $2, $3, $4, $5, $6);
						$upd_date = $YY . $MM . $DD;
						$upd_time = $HH . $MI;
					}
					my @vals = ();
					my @diffs = ();
					for my $item ('row', 'exec', 'commit', 'cpu', 'iowait', 'buff', 
						'disk', 'redo', 'elapse') {
						my $key  = $tm   . ',' . $host . ',' . $module . ',' . $item;
						my $val = $DAT{$key} || 0;
#print "KEY2:$key=$val\n";
						push(@vals, $val);
						my $key2 = $host . ',' . $module . ',' . $item;
						my $last = $vsql_last{$key2};
						my $diff = 0;
						if ($last > 0 && $val > 0 && $val - $last > 0) {
								$diff = $val - $last;
						}
						push(@diffs, $diff);
					}
					# vsql登録
#print "UPD1:  $upd_date, $upd_time, $HOST, $module\n" . join(",", @vals) . "\n";
					my $ret = $sthr->execute( $upd_date, $upd_time, $host, $module, @vals);
					if ( !$ret ) {
						$succ = 0;
						warn "$hDB->errstr : $!" ;
						sleep(1);
						last;
					}
					# vsql_diff登録
#print "UPD2:  $upd_date, $upd_time, $HOST, $module\n" . join(",", @diffs) . "\n";
					my $ret = $sthr2->execute( $upd_date, $upd_time, $host, $module, @diffs);
					if ( !$ret ) {
						$succ = 0;
						warn "$hDB->errstr : $!" ;
						sleep(1);
						last;
					}
				}
			}
		}
		$sthr->finish;
		undef($sthr);
		$sthr2->finish;
		undef($sthr2);
		$hDB->disconnect;
	}
}

# jvmstatログ生成
sub mkoraseslog {
	my ($infile) = @_;
	my ($sec, $dt);

	return if ($infile!~/rmc_sql_(.*)\.txt/);
	my $sid = $1;
	$SID{$sid} = 1;
	my ($fname, $path, $suffix) = fileparse($infile, qr{\.txt});
#print "IN:$IDIR/$infile\n";
	open(IN, "$IDIR/$infile");
	while (<IN>) {
		chop;
		my $line = $_;
		if ($_=~/^Date:(\d\d)\/(\d\d)\/(\d\d) (\d\d):(\d\d):(\d\d)$/) {
			my ($YY, $MM, $DD, $hh, $mm, $ss) = ($1, $2, $3, $4, $5, $6);
			$sec = timelocal($ss,$mm,$hh,$DD,$MM-1,$YY-1900+2000);
			my ($ss, $mm, $hh, $DD, $MM, $YY, $wday, $yday, $isdst) = localtime($sec);
			$dt = sprintf("%04d/%02d/%02d %02d:%02d:%02d", 
				$YY + 1900, $MM + 1, $DD, $hh, $mm, $ss);
			$TMS{$dt} = 1;
		} else {
			my ($dt2, $ses, $id, $metric,$cat,$val,$mod) = split(/,/, $_);
			$mod=~s/@.*//g;
			$mod=~s/\(.*\)//g;
			$RMC{$mod} = 1;
			$MOD{$mod} = 1;
			my $key  = join(",", ($dt, $sid, $mod));
			my $key2 = $refmetric{$metric};
			if ($key2 ne '') {
#print "[$key,$key2] $metric=$val\n";
#print "KEY1:" . $key . ',' . $key2 . "\n";
				$DAT{$key . ',' . $key2}   += $val;
			}
		}
	}
	close(IN);
}

sub main {
	initdb();

	opendir ( DIR, $IDIR ) || die "Can't open dir. $!\n";
	my @infiles = grep /rmc_sql_(.*)\.txt/, readdir(DIR);
	closedir( DIR ); 
	
	for my $infile(@infiles) {
    print "Read:$infile\n";
		mkoraseslog($infile);
	}

	my $opath = "$ODIR/rmcsql";
	`mkdir -p $opath` if (!-d $opath);
	for my $sid (sort keys %SID) {
		for my $rmc (sort keys %RMC) {
			# 従来のv$sql統計の換算（既存グラフのCDEF換算(/10000)は廃止)
			my $ofile = sprintf("rmc_sql_%s.txt", $rmc);
			open(OUT, "> $opath/$ofile") || die "Can't open file $!\n";
			my $ln = sprintf("%s %10s %10s %10s %10s %10s %10s %10s\n",
				'date', 'time', 'exec', 'disk', 'buff', 'row', 'cpu', 'elapse');
			print OUT $ln;
			for my $dt (sort keys %TMS) {
				my ($exec,$disk,$buff,$row,$cpu,$elapse);
				my $key = join(",", ($dt, $sid, $rmc));
				$DAT{$key . ',elapse'} = $DAT{$key . ',cpu'} + 
					$DAT{$key . ',redo'} +
					$DAT{$key . ',iowait'};
				my $ln = sprintf("%s %10d %10d %10d %10d %10.0f %10.0f\n",
					$dt, 
					$DAT{$key . ',exec'}, 
					$DAT{$key . ',disk'}, 
					$DAT{$key . ',buff'}, 
					$DAT{$key . ',row'}, 
					$DAT{$key . ',cpu'}, 
					$DAT{$key . ',elapse'});
				print OUT $ln;
			}
			close(OUT);

			# Oracle ビジー率統計
			my $ofile = sprintf("rmc_orawait_%s.txt", $rmc);
			open(OUT, "> $opath/$ofile") || die "Can't open file $!\n";
			my $ln = sprintf("%s %10s %10s %10s %10s\n", 
				'date', 'time', 'cpu', 'iowait', 'redo');
			print OUT $ln;
			for my $dt (sort keys %TMS) {
				my $key = join(",", ($dt, $sid, $rmc));
				my $ln = sprintf("%s %10.0f %10.0f %10.0f\n",  
					$dt, 
					$DAT{$key . ',cpu'}, 
					$DAT{$key . ',iowait'}, 
					$DAT{$key . ',redo'});
				print OUT $ln;
			}
			close(OUT);

			# DBコミット統計
			my $ofile = sprintf("rmc_dbcommit_%s.txt", $rmc);
			open(OUT, "> $opath/$ofile") || die "Can't open file $!\n";
			my $ln = sprintf("%s %10s %10s %10s %10s %10s", 
				'date', 'time', 'commit', 'elapse');
			print OUT $ln . "\n";
			for my $dt (sort keys %TMS) {
				my $key = join(",", ($dt, $sid, $rmc));
				my $ln = sprintf("%s %10.0f %10.0f\n",  
					$dt, 
					$DAT{$key . ',commit'}, 
					$DAT{$key . ',redo'});
				print OUT $ln;
			}
			close(OUT);
		}
	}
	trandat();
	updvsql();
}

