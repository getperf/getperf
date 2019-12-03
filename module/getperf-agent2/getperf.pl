#!/usr/bin/perl
#
# パフォーマンスログ採取
# Usage: ./getperf.pl --statid=[HW | JVM | ORACLE | STAR | TIBCO]
#
use strict;

# ライブラリ読込
#use POSIX ":sys_wait_h";
use POSIX;
use CGI::Carp qw(carpout);
use Digest::MD5;
use Getopt::Long;
use Digest::MD5;
use SOAP::Lite;
use SOAP::Lite::Packager;
use MIME::Entity;

# 実行パス
my %OSCMD = (
	'dirname' => '/usr/bin/dirname',
	'pwd'     => '/bin/pwd',
);

# ディレクトリ設定
my $PWD      = gethome($0);	   # ~mon/bin
my $HOST     = gethostname();
my $OUT      = "$PWD/log";	   # ~mon/log
my $WORK     = "$PWD/_wk";     # ~mon/_wk
my $WKLOG    = "$PWD/_log";    # ~mon/_log

# 実行オプション設定
$ENV{'LANG'} = 'C';
my $STATID   = 'HW';
my $RUNMODE  = '';
my $HAMODE   = 0;
my $INDEPEND = 0;
my $PARFILE  = "$PWD/Param.ini";
my $USAGE    = "$0 --statid=[HW|AF|ORACLE|...] [--param=../Param.ini] [-ha] [--i]\n";
$USAGE      .= "$0 --runmode=[START|STOP]\n";

GetOptions( 
	'--statid=s'   => \$STATID, 
	'--param=s'    => \$PARFILE,
	'--runmode=s'  => \$RUNMODE,
	'--ha'         => \$HAMODE,
	'--i'          => \$INDEPEND,
) || die $USAGE;

# 環境変数設定
my $BKLOG       = "$PWD/_bk/$STATID";

my %GLOBALPARAM = ();
my %STATPARAM   = ();
my %PIDLIST     = ();
my $DEBUG       = 0;
my $VER         = "v2.5.0";
my $KEY         = 'p2da4';

# シグナル制御
$SIG{'INT'} = \&killProcess;
$SIG{'CHLD'} = "IGNORE";

main();
exit 0;

# メイン関数
sub main {

	# モード変更オプションの場合
	if ($RUNMODE) {
		if ($RUNMODE!~/^(START|STOP)$/) {
			die "Error : --runmode=[START|STOP] : $RUNMODE";
		}
		checkMode($RUNMODE);
	# モニタリングモードの場合
	} else {
		initErrorLog();

		warn "<<<<< START Main [$STATID] [$VER] >>>>>\n";
		# Param.ini読込み
		readParam();

		# ライセンスチェック
		checkLicense();
		# HA監視モードの場合はホスト名をサービス名に変える
		$HOST = checkNode() if ($HAMODE);
		# 起動/停止モードチェック
		if (checkMode() ne 'START') {
			die "Error : startStop.txt : START_STOP_MODE isn't \"START\"";
		}
		# ディスク容量チェック
		my $msg;
		if (!checkDiskUtil(\$msg)) {
			checkMode('STOP');
			sendErrorMessage(1, "Disk util% check error : $msg");
			die "Error : Disk util% check error : $msg\n";
		}
		# 性能データ採取プロセスの起動と監視
		my $dt = runMonitorProcess();
		deleteLog();
		# ログのzip圧縮とデータ送信
		if (!$INDEPEND) {
			my $sendfile = zipLog($dt);
			my $res = checkZipLogs();
		}
		warn "<<<<< END   Main >>>>>\n";
	}
}

# 実行パスから１つ上位のディレクトリをホームとして取得する
# 相対パスは絶対パスに変換する
sub gethome {
	my ($inpath) = @_;
	my $cmd = $OSCMD{'dirname'} . ' ' . $inpath;
	my $dirname = `$cmd`;
	chomp($dirname);
	$dirname .= '/..';
	my $abs_path = '';
	if (-d $dirname) {
		$cmd = 'cd ' . $dirname . '; ' . $OSCMD{'pwd'};
		$abs_path = `$cmd`;
		chomp ($abs_path);
	} else {
		die "Can't change directory $inpath : $@";
	}
	return ($abs_path);
}

# ホスト名を取得する。ドメイン名は削除する。大文字は小文字に変換する。
sub gethostname {
	my $host = `hostname`;
	chomp($host);
	if ($host =~ /^(.*?)\./) {
		$host = $1;
	}
	return(lc($host));
}


