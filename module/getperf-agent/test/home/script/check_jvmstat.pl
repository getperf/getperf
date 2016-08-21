#!/usr/bin/perl
use strict;
use utf8;
use Encode;
use Data::Dumper;
use Getopt::Long;

# ディレクトリの設定

my $SHOWVER = 0;
my $PWD     = GetAbsPath();
my $ODIR    = "${PWD}/../_wk/verify";
my $USAGE   = "check_jvmstat, version : 2.5.0(UNIX)\n" .
	"Usage : check_jvmstat.pl [--odir=...]\n";

GetOptions('--odir=s' => \$ODIR, '--version' => \$SHOWVER) || die $USAGE;

if ($SHOWVER) {
	print $USAGE ;
	exit 0;
}
mkdir($ODIR) if (!-d $ODIR);

# 入力変数

my %users = ();
my %hosts = ();
my %java_paths = ();

# メイン

if (checkRemoteHost() == 1) {
	$users{'__owner__'} = 1;
} else {
	checkSwitchUser();
}

checkJavaPathAndVersion();
verifyJps();
reportJps();

exit;

# リモートホストの実行変更チェック

sub checkRemoteHost {
	my $yesno = 'n';
	my $msg   = '';
	my $cmd   = '';

	# 実行ユーザの入力

	GetLine("リモートホスト経由のモニタリングを実行しますか", \$yesno);
	if ($yesno eq 'y') {
	
		PutLine("リモートホストのIPアドレス、ホスト名を入力して下さい");
		PutLine("(注)事前にリモートホスト側でjstatdデーモンの起動が必要です");
	
		$yesno = 'n';
		while($yesno ne 'y') {
			while (1) {
				my $host = '';
				$msg = "ホストを入力して下さい。終了時はRETURN";
				GetLine($msg, \$host);
				last if ($host eq '');
				if ($host=~/[\/|\s]/) {
					PutLine("${host} は適切なホスト名ではありません");
					next;
				}
				$hosts{$host} = 1;
			}
			$yesno = 'y';
			$msg = sprintf( "対象ホストは、%s ですね。よろしいですか?", join(",", keys(%hosts)));
			GetLine($msg, \$yesno);
			if ($yesno ne 'y') {
				%hosts = ();
			}
		}
	}

	return (%hosts)?1:0;
}

# 特定ユーザでの実行変更チェック

sub checkSwitchUser {
	my $yesno = 'n';
	my $msg   = '';
	my $cmd   = '';

	# 実行ユーザの入力

	GetLine("他のユーザにスイッチしてコマンドを実行しますか", \$yesno);
	if ($yesno eq 'y') {
	
		PutLine("実行ユーザを入力して下さい");
		PutLine("(注) 実行にはパスワードなしでスイッチユーザ出来るユーザでの実行が必要です");
		PutLine("     通常はrootを使用します");
	
		$yesno = 'n';
		while($yesno ne 'y') {
			while (1) {
				my $user = '';
				$msg = "ユーザを入力して下さい。終了時はRETURN";
				GetLine($msg, \$user);
				last if ($user eq '');
				$users{$user} = 1;
			}
	
			$yesno = 'y';
			$msg = sprintf( "実行ユーザは、%s ですね。よろしいですか?", join(",", keys(%users)));
			GetLine($msg, \$yesno);
		}
		
		# 実行ユーザでスイッチユーザできるかのチェック
		
		if (%users) {
			PutLine("スイッチユーザのテストをします。");
			for my $user(sort keys %users) {
				my $su_ok = '';
				$cmd = "su - $user -c '/bin/sh -c \"echo OK 2>1&\"'";
				PutLine($cmd, 1);
				my @buf = `$cmd`;
				$su_ok = pop(@buf);
				$su_ok =~ s/[\r\n]+//g;
				if ($su_ok ne 'OK') {
					PutLine("\n実行者はパスワード入力なしでスイッチユーザできる権限が必要です");
					die "Can't execute $cmd : $?\n";
				} 
				PutLine(" ... $su_ok");
			}
		}
	} else {
		$users{'__owner__'} = 1;
	}
}

# javaのパスとバージョンをチェック

