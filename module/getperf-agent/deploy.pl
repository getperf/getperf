#!/usr/local/bin/perl
use strict;
use utf8;
use Config;
use Encode;
use File::Spec;
use File::Copy;
#use File::Copy::Recursive qw(rcopy);
use File::Path qw/mkpath rmtree/;
use Data::Dumper;
use Getopt::Long;
use FindBin;
use lib "$FindBin::Bin";
use Agent;

my $rc      = 0;
my $URL_CM  = undef;
my $CACERT  = undef;
my $exe     = ($ENV{'OS'}=~/Windows/) ? ".exe" : "";
my $PWD     = $FindBin::Bin;
my $SRC     = "${PWD}/src";
my $exe     = ($ENV{'OS'}=~/Windows/) ? ".exe" : "";
my $DEST    = ($ENV{'OS'}=~/Windows/) ? 'c:\ptune\home' : $ENV{'HOME'};
my $CONF    = getOsname();

my $PACKAGE = $Agent::PACKAGE;
my $BUILD   = $Agent::BUILD;
my $MAJOR_VERSION = $Agent::MAJOR_VERSION;
my $OS_TAG  = getModuleTag();

my $USAGE   = "deploy.pl [--conf=s] [--dest=s] [--cacert=s] [--url=s]\n";
GetOptions(
	'--conf=s'   => \$CONF,
	'--dest=s'   => \$DEST,
	'--cacert=s' => \$CACERT,
	'--url=s'    => \$URL_CM,
) || die $USAGE;

GetLine("Enter the agent module destination", \$DEST);
if (!defined($CACERT)) {
	my $root_ca  = '/etc/getperf/ssl/ca/ca.crt';
	my $root_ca2 = 'src/conf/ssl/ca/ca.crt';
	$CACERT = $root_ca  if (-f $root_ca);
	$CACERT = $root_ca2 if (-f $root_ca2);

	GetLine("Enter the path to the CA certificate", \$CACERT);
}

if (!defined($URL_CM)) {
	$URL_CM = $Agent::URL_CM;
	GetLine("Enter the management Web service URL", \$URL_CM);
}
prepareGetperf();
prepareZabbix();
archiveGetperf();
exit;

##
# ディレクトリパスのセパレータをlinux,Windows環境に合わせて変換する
#
sub _r {
	my ($str) = @_;
	if ($ENV{'OS'}=~/Windows/) {
		$str=~s/\//\\/g;
	}
	return $str;
}

sub rcopy {
	my ($src, $dest) = @_;

	my $cmd = ($ENV{'OS'}=~/Windows/) ? 
		"xcopy /f /y /s ${src} ${dest}\\" : "cp -r ${src}/* ${dest}/";
	print $cmd . "\n";
	my $out = `$cmd`;
	my $rc  = $?;
	return ($rc == 0) ? 1 : 0;
}
	
##
# プリント出力
#
sub PutLine {
	my ($line, $noreturn) = @_;
	if ($^O eq 'solaris' || $^O eq 'freebsd') {
		$line = encode('euc-jp', $line);
	} elsif ($^O eq 'MSWin32') {
		$line = encode('cp932', $line);
	} else {
		$line = encode('utf-8', $line);
	}
	if ($noreturn) {
		print $line;
	} else {
		print $line . "\n";
	}
}