# HA監視モードの場合はホスト名をサービス名に変更
sub checkNode {
	my $node;

	my $hastat  = $GLOBALPARAM{'CMD_HASTAT'};
	die "Can't find param : CMD_HASTAT" if (!$hastat);
	
	my @buf;
	open(IN, "$PWD/script/$hastat|") || die "Can't open $PWD/script/$hastat:$1";
	@buf = <IN>;
	close(IN);

	$node = $buf[0];
	chomp($node);
	die "Error : $hastat : $node : $?" if ($node!~/^[a-z|A-Z]/);

	warn "HA service name : $node\n";
	return($node);
}

# パラメータファイル読み込み
sub readParam {
	warn "[1] Read Parameter =========================\n";
	# パラメータファイル読み込み
	warn "Read Param file : $PARFILE\n";
	open(IN, $PARFILE) || die "Can't open file : $PARFILE";
	while (<IN>) {
		# 先頭文字が';'の場合は読み飛ばす
		next if ($_=~/^;/);

		# パラメータ名.カテゴリ = "文字列" の識別
		if ($_=~/(\w[^\s]*)\.(\w[^\s]*)\s*=\s*"([^"]*)"/) {
			if ($2 eq $STATID) {
				my $sep = ($1 eq 'STATCMD')?"\n":"";
				$STATPARAM{$1} .= $3 . $sep;
			}
		# パラメータ名.カテゴリ = '文字列' の識別
		} elsif ($_=~/(\w[^\s]*)\.(\w[^\s]*)\s*=\s*'([^']*)'/) {
			if ($2 eq $STATID) {
				my $sep = ($1 eq 'STATCMD')?"\n":"";
				$STATPARAM{$1} .= $3 . $sep;
			}
		# パラメータ名.カテゴリ = 数値 の識別
		} elsif ($_=~/(\w[^\s]*)\.$STATID\s*=\s*(\d+)/) {
			$STATPARAM{$1} = $2;
		# パラメータ名 = "文字列" の識別
		} elsif ($_=~/(\w[^\s]*)\s*=\s*"([^"]*)"/) {
			$GLOBALPARAM{$1} = $2;
		# パラメータ名 = '文字列' の識別
		} elsif ($_=~/(\w[^\s]*)\s*=\s*'([^']*)'/) {
			$GLOBALPARAM{$1} = $2;
		# パラメータ名 = 数値 の識別
		} elsif ($_=~/(\w[^\s]*)\s*=\s*(\d+)/) {
			$GLOBALPARAM{$1} = $2;
		}
	}
	close(IN);

	# パラメータファイルチェック
	die "Can't find param : STATCMD.$STATID=..." if (!$STATPARAM{'STATCMD'});
	die "Can't find param : STATSEC.$STATID=999" if (!$STATPARAM{'STATSEC'});
	if (!$STATPARAM{'STATMODE'}) {
		warn "Can't find param : STATMODE.$STATID=[concurrent|serial]\n";
		warn "Set : STATMODE.$STATID=\"concurrent\"\n";
		$STATPARAM{'STATMODE'} = 'concurrent';
	}

	# デバック出力
	if ($DEBUG) {
		for my $key (sort keys %GLOBALPARAM) {
			warn "GLOBAL|$key|$GLOBALPARAM{$key}\n";
		}
		for my $key (sort keys %STATPARAM) {
			my $res = join("|", split(/\n/, $STATPARAM{$key}));
			warn "STAT|$key|$res|\n";
		}
	}
}

# WEBサービスを使用してリモートホストから構成ファイルを取得する
sub getConfigFile {
	my ($fname) = @_;
	
	my $url    = $GLOBALPARAM{'URL_CM_SERVICE'};
	my $siteid = $GLOBALPARAM{'SITE_ID'};

	# WEBサービス呼び出し
	my $res = SOAP::Lite
		->packager(SOAP::Lite::Packager::MIME->new)
		->uri('http://perf.getperf.co.jp')
		->proxy($url)
		->getPerfConfigFile($siteid, $HOST, $fname);

	# ダウンロードファイル書き込み
	my $ret = $res->result;
	if ($ret eq 'Ok') {
		open(OUT, ">$WORK/$fname")
			|| die "Can't open file : $WORK/$fname";
		my $part = shift(@{$res->parts});
		$part->print_header(\*STDOUT);
		$part->print_body(\*OUT);
		close(OUT);
	} else {
		my $key = join('/', ($siteid, $HOST, $fname));
		warn "LicenseService failed : [RC=$res]\n$key\n";
		return (0);
	}
	# zipファイル解凍
	my $unzip  = $GLOBALPARAM{'CMD_UNZIP'};
	die "Can't find param : CMD_UNZIP" if (!$unzip);
	die "Can't find : $unzip" if (!-x $unzip);
	my $cmd = "(cd ${PWD}; /usr/bin/unzip -o ${WORK}/${fname})";
	my $buf = `$cmd`;
	if ($? != -1 && $? != 0) {
		die "Error : $? $!";
	}
	warn "Result : \n$buf";
	return(1);
}