sub checkJavaPathAndVersion {
	my $yesno = 'n';
	my $msg   = '';
	my $cmd   = '';
	for my $user(sort keys %users) {
		my $finish = 0;
		my $java_path = '';
		if ($user eq '__owner__') {
			PutLine("java実行パスを検索します");
			$cmd = "which java";
		} else {
			PutLine("$user ユーザのjava実行パスを検索します");
			$cmd = "su - $user -c '/bin/sh -c \"which java 2>1&\"'";
		}
		my @buf = `$cmd`;
		$java_path = pop(@buf);
		$java_path =~ s/[\r\n]+//g;
		if ($java_path ne '') {
			$yesno = 'y';
			GetLine("${java_path} が見つかりました。本パスを使用しますか", \$yesno);
			if ($yesno eq 'y') {
				$java_paths{$user}{$java_path}{flg} = 0;
				my $rc = checkJavaConfig($user, $java_path, $java_paths{$user}{$java_path});
				$java_paths{$user}{$java_path}{flg} = $rc;
				$yesno = 'n';
				GetLine("その他のパスも追加しますか", \$yesno);
				if ($yesno eq 'n') {
					$finish = 1;
				}
			}
		} else {
			PutLine("javaのパスが見つかりませんでした");
		}
		
		while($finish == 0) {
			$java_path = '';
			$msg = "javaの実行パスを入力して下さい\n終了する場合はENTER";
			GetLine($msg, \$java_path);
			last if ($java_path eq '');
			if ($java_path!~/\/java$/) {
				PutLine("${java_path} は適切なjavaパス名ではありません");
				next;
			}
			if (!-f $java_path) {
				PutLine("${java_path} が存在しませんでした");
				next;
			}
			$yesno = 'y';
			GetLine("本パスを使用しますか", \$yesno);
			if ($yesno eq 'y') {
				$java_paths{$user}{$java_path}{flg} = 0;
				my $rc = checkJavaConfig($user, $java_path, $java_paths{$user}{$java_path});
				$java_paths{$user}{$java_path}{flg} = $rc;
				$yesno = 'n';
				GetLine("その他のパスも追加しますか", \$yesno);
				if ($yesno eq 'n') {
					$finish = 1;
				}
			}
		}
	}
}

# jpsコマンドの検証

sub verifyJps {
	
	my $sfx = 1;
	for my $user (keys %java_paths) {
		for my $java (keys %{$java_paths{$user}}) {
			next if ($java_paths{$user}{$java}{flg} == 0);
			if (%hosts) {
				for my $host(keys %hosts) {
					execJps($java_paths{$user}{$java}, $user, $sfx, $host);
					$sfx ++;
				}
			} else {
				execJps($java_paths{$user}{$java}, $user, $sfx, undef);
				$sfx ++;
			}
		}
	}
}

# jpsコマンドの実行

sub execJps {
	my ($ref_java, $user, $sfx, $host) = @_;
	my $yesno = 'n';
	my $msg   = '';

	my $home = $ref_java->{home};
	my $jps  = $ref_java->{jps};

	# テスト名を"jps_{ユーザ名|ホスト名}_{サフィックス}"として設定
	my $test = "jps";
	if ($host ne undef) {
		PutLine("リモートホスト${host}をチェックします");
		my $rhost = $host;
		$rhost =~s/\./_/g;
		$test .= "_${rhost}";
	} elsif ($user eq '__owner__') {
		PutLine("${home}/bin/javaプロセスをチェックします");
	} else {
		PutLine("${user} オーナーの${home}/bin/javaプロセスをチェックします");
		$test .= "_${user}";
	}
	$test .= "_${sfx}";

	# コマンドオプション(-v ホスト名)を指定
	my $jps_opt = "-v";
	if ($host ne undef) {
		$jps_opt .= " ${host}";
	}

	# "JAVA_HOME="..." jps -v 1> "テスト.out" 2> "テスト.err""としてコマンド生成
	my $cmd = "\"${PWD}/get_jvmps.sh\" -j \"${home}\" -e \"${jps}\" -o \"${jps_opt}\" " .
		"1> \"${ODIR}/${test}.out\" 2> \"${ODIR}/${test}.err\"";

	if ($user ne '__owner__') {
		# 出力ファイルを事前作成して、オーナ変更
		my @ent = getpwnam ($user);
		if (@ent == 0) {
			die "can not get getpwnam[$user]";
		}
		for my $ofile(("${ODIR}/${test}.out", "${ODIR}/${test}.err")) {
			open(OUT,">$ofile") || die "Can't create : $@";
			close(OUT);
			chown($ent[2], $ent[3], $ofile) || die "Can't chwon : $@";
		}
		$cmd = "su - $user -c '${cmd}'";
	} 

	PutLine("EXEC[ $cmd ]");
	my $rc = system($cmd);
	my $msg = ($rc == 0)?'OK':'NG';
	PutLine("結果 : ${msg}");

	$ref_java->{$sfx}{cmd}  = $cmd;
	$ref_java->{$sfx}{out}  = "${test}.out";
	$ref_java->{$sfx}{err}  = "${test}.err";
	$ref_java->{$sfx}{host} = $host;
	$ref_java->{$sfx}{rc}   = $rc;
}

# jpsコマンドのレポート

