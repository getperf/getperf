#!/usr/local/bin/perl
use strict;
use File::Spec;
use File::Copy;
use File::Copy::Recursive qw(rcopy);
use File::Path qw/mkpath rmtree/;
use Test::More tests => 6;
use Data::Dumper;
use FindBin;
use Getopt::Long;
use Sys::Hostname;

my $CONF='conf';
my $USAGE   = "test_getperf.pl [--conf=...]\n";
GetOptions('--conf=s' => \$CONF) || die $USAGE;

sub _r {
	my ($str) = @_;
	if ($ENV{'OS'}=~/Windows/) {
		$str=~s/\//\\/g;
	}
	return $str;
}

my $rc  = 0;
my $exe = ($ENV{'OS'}=~/Windows/) ? ".exe" : "";
my $PWD = $FindBin::Bin;

$PWD     = File::Spec->rel2abs($PWD);
my $SRC  = "${PWD}/../src";
$SRC     = File::Spec->rel2abs($SRC);
my $TEST = ${PWD};
#$TEST    = File::Spec->rel2abs($TEST);
my $DEST = ($ENV{'OS'}=~/Windows/) ? 'c:\ptune' : $PWD;

main();
exit;

sub prepareHome {
	my $home    = _r("$DEST/home");
	my $bindir  = _r("$DEST/home/bin");
	my $arcdir  = _r("$DEST/home/_bk");
	my $confdir = _r("$DEST/home/conf");
	my $ssldir  = _r("$DEST/home/ssl");
	my $script  = _r("$DEST/home/script");
	my $script2 = _r("$DEST/home/script/PerfMon");
	my $srcdir;

	rmtree($home);
	mkpath($bindir);
	mkpath($confdir);
	mkpath($arcdir);
	mkpath($script);

	print "pwd:$PWD\n";
	$srcdir = ($ENV{'OS'}=~/Windows/) ? "$PWD/win" : "$PWD/cfg";
	print "srcdir:$srcdir\n";

	if ( ! -d "${srcdir}/${CONF}" ) {
		die "${srcdir}/${CONF} not found";
	}

	print "copy ${SRC}/getperf${exe}     $bindir" . "\n";
	copy( _r("${SRC}/getperf${exe}"),     $bindir );
	copy( _r("${SRC}/getperfctl${exe}"),  $bindir );
	copy( _r("${SRC}/getperfzip${exe}"),  $bindir );
	copy( _r("${SRC}/getperfsoap${exe}"), $bindir );
#print "copy " . _r("${TEST}/testcmd${exe}") . " $script\n"; exit;
	copy( _r("${TEST}/testcmd${exe}"),    $script );
	chmod( 0755, _r("${bindir}/getperf${exe}") );
	chmod( 0755, _r("${bindir}/getperfctl${exe}") );
	chmod( 0755, _r("${bindir}/getperfzip${exe}") );
	chmod( 0755, _r("${bindir}/getperfsoap${exe}") );
	chmod( 0755, _r("${script}/testcmd${exe}") );

	print "rcopy ${SRC}/script ${home}/script" . "\n";
	rcopy( _r("${SRC}/script"),           _r("${home}/script") );
	print "copy ${srcdir}/getperf.ini $home" . "\n";
	copy( _r("${srcdir}/getperf.ini"),    $home );
	print "copy ${srcdir}/getperf_ws.ini $home" . "\n";
	copy( _r("${srcdir}/getperf_ws.ini"), $home );
	print "copy ${srcdir}/${CONF} $confdir" . "\n";
	rcopy( _r("${srcdir}/${CONF}"),    $confdir );
	print "copy ${srcdir}/ssl $ssldir" . "\n";
	rcopy( _r("${srcdir}/ssl"),    $ssldir );
}

sub copySSLLicense {
	my $home    = "$PWD/home";
	my $srcdir;

	if ($ENV{'OS'}=~/Windows/) {
		$srcdir = "$PWD/win";
	} else {
		$srcdir = "$PWD/cfg";
	}

	rcopy( "${srcdir}/ssl", "${home}/ssl" );
}

# ダミー用アーカイブファイルの作成
# \_bk\arc_tsol406312__TEST_20111227_104211.zip
sub mkDummyArchive {
	my ($saveHour) = @_;

	my $host = hostname();
	$host=~s/\..*//g;
	$host=lc($host);

	my $currTime = time();
	for my $hour(1..$saveHour) {
		my $sec = $currTime - $hour * 3600;
		my ($ss, $mm, $hh, $DD, $MM, $YY, $wday, $yday, $isdst) = localtime($sec);
		my $tms = sprintf("%04d%02d%02d_%02d%02d%02d", 1900 + $YY, $MM + 1, $DD, $hh, $mm, $ss);
	
		my $zipFile = "arc_${host}__TEST_${tms}.zip";
		my $zipPath = "$DEST/home/_bk/${zipFile}";
		open( OUT, ">$zipPath") || die "open error[$zipPath] $?";
		print OUT "test\n";
		close( OUT );
	}
}

sub main {
	prepareHome();
	copySSLLicense();
#	mkDummyArchive(48);

	my $cmd = _r("$DEST/home/bin/getperf${exe} -c $DEST/home/getperf.ini -s TEST");
	print "$cmd\n";
#	$cmd = "valgrind -v  --leak-check=full --show-reachable=no --error-limit=no --leak-check=yes " . $cmd;
	my $cmd = _r("$DEST/home/bin/getperfctl${exe} setup -c $DEST/home/getperf.ini  --user test1 --pass test1 --key IZA5971");
	print "$cmd\n";
exit(0);
	my $pid = fork();
	if ( $pid == 0 ) {
		$rc = system($cmd);
		print "RC=$rc\n";
		exit(0);
	}

	sleep(30);
	$cmd = _r("${SRC}/getperf${exe} --stop -c $DEST/home/getperf.ini");
	$rc = system($cmd);
	print "RC=$rc\n";
	ok($rc == 0);

	if ($ENV{'OS'}=~/Windows/) {
		$cmd = "dir $DEST\\home\\log\\*\\*\\*";
	} else {
		$cmd = "ls -l $DEST/home/log/*/*/*";
	}
	print "$cmd\n";
	system($cmd);

}