# ライセンスファイルからライセンスチェックを行う
sub checkLicense {
	warn "[2] Check License ==========================\n";
	# ライセンスファイルがない場合
	if (!-f "$PWD/ssl/License.txt") {
		# WEBサービスでライセンスファイル取得
		warn "File not found : $PWD/License.txt. Resync from WEB Service.\n";
		my $res = getConfigFile('sslconf.zip');
		if (!$res) {
			die "REMHOST_LICENSE Web Service failed : $res";
		}
    }
    
	# ライセンスチェック
	# 失敗した場合はWEBサービスからライセンスファイルをリシンクし、再トライする。

	my $siteid = $GLOBALPARAM{'SITE_ID'};
	my $ckloop = 3;
	my $ckflg = 0;
	while ($ckloop > 0) {
		$ckloop --;
		$ckflg = 1;
		
		# ライセンスファイルの読み込み
		my %param;
		open(IN, "$PWD/ssl/License.txt") 
			|| die "Can't open file : $PWD/ssl/License.txt";
		while (<IN>) {
			next if ($_!~/(\w[^\s]*)\s*=\s*"([^"]*)"/);
			$param{$1} = $2;
		}
		close(IN);

		# ダイジェストキー取得
		my $md5 = Digest::MD5->new;
		$md5->add($param{'HOSTNAME'});
		$md5->add($param{'EXPIRE'});
		$md5->add($siteid);
		my $digest = $md5->hexdigest;

		# ライセンスキーチェック
		my $key = sprintf("[HOST=%s|EXPIRE=%s|CODE=%s]",
			$param{'HOSTNAME'}, $param{'EXPIRE'}, $param{'CODE'});

		if ($digest ne $param{'CODE'}) {
			sendErrorMessage(2, "License check error : [$key]");
			warn "License check error : $key\n";
			$ckflg = 0;
		}

		# ホスト名チェック
		if ($ckflg != 0 && $HOST ne $param{'HOSTNAME'}) {
			sendErrorMessage(2, "License check error : [HOST=$HOST][$key]");
			warn "License check error : [HOST=$HOST]\n$key\n";
			$ckflg = 0;
		}

		# 日付チェック
	    my ( $ss, $mm, $hh, $DD, $MM, $YY, $wday, $yday, $isdst ) = localtime();
	    my $dt = sprintf( "%04d%02d%02d", $YY + 1900, $MM + 1, $DD);
		if ($ckflg != 0 && $dt gt $param{'EXPIRE'}) {
			# 期限切れの場合は再度、WEBサービスでライセンスファイル取得
			sendErrorMessage(2, "License check error : [DATE=$dt][$key]");
			warn "License check error : [DATE=$dt]\n$key\n";
			$ckflg = 0;
		}
		if ($ckflg == 0) {
			warn "Resync from WEB Service.\n";
			my $res = getConfigFile('sslconf.zip');
			if (!$res) {
				sendErrorMessage(2, "REMHOST_LICENSE failed : $res");
				die "REMHOST_LICENSE Web Service failed : $res";
			}
		} else {
			warn "License check Ok : $key\n";
			last;
		}
	}
	return($ckflg);
}

# エラーログ初期化
sub initErrorLog {
	mkdir $WKLOG        if ( !-d "$WKLOG" );
	mkdir $OUT          if ( !-d "$OUT" );
	mkdir $WORK         if ( !-d "$WORK" );
	mkdir "$PWD/_bk"    if ( !-d "$PWD/_bk" );
	mkdir $BKLOG        if ( !-d "$BKLOG" );

	open( "LOG", ">>$WKLOG/stat_$STATID.log" )
		or die("Unable to open log: $!\n");
	carpout("LOG");
}