sub reportJps {
	
	my $buf = '';
	my $sfx = 1;

	$buf = "user: \n";
	for my $user (keys %java_paths) {
		$buf .= "  ${user}:\n";
		for my $java (keys %{$java_paths{$user}}) {
			next if ($java_paths{$user}{$java}{flg} == 0);

			while (defined($java_paths{$user}{$java}{$sfx})) {
				my $ref_res = $java_paths{$user}{$java}{$sfx};
				my $test = sprintf("test%03d", $sfx);
				$buf .= "    ${test}: \n";
				$buf .= "      java: ${java}\n";
				$buf .= "      version: " . $java_paths{$user}{$java}{version} . "\n";
				$buf .= "      home: " . $java_paths{$user}{$java}{home} . "\n";
				$buf .= "      jps: " . $java_paths{$user}{$java}{jps} . "\n";
				$buf .= "      cmd: '" . $ref_res->{cmd} . "'\n";
				$buf .= "      rc: " . $ref_res->{rc} . "\n";
				if (defined($ref_res->{host})) {
					$buf .= "      host: " . $ref_res->{host} . "\n";
				}

				# jps出力結果をyaml形式に変換
				my $ofile = $ODIR . '/' . $ref_res->{out};
				if (-f $ofile) {
					open (IN, $ofile) || die "Can't open $ofile : $@";
					my @obuf = <IN>;
					close (IN);
					if (@obuf) {
						$buf .= "      out: |\n";
						@obuf = map { '        ' . $_ } @obuf;
						$buf .= join('', @obuf);
						$buf .= "\n";
					}
				}

				# jpsコマンド標準エラーをyaml形式に変換
				my $efile = $ODIR . '/' . $ref_res->{err};
				if (-f $efile) {
					open (IN, $efile) || die "Can't open $efile : $@";
					my @ebuf = <IN>;
					close (IN);
					if (@ebuf) {
						$buf .= "      err: |\n";
						@ebuf = map { '        ' . $_ } @ebuf;
						$buf .= join('', @ebuf);
						$buf .= "\n";
					}
				}
				$sfx ++;
			}
		}
	}
	print $buf;
	my $ofile = "$ODIR/ck_jvmstat.yaml";
	PutLine("${ofile}に検証結果を出力します");
	open (OUT, ">$ofile") || die "Can't open $ofile : $@";
	print OUT $buf;
	close(OUT);
}

# javaの構成チェック

sub checkJavaConfig {
	my ($user, $java_path, $java_conf) = @_;

	# JAVA ディレクトリの抽出
	my $java_home = $java_path;
	$java_home =~s/\/bin\/java$//g;
	$java_conf->{home} = $java_home;
	
	# JAVAバージョンのチェック
	my $cmd = '';
	if ($user eq '__owner__') {
		$cmd = "/bin/sh -c '${java_path} -version 2>&1'";
	} else {
		$cmd = "su - $user -c \"/bin/sh -c '${java_path} -version 2>&1'\"";
	}
	my $buf = '';
	$buf = `$cmd`;
	if ($buf eq '') {
		warn "ERROR : Can't exec $cmd $@";
	}
	my $version = '';
	if ($buf=~/java version "(.*?)"/) {
		$version = $1;
	} else {
		warn "ERROR : Can't check java ver";
	}
	$java_conf->{version} = $version;

	# jvmps,jpsのチェック
	my $jps_path = '';
	if ($version=~/^1\.[0-3]/) {
		warn "ERROR : jstat support java 1.4 later";
	} elsif ($version=~/^1\.4/) {
		$jps_path = "${PWD}/jvmstat/bin/jvmps";
	} elsif ($version=~/^1\./) {
		$jps_path = "${java_home}/bin/jps";
	} else {
		warn "ERROR : jstat not found";
	}
	if (-f $jps_path) {
		$java_conf->{jps} = $jps_path;
	} else {
		warn "ERROR : ${jps_path} not found";
	}
	if ($version ne '' && -f $jps_path) {
		return 1;
	} else {
		return 0;
	}
}

# プリント出力

sub PutLine {
	my ($line, $noreturn) = @_;
	if ($^O eq 'solaris') {
		$line = encode('euc-jp', $line);
	} else {
		$line = encode('utf-8', $line);
	}
	if ($noreturn) {
		print $line;
	} else {
		print $line . "\n";
	}
}

# メッセージを出力し、1行入力する

sub GetLine {
	my ($msg, $buf) = @_;

	my $line = $msg;
	$line .= ($$buf eq '')?' ':' [' . $$buf . '] ';
	if ($^O eq 'solaris') {
		$line = encode('euc-jp', $line);
	} else {
		$line = encode('utf-8', $line);
	}
	print $line;
	my $res = '';
	$res = <>;
	$res =~ s/[\r\n]+//g;	# chompの替わり
	if ($res ne '') {
		$$buf = $res;
	}
}

# 実行パスの絶対パスの取得

sub GetAbsPath {
	my $pwd_push = `pwd`; 
	$pwd_push =~ s/[\r\n]+//g;

	my $dirname = `dirname $0`;
	$dirname =~ s/[\r\n]+//g;

	chdir($dirname);
	my $pwd = `pwd`;
	$pwd =~ s/[\r\n]+//g;
	chdir($pwd_push);
	
	return $pwd;
}