##
# メッセージを出力し、1行入力する
#
sub GetLine {
	my ($msg, $buf) = @_;

	my $line = $msg;
	$line .= ($$buf eq '')?' ':' [' . $$buf . '] ';
	if ($^O eq 'solaris' || $^O eq 'freebsd') {
		$line = encode('euc-jp', $line);
	} elsif ($^O eq 'MSWin32') {
		$line = encode('cp932', $line);
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

sub getOsname {
	my $tag = undef;	
	if ($^O eq 'linux') {
		$tag = 'linux';
	} elsif ($^O eq 'MSWin32') {
		$tag = 'win';
	} elsif ($^O eq 'solaris') {
		$tag = 'solaris';
	} else {
		die "Unkown os name : $^O";
	}
	return $tag;
}

##
# OS情報を取得してモジュールタグ情報生成(CentOS6-x86_64など)
#
sub getModuleTag {
	my $tag = undef;
	if ($^O eq 'MSWin32') {
		$tag = "Windows-MSWin32";
	} else {
		my $uname = `uname -a`;
		# Solaris,FreeBSD ディストリビューション
		if ($uname=~/^(\S+)\s+(\S+)\s+(\S+).+(x86_64|i386|amd64)/) {
			my ($os, $osver, $arch) = ($1, $3, $4);
			$osver = $1 if ($osver=~/^(\d+\.\d+)/);
			if ($os eq 'Linux') {
				my @lines = readpipe("lsb_release -a");
				for my $line(@lines) {
					chomp($line);
					# Distributor ID: CentOS
					# Release:        6.6
					$os    = $1 if ($line=~/^Distributor ID:\s+(.+?)$/);
					$osver = $1 if ($line=~/^Release:\s+(\d+)/);
				}
			}
			$tag = "${os}${osver}-${arch}";
		}
	}
	return $tag;
}

##
# OS情報を取得してZabbixアーカイブ名取得
#
sub getZabbixArchiveName {
	my ($agent_ver) = @_;

	my $tag = undef;
	if ($^O eq 'MSWin32') {
		$tag = "zabbix_agents_${agent_ver}.win.zip";
	} else {
		my $uname = `uname -a`;
		# UNIX ディストリビューション
		if ($uname=~/^(\S+)\s+(\S+)\s+(\S+).+(x86_64|i386|amd64|sparc)/) {
			my ($os, $osver, $arch) = ($1, $3, $4);
			if ($os eq 'Linux') {
				$arch  = 'amd64' if ($arch eq 'x86_64');
				$osver = "${1}_${2}" if ($osver=~/^(\d+)\.(\d+)\./);
				# set Kernel2.6, if the major version is more than 3
				$osver = '2_6' if ($osver=~/^[3-9]/);
				$tag = "zabbix_agents_${agent_ver}.linux${osver}.${arch}.tar.gz";
			} elsif ($os eq 'SunOS') {
				$arch  = 'amd64' if ($arch eq 'x86_64' || $arch eq 'i386');
				$osver = $2 if ($osver=~/^(\d+)\.(\d+)$/);
				$tag = "zabbix_agents_${agent_ver}.solaris${osver}.${arch}.tar.gz";
			}
		}
	}
	return $tag;
}

sub findMSWinZip {
	my $zipbin = 'c:\program files\7-zip\7z.exe';
	if (-f 'c:\program files\7-zip\7z.exe') {
		$zipbin = 'c:\program files\7-zip\7z.exe';
	} elsif (-f 'c:\program files (x86)\7-zip\7z.exe') {
		$zipbin = 'c:\program files (x86)\7-zip\7z.exe';
	} elsif (!-f $zipbin) {
		die "7-zip not found : $zipbin\nYou may download at 'http://www.7-zip.org/'\n";
		return;
	}
	return $zipbin;
}

##
# $SRC から $DEST にgetperfをデプロイする
#
sub prepareGetperf {
	# デプロイ先のディレクトリ構成
	my $getperf = _r("$DEST/ptune");
	my $bindir  = _r("$DEST/ptune/bin");
	my $confdir = _r("$DEST/ptune/conf");
	my $ssldir  = _r("$DEST/ptune/network");
	my $script  = _r("$DEST/ptune/script");
	my $srcdir;

	# 採取コマンド構成ファイルのコピー元
	# src/conf/{OS名}の下に配置
	my $config = _r( "$SRC/conf/${CONF}" );
	if ( ! -d $config ) {
		die "${config} not found";
	}

	# ディレクトリ作成
#	rmtree($getperf);
	for my $dir($bindir, $confdir, $ssldir, $script) {
		mkpath($dir)  if (!-d $dir);
	}
	for my $work(qw/_bk _log _wk/) {
		my $dir = _r("$DEST/ptune/$work");
		mkpath($dir)  if (!-d $dir);
	}

	# src/doc下のreadme.txtコピー
	copy( _r("${SRC}/doc/readme.txt"),    $getperf );

	# src下の実行バイナリのコピー
	for my $bin(qw/getperf getperfctl getperfsoap getperfzip logretrieve/) {
		copy( _r("${SRC}/${bin}${exe}"),     $bindir );
		chmod( 0755, _r("${bindir}/${bin}${exe}") );
	}
	if ($^O eq 'MSWin32') {
		copy( _r("${SRC}/gpfpanel${exe}"),     $bindir );
		chmod( 0755, _r("${bindir}/gpfpanel${exe}") );
	}
	
	# Windowsの場合は win32\bin下をコピー
	if ($^O eq 'MSWin32') {
		# for my $bin(qw/libeay32.dll msvcr120.dll ssleay32.dll zlib1.dll/) {
			# my $target = ($bin eq 'zip.exe') ? $DEST : $bindir;			
			rcopy( _r("${PWD}/win32/bin"), $bindir );
			chmod( 0755, _r("${bindir}/*") );
		# }
	}
	else {
	 	my $uname = `uname -a`;
	 	for my $bin(qw/getperf*.sh getperfagent install.pl/) {
	 		system ("cp ${SRC}/${bin}  ${bindir}");
	 	}

        # ldd コマンドからlibcryptoとlibsslのライブラリパスを探してコピーする
        # libcrypto.so.1.0.0 => /lib/x86_64-linux-gnu/libcrypto.so.1.0.0 (0x00007ffc25adf000)
        # libssl.so.1.0.0 => /lib/x86_64-linux-gnu/libssl.so.1.0.0 (0x00007ffc25880000)
		my @ldds = readpipe("ldd ${SRC}/getperfsoap 2>&1");
		for my $ldd(@ldds) {
			chomp($ldd);
			$ldd=~s/(\r|\n)//g;
			next if ($ldd!~/^\s+(libcrypto|libssl).* =>\s+(.+?)$/);
			my $lib = $2;
			$lib =~s/\(.+\)//g;
			system("cp ${lib} ${bindir}");
		}
		for my $bin(qw(getperf getperfctl getperfsoap getperfzip)) {
			system ("mv ${bindir}/${bin}    ${bindir}/_${bin}");
			system ("mv ${bindir}/${bin}.sh ${bindir}/${bin}");
		}
		for my $bin(qw(logretrieve)) {
			next if (! -f "${SRC}/${bin}");
			system ("mv ${SRC}/${bin}    ${script}/_${bin}");
			system ("cp ${SRC}/${bin}.sh ${script}/${bin}");
		}
	} 
	
	# スクリプトのコピー
	rcopy( _r("${SRC}/script"),        _r("${getperf}/script") );

	# 設定ファイル getperf.ini のコピー
	if (!-f "${getperf}/getperf.ini") {
		copy( _r("${SRC}/conf/${CONF}/getperf.ini"),    $getperf );
	}
	
	# 設定ファイル getperf_ws.ini のコピー
	open (IN , "${SRC}/conf/${CONF}/getperf_ws.ini") || die "$!";
	my @buf = map { $_=~s/__URL_CM__/$URL_CM/g; $_ } <IN>;
	close(IN);
	my $outifile = "$ssldir/getperf_ws.ini";
	open (OUT, ">$outifile") || die "Can't open $outifile : $!";	#'
	print OUT @buf;
	close(OUT);
	
	# 設定ファイル conf/{カテゴリ}.ini のコピー
	copy( _r("${SRC}/conf/${CONF}/conf/HW.ini"), _r("${getperf}/conf/HW.ini") );

	# CA証明書のコピー
	if (defined($CACERT)) {
		die "not found : $CACERT" if (! -f $CACERT );
		copy( $CACERT, $ssldir );
	}
}

##
# $SRC から $DEST にgetperfをデプロイする
#
sub prepareZabbix {

	my $zabbix_home = _r("$DEST/ptune");
	my $zabbix_var  = _r("$PWD/var/zabbix");
	if (! -f "$zabbix_var/Recipe.pl") {
		return;
	}
	my $zabbix_config = do "$zabbix_var/Recipe.pl" or die "$!$@";
	if ($zabbix_config->{GETPERF_AGENT_USE_ZABBIX} != 1) {
		return;
	}

	# Extract 'zabbix_agents_{ver}.{os_destribution}.tar.gz'
	my $zabbix_archive = getZabbixArchiveName($zabbix_config->{ZABBIX_AGENT_VERSION});
	if (!$zabbix_archive) {
		return;
	}
	my $zabbix_archive_path = "$zabbix_var/$zabbix_archive";
	if (!-f $zabbix_archive_path) {
		die "not found : '$zabbix_archive_path'";
	}

	my $buf = undef;
	chdir $zabbix_home;
	if ($^O eq 'MSWin32') {
		my $zipbin  = findMSWinZip();
		my $command = "\"${zipbin}\" x";
		$command   .= " -y -o" . _r($zabbix_home);
		$command   .= " " . _r($zabbix_archive_path);
		print "$command\n";
		$buf = `$command`;
	} else {
		$buf = `gzip -cd ${zabbix_archive_path} | tar xvf -`;
	}
	if ($? != 0) {
		die "unzip error '$buf' $@ : exit $?";
	}

	# Remove default zabbix config file from conf directory
	if ($^O eq 'MSWin32') {
		{
			my $command = "del /Q " . _r("$zabbix_home/conf/zabbix*");
			print $command . "\n";
			$buf = `$command`;
			if ($? != 0) {
				die "error '$buf' $@ : exit $?";
			}
		}
		if ( -d "$zabbix_home/conf/zabbix_agentd" ) {
			my $command = "rmdir /S /Q " . _r("$zabbix_home/conf/zabbix_agentd");
			print $command . "\n";
			$buf = `$command`;
			if ($? != 0) {
				die "error '$buf' $@ : exit $?";
			}
		}
	} else {
		$buf = `rm -r $zabbix_home/conf/zabbix*`;		
		if ($? != 0) {
			die "error '$buf' $@ : exit $?";
		}
	}

	# Directory copy '{getperf_home}/lib/agent/Zabbix/{os}'
	my $script_dir = _r("$PWD/var/");
	$script_dir   .= ($^O eq 'MSWin32') ? 'win' : 'unix';
	print "rcopy $script_dir $zabbix_home\n";
	rcopy( _r($script_dir), _r($zabbix_home) );

	# Add package name of Zabbix
	$PACKAGE .= '-zabbix';
}

sub archiveGetperf {
	my $module_tag = getModuleTag();

	my $ext     = ($^O eq 'MSWin32') ? 'zip' : 'tar.gz';
	my $archive = "${PACKAGE}-Build${BUILD}-${module_tag}.${ext}";
	my $zipbin  = 'zip';
	if ($^O eq 'MSWin32') {
		$zipbin = findMSWinZip();
	} 
	my $zipcmd  = ($^O eq 'MSWin32') ? "\"${zipbin}\" a" : 'zip';

	if (!$module_tag) {
		die "Can't parse $module_tag";
	}

	# archive agent 
	{
		chdir("$DEST");
		my $command;
		if ($^O eq 'MSWin32') {
			$command = "${zipcmd} -r ${archive} ptune";
		} else {
			$command = "tar cf - ptune | gzip > ${archive}";
		}
		print "$command\n";
		my $buf = `$command`;
		if ($? != 0) {
			die "$@\n$buf";
		}
	}

	# archive agent update
	{
		my $update  = "getperf-bin-${module_tag}-${BUILD}.zip";
		my $update_target = "$DEST/update/$OS_TAG/$MAJOR_VERSION/$BUILD";
		my $update_dir  = _r($update_target);
		my $update_path = _r("$update_target/$update");
		if (!-d $update_dir) {
			my $mkdir = ($^O eq 'MSWin32') ? 'mkdir' : 'mkdir -p';
			system("$mkdir $update_dir");
		}
		chdir("$DEST/ptune");
		my $command = "$zipcmd -r ${update_path} bin";
		print "$command\n";
		my $buf = `$command`;
		if ($? != 0) {
			die "$@\n$buf";
		}
	}

	# package for '${getperf_home}/var/module'
	{
		chdir("$DEST");
		my $command = "$zipcmd -r upload_var_module.zip ${PACKAGE}-Build*.* update";
		print "$command\n";
		my $buf = `$command`;
		if ($? != 0) {
			die "$@\n$buf";
		}
	}

	chdir($PWD);
}