# プロセスの有無チェック。
# %PIDLISTリスト内のプロセスが1つでもあれば1を返す
sub checkCreatedProcess {
	# psコマンドでプロセスIDを取得
	my $ps  = $GLOBALPARAM{'CMD_PS'};
	die "Can't find param : CMD_PS" if (!$ps);
	die "Can't find : $ps" if (!-f $ps);
	my $cmd = "$ps -eo pid";
	warn "$cmd\n" if ($DEBUG);
	my @pslist = grep /([0-9]*)/, `$cmd`;

	# 取得したプロセスIDとプロセスリストのチェック
	my $res = 0;
	for my $pid(@pslist) {
		$pid=~s/[ |\n]//g;
		if ($PIDLIST{$pid}) {
			$res = 1;
			warn "[PID] $pid : $PIDLIST{$pid}\n" if ($DEBUG);
		}
	}

	return($res);
}

# %PIDLISTリスト内のプロセスの強制終了。
sub killProcess {
	warn "=== Kill Process ===========================\n";
	# psコマンドでプロセスIDを取得
	my $ps  = $GLOBALPARAM{'CMD_PS'};
	die "Can't find param : CMD_PS=/bin/ps" if (!$ps);
	die "Can't find : $ps" if (!-f $ps);
	my $cmd = "$ps -eo pid";
	my @pslist = grep /([0-9]*)/, `$cmd`;

	# 取得したプロセスIDとプロセスリストのチェック
	my $res = 0;
	for my $pid(@pslist) {
		chop($pid);
		# 該当の プロセスID を kill
		if ($PIDLIST{$pid}) {
			warn "kill 'HUP', $pid\n";
			kill 'HUP', $pid;
			$res = -1 if ($?);
		}
	}

	return($res);
}

# 開始・停止モードのチェック。
# 引数があれば"startStop.txt"にモードを記録する。ない場合は逆に
# "startStop.txt"を読み込み結果を返り値に返す。
sub checkMode {
	my ($stat) = @_;
	
	if ($stat) {
		open(OUT, ">$PWD/startStop.txt") 
			|| die "Can't open file : $PWD/startStop.txt";
		my $buf = sprintf("START_STOP_MODE=\"%s\"", $stat);
		print OUT $buf;
		warn "Write $PWD/startStop.txt : $stat\n";
	} else {
		open(IN, "$PWD/startStop.txt") 
			|| die "Can't open file : $PWD/startStop.txt";
		while (<IN>) {
			next if ($_!~/(\w[^\s]*)\s*=\s*"([^"]*)"/);
			$stat = $2 if ($1 eq 'START_STOP_MODE');
		}
		close(IN);
	}
	return($stat);
}

# ディスク容量のチェック
sub checkDiskUtil {
	my ($msg) = @_;
	my $ret = 0;

	# Windowsの場合は何もしない(将来実装予定)
	return ($ret) if ($ENV{'OS'}=~/Windows/);
	
	# ディスク使用量のチェック
	my $capacity = $GLOBALPARAM{'MIN_DISK_CAPACITY'};
	if (!$capacity) {
		warn "Can't find param : MIN_DISK_CAPACITY, using 100\n";
		$capacity = 100;
	}
	my $limit = int(1024 * $capacity);

	# dfコマンドでディスク使用量を取得
	my $df  = $GLOBALPARAM{'CMD_DF'};
	die "Can't find param : CMD_DF" if (!$df);
	die "Can't find : $df" if (!-f $df);
	my $cmd = "$df -k $PWD";
	my @dflist = `$cmd`;
	for my $dfline(@dflist) {
		chop($dfline);
		next if ($dfline!~/\s*\d*\s*\d*\s+(\d*)\s*\d*%/);
		if ($1 < $limit) {
			$$msg = "Disk Free is low : $1 KB (MIN : $limit).";
			last;
		} else {
			$ret = 1;
		}
	}
	return ($ret);
}

# ログの削除
sub deleteLog {
	warn "[4] Delete Log =============================\n";

	my $rmdir = $GLOBALPARAM{'CMD_RMDIR'};
	die "Can't find param : CMD_RMDIR" if (!$rmdir);

	my $saveday = $GLOBALPARAM{'SAVEDAYS'};
	if (!$saveday) {
		warn "Can't find param : SAVEDAYS, using 1\n";
		$saveday = 1;
	} else {
		warn "SAVEDAYS[$saveday]\n";
	}

	# 日付チェック
	my $times = time() - $saveday * 24 * 3600;
	my ( $ss, $mm, $hh, $DD, $MM, $YY, $wday, $yday, $isdst ) = 
		localtime($times);
	my $dt = sprintf("%04d%02d%02d", $YY + 1900, $MM + 1, $DD);

	# 削除対象ディレクトリチェック
	my $odir = sprintf("%s/%s/", $OUT, $STATID);
	
	# ディレクトリがなければ何もせずに戻る
	return(0) if (!-d $odir);

	opendir( DIR, $odir ) || die "Can't open dir $odir : $!";
	my @dates = sort grep /^\d+$/, readdir(DIR);
	closedir(DIR);
	
	# 削除対象ディレクトリ抽出
	my @target;
	my $cnt = 0;
	for my $date(@dates) {
		warn "Check [$date][$dt]\n" if ($DEBUG);
		next if ($date gt $dt);
		$cnt ++;
		push( @target, $date);
		
		# 100件ずつ削除
		if ((my $n = scalar(@target)) >= 100) {
			my $cmd;
			if ($ENV{'OS'}=~/Windows/) {
				$odir=~s/\//\\/g;
				$cmd  = "cd $odir\n";
				$cmd .= "$rmdir " . join(' ', @target) . "\n";
				open(OUT, ">$WORK/rm_$STATID.bat");
				print OUT $cmd;
				close(OUT);
				warn "Exec\n$cmd\n" if ($DEBUG);
				$WORK=~s/\//\\/g;
				my $buf = `$WORK\\rm_$STATID.bat`;
				warn "Result:\n $buf\n" if ($DEBUG);
			} else {
				$cmd  = "(cd $odir; $rmdir " . join(' ', @target) . ")";
				warn "Exec $cmd\n" if ($DEBUG);
				system($cmd);
			}
			warn "Delete $target[0]\n";
			@target = ();
		}
	}

	# 残りのディレクトリを削除
	if (scalar(@target) > 0) {
		my $cmd;
		if ($ENV{'OS'}=~/Windows/) {
			$odir=~s/\//\\/g;
			$cmd  = "cd $odir\n";
			$cmd .= "$rmdir " . join(' ', @target) . "\n";
			open(OUT, ">$WORK/rm_$STATID.bat");
			print OUT $cmd;
			close(OUT);
			warn "Exec1 $cmd\n" if ($DEBUG);
			$WORK=~s/\//\\/g;
			my $buf = `$WORK\\rm_$STATID.bat`;
			warn "Result:\n $buf\n" if ($DEBUG);
		} else {
			$cmd  = "(cd $odir; $rmdir " . join(' ', @target) . ")";
			warn "Exec\n$cmd\n" if ($DEBUG);
			my $buf = `$cmd`;
		}
		warn "Delete $target[0]\n";
	}

	warn "Deleted target : $cnt ( < $dt)\n";
}

# 性能データ採取コマンド制御
sub runMonitorProcess {
	warn "[3] Exec Monitor Process ===================\n";

	# 日付チェック
	my ( $ss, $mm, $hh, $DD, $MM, $YY, $wday, $yday, $isdst ) = 
		localtime();
	my $date = sprintf("%04d%02d%02d", 1900 + $YY, $MM + 1, $DD);
	my $time = sprintf("%02d%02d", $hh, $mm);
	my $dt = $date . '_' . $time;
	
	# モニタリングコマンド内のパス設定
	my $ODIR   = sprintf("%s/%s/%s/%s", $OUT, $STATID, $date, $time);
	my $SCRIPT = sprintf("%s/script", $PWD);

	# Windowsの場合はパス名変換
	if ($ENV{'OS'}=~/Windows/) {
		$ODIR=~s/\//\\/g;
		$SCRIPT=~s/\//\\/g;
	}
	
	# 出力先ディレクトリが存在しない場合は作成
	my $path = sprintf("%s/%s/%s", $OUT, $STATID, $date);
	mkdir($path) if (!-d $path);
	mkdir("$path/$time") if (!-d "$path/$time");

	# モニタリングコマンド起動
	my @scmd = split(/\n/, $STATPARAM{'STATCMD'});

	# 平行実行モードの場合は複数の子プロセスが同時にコマンド実行
	warn "STATMODE[$STATPARAM{'STATMODE'}]\n";
	warn "STATSEC[$STATPARAM{'STATSEC'}]\n";
	if ($STATPARAM{'STATMODE'} eq 'concurrent') {
		for my $cmd ( @scmd ) {
			$cmd=~s/_cwd_/$SCRIPT/g;
			$cmd=~s/_odir_/$ODIR/g;

			my $cid = fork();
			if ( $cid == 0 ) {
				warn "Execute($$) $cmd\n";
				my $res = system($cmd);
				if ($res == 0) {
					warn "Finish ($$) RES=$res OK\n";
				} else {
					warn "Finish ($$) RES=$res $!\n";
				}
				exit;
			}
			else {
				$PIDLIST{$cid} = $cmd;
			}
		}
	# 順序実行モードの場合は1つの子プロセスが順に実行
	} elsif ($STATPARAM{'STATMODE'} eq 'serial') {
		my $cid = fork();
		if ( $cid == 0 ) {
			for my $cmd ( @scmd ) {
				$cmd=~s/_pwd_/$SCRIPT/g;
				$cmd=~s/_odir_/$ODIR/g;

				warn "Execute($$) $cmd\n";
				my $res = system($cmd);
				warn "Finish ($$) RES=$res\n";
			}
			exit;
		} else {
			$PIDLIST{$cid} = 'all_cmd';
		}
	} 

	# 子プロセス起動後のプロセス監視
	my $interval = 5;
	my $moncnt = int(1.0 * $STATPARAM{'STATSEC'} / $interval);
	$moncnt = 1 if ($moncnt == 0);
	my $res = 1;
	for my $cnt(1..$moncnt) {
		$res = checkCreatedProcess();
		last if ($res == 0);
		if (checkMode() ne 'START') {
			warn "Error : startStop.txt : START_STOP_MODE isn't \"START\"";
			last;
		}
		sleep($interval);
	}

	warn("[5] Terminate Monitor Process ==============\n");
	# タイムアウト処理(子プロセスの強制終了)
	if ($res == 1) {
		killProcess();
	}

	return($dt);
}

# 指定ディレクトリをzip圧縮
sub zipLog {
	my ($dt) = @_;
	
	warn("[6] Archive log files ======================\n");
	# 入出力ファイル設定
	my ($date, $time) = split(/_/, $dt);
	my $ifile = sprintf("%s/%s/%s", $STATID, $date, $time);
	my $ofile = sprintf("arc_%s__%s_%s.zip", $HOST, $STATID, $dt);

	# 実行コマンドの起動方法が相対パスなのか絶対パスなのかで
	# zipファイルのパスの指定を変更する
	my $opath ;
	if ($PWD=~/^\./) {
		$opath = "../_bk/$STATID";
	} else {
		$opath = $BKLOG;
	}

	# zipコマンドで圧縮
	my $zip  = $GLOBALPARAM{'CMD_ZIP'};
	die "Can't find param : CMD_ZIP" if (!$zip);
	die "Can't find : $zip" if (!-f $zip);

	my $buf;
	if ($ENV{'OS'}=~/Windows/) {
		my $cmd  = "cd $OUT\n";
		$cmd    .= "$zip -r $opath/$ofile $ifile";
		$cmd=~s/\//\\/g;
		open(OUT, ">$WORK/zip_$STATID.bat");
		print OUT $cmd;
		close(OUT);
		warn "Exec1 $cmd\n" if ($DEBUG);

		my $cmd = "$WORK/zip_$STATID.bat";
		$cmd=~s/\//\\/g;
		warn "Exec2 $cmd\n" if ($DEBUG);
		$buf = `$cmd`;
	} else {
		my $cmd = "(cd $OUT; $zip -r $opath/$ofile $ifile)";
		warn "Exec\n$cmd\n" if ($DEBUG);
		warn("Execute $cmd\n");
		$buf = `$cmd`;
	}

	if ($? != -1 && $? != 0) {
		die "Error : $? $!";
	}
	warn "Result : \n$buf";
	
	return($ofile);
}

# リモートホストのファイル送信サービスの予約をする
sub reserveFileSender {
	my ($onOff) = @_;

	# URLとSiteIDをParam.iniから読み込み
	my $url    = $GLOBALPARAM{'URL_PM_SERVICE'};
	die "Can't find param : URL_PM_SERVICE" if ($url eq '');
	my $siteid = $GLOBALPARAM{'SITE_ID'};
	die "Can't find param : SITE_ID" if ($siteid eq '');

	my $key = sprintf("[URL=%s]\n[siteid=%s|HOST=%s]", $url, $siteid, $HOST);
	my $timeout = 10;

	# WSDLの指定
	if ($onOff eq 'ON') {
		# ファイル送信予約(失敗した時は2回リトライ)
		my $loopcnt = 3;
		while ($loopcnt > 0) {
			$loopcnt --;
			my $res = SOAP::Lite 
				-> uri('http://perf.getperf.co.jp')
				-> proxy($url)
				-> reserveSendPerfData($siteid, $HOST, $onOff)
				-> result;
			if ($res == 0) {
				# 予約完了
				warn "Reserve Ok\n";
				return(1);
			} elsif ($res > 0) {
				# 予約待ち
				warn "Reserve Wait[$timeout] : $key\n";
				sleep($timeout);
			} else {
				# それ以外(エラー)
				die "Reserve Error[$res] : $key";
			}
		}
	} elsif ($onOff eq 'OFF') {
		# ファイル送信予約解除
		my $res = SOAP::Lite 
			-> uri('http://perf.getperf.co.jp')
			-> proxy($url)
			-> reserveSendPerfData($siteid, $HOST, $onOff)
			-> result;
		if ($res eq 'Ok') {
			# 予約解除完了
			warn "UnReserve Ok\n";
			return(1);
		} else {
			# それ以外(エラー)
			die "UnReserve Error[$res] : $key";
		}
	}

	return(0);
}

# 未送信ログを抽出し送信する
sub checkZipLogs {

	warn("[7] Check Unsended log files ===============\n");
	# 保存期間のリミットファイルのチェック
	my $savemin = $GLOBALPARAM{'FILERECEIVE_BUFFERTIME'};
	my $times = time() - $savemin * 60;
	my ( $ss, $mm, $hh, $DD, $MM, $YY, $wday, $yday, $isdst ) = 
		localtime($times);
	my $limfile = sprintf("arc_%s__%s_%04d%02d%02d_%02d%02d%02d.zip",
		$HOST, $STATID, $YY + 1900, $MM + 1, $DD, $hh, $mm, $ss);

	warn "limfile [$limfile]" if ($DEBUG);
	# lastzip.txt から最後に転送したファイル名を読み込む
	my $lastzip;
	my $lastzipfile = sprintf("%s/lastzip_%s_%s.txt", $BKLOG, $STATID, $HOST);
	if (-f "$lastzipfile") {
		open(IN, "$lastzipfile") || die "Can't open file : $lastzipfile";
		$lastzip = <IN>;
		close(IN);
	} 
	$lastzip = $limfile if ($lastzip eq '');
	warn "lastzip [$lastzip]\n";

	# ~mon/_bkからzipファイルリスト読み込み
	opendir( DIR, $BKLOG ) || die "Can't open dir $BKLOG : $!";
	my @ziplist = sort grep /^arc_$HOST.*\.zip/, readdir(DIR);
	closedir(DIR);
	
	# 未送信ログリストの抽出
	my @target = ();
	for my $zip(@ziplist) {
		$zip=~s/\n$//g;			# 改行がある場合は除く
		my $zippath = "$BKLOG/$zip";
		warn "Check [$zip]" if ($DEBUG);
		if ($zip lt $limfile) {
			# リミットファイルより古いファイルは無条件に削除
			unlink  $zippath || warn "Can't delete : $zippath\n";
		} elsif ($zip gt $lastzip) {
			# 未送信ログの再送実行
			push(@target, $zip);
		}
	}

	# ログリスト送信。失敗したら中断する。
	warn "[TARGET]\n" . join("\n", @target) . "\n";
	my $updatedzip = $lastzip;
	for my $zip(@target) {
		my $zippath = "$BKLOG/$zip";
		my $res = sendLog($zip);
		if ($res == 0) {
			# 成功したらログを削除
			warn "Send Ok : $zip\n";
			unlink  $zippath || warn "Can't delete : $zippath\n";
			$updatedzip = $zip;
		} else {
			# 失敗したらループを抜け中断する
			sendErrorMessage(2, "Send failed. stop sending : $zip\n");
			warn "Send failed. stop sending : $zip\n";
			last;
		}
	}
	warn "updatedzip [$updatedzip]" if ($DEBUG);

	# 送信できなかったログを再度ziplist.txtに登録
	open(OUT, ">$lastzipfile") ||
		die "Can't open file : $lastzipfile";
	print OUT $updatedzip;
	close(OUT);
}

# zipファイルをリモートホストに送信
sub sendLog {
	my ($file) = @_;
	
	warn("[8] Send log files =========================\n");
	if (!-f "$BKLOG/$file") {
		warn "Error: Can't find file : $BKLOG/$file\n";
		return 0;
	}

	# データ送信予約
	my $res = reserveFileSender('ON');
	if (!$res) {
		warn "STOP send [RC=$res] : $file\n";
		return 0;
	}

	# ファイル送信コマンド実行
	if (!sendData($file)) {
		warn "Error : [sendData] $file";
	}

	# データ送信予約解除
	return reserveFileSender('OFF');
}

# リモートホストにエラーメッセージを送信する
# level : [1]CRITICAL,[2]ERROR
sub sendErrorMessage {
	my ($level, $dt, $module, $text) = @_;

	# 自律モードの場合は何もしない
	return 0 if ($INDEPEND);

	# URLとSiteIDをParam.iniから読み込み
	my $url    = $GLOBALPARAM{'URL_PM_SERVICE'};
	die "Can't find param :  . '?wsdl'" if ($url eq '');
	my $siteid = $GLOBALPARAM{'SITE_ID'};
	die "Can't find param : SITE_ID" if ($siteid eq '');

	my $lvl_str = SOAP::Data->type(string => $level);

	my $key = sprintf("[URL=%s]\n[siteid=%s|HOST=%s]", $url, $siteid, $HOST);
	my $msg = join('|', ($dt, $module, $text));

	# WSDLの指定
	my $res;
	eval {
		$res = SOAP::Lite 
			-> uri('http://perf.getperf.co.jp')
			-> proxy($url)
			-> sendEventLog($siteid, $HOST, $lvl_str, $msg)
			-> result;
	};
	warn "Error:" . $@ if $@; 	

	if ($res eq 'Ok') {
		return 1;
	} else {
		warn "sendError Failed : $res : $key\n";
		return 0;
	}
}

# ログ蓄積ファイルをチェックし、サーバにログを送信する
sub checkLogMessage {
	my $res = -1;

	# ログの蓄積ファイルがある場合
	if (-f "$WORK/logmsg_$STATID.txt") {
		# 蓄積データを @msgs に読込む
		open(IN, "$WORK/logmsg_$STATID.txt") ||  die "ファイルを開けません :$!\n";
		my $msgs = <IN>;
		close(IN);

		# エラーレベル,時刻,モジュール,メッセージの4要素でない場合は終了
		my @msg = split("|", $msgs);
		return -1 if (scalar(@msg) != 4);
		
		# WEBサービスでメッセージをサーバに送信
		$res = sendErrorMessage(shift(@msg), shift(@msg), shift(@msg), shift(@msg));
		# 成功した場合は蓄積ファイル削除、失敗した場合は何もしない
		if ($res == 0) {
			unlink( "$WORK/logmsg_$STATID.txt" );
		}
	} 
	return $res;
}

# サーバにログ送信
sub sendLogMessage {
	my ($level, $module, $text) = @_;
	my $res = -1;

	# 現在時刻を取得
	my ( $ss, $mm, $hh, $DD, $MM, $YY, $wday, $yday, $isdst ) = localtime();
	my $dt = sprintf( "%04d/%02d/%02d %02d:%02d:%02d", 
		$YY + 1900, $MM + 1, $DD, $hh, $mm, $ss);

	# ログ蓄積ファイルをチェックして、蓄積ファイルがなければログ送信
	if (checkLogMessage()) {
		$res = sendErrorMessage($level, $dt, $module, $text);
		# 失敗したらログ蓄積ファイルに書き込み、終了する
		if (!$res) {
			my $line = join('|', ($level, $dt, $module, $text));
			open(OUT, ">$WORK/logmsg_$STATID.txt") ||  die "ファイルを開けません :$!\n";
			print OUT $line . "\n";
			close(OUT);
		}
	}
	return $res;
}

# リモートホストにデータを送信する
sub sendData {
	my ($fname) = @_;

	# URLとSiteIDをParam.iniから読み込み
	my $url    = $GLOBALPARAM{'URL_PM_SERVICE'};
	die "Can't find param :  URL_PM_SERVICE" if ($url eq '');
	my $siteid = $GLOBALPARAM{'SITE_ID'};
	die "Can't find param : SITE_ID" if ($siteid eq '');

	my $key = sprintf("[URL=%s]\n[siteid=%s|HOST=%s]", $url, $siteid, $HOST);

	# WSDLの指定
	my $ent = build MIME::Entity
	  Type        => "application/zip",
	  Encoding    => "base64",
	  Path        => "$BKLOG/$fname",
	  Filename    => $fname,
	  Id          => $fname,
	  Disposition => "attachment";

	my $res = SOAP::Lite
	  ->packager(SOAP::Lite::Packager::MIME->new)
	  ->uri('http://perf.getperf.co.jp')
	  ->parts([ $ent ])
	  ->proxy($url)
	  ->sendPerfData($siteid, "${HOST}__${STATID}", $fname)
	  ->result;

	if ($res eq 'Ok') {
		return 1;
	} else {
		warn "sendError Failed : $res : $key\n";
		return 0;
	}
}
