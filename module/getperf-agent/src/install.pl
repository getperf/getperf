#!/usr/bin/perl
use strict;
use utf8;
use Encode;
use FindBin;
use Getopt::Long;

my $rc          = 0;
my $USER        = undef;
my $GPHOME      = undef;
my $MODULE      = 'getperf';
my $INSTALL_ALL = 0;
my @MODULES     = qw/getperf zabbix/;

my $USAGE   = "install.pl [--all|--module=s] [--user=s] [--home=s]\n";
GetOptions(
	'--all'      => \$INSTALL_ALL,
	'--module=s' => \$MODULE,
	'--user=s'   => \$USER,
	'--home=s'   => \$GPHOME,
) || die $USAGE;

&main();
exit(0);

##
# プリント出力
#
sub PutLine {
	my ($line, $noreturn) = @_;
	if ($^O eq 'solaris' || $^O eq 'freebsd') {
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

##
# メッセージを出力し、1行入力する
#
sub GetLine {
	my ($msg, $buf) = @_;

	my $line = $msg;
	$line .= ($$buf eq '')?' ':' [' . $$buf . '] ';
	if ($^O eq 'solaris' || $^O eq 'freebsd') {
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

##
# メイン
#
sub main {

	if (!defined($GPHOME)) {
		$GPHOME = `cd ${FindBin::Bin}/.. && pwd`;
		chomp($GPHOME);
	}
	if (!defined($USER)) {
		my @statinfo = stat "$GPHOME/bin/getperfctl";
		my @statinfo = stat $GPHOME;
		my $userId = $statinfo[4];
		$USER = getpwuid $userId;
	}
	
	my $yesno  = 'n';
	my @services = ($INSTALL_ALL) ? @MODULES : ($MODULE);
	my @scripts = map { "/etc/init.d/${_}agent" } @services;

	GetLine("Create the startup script with the following settings\n"
		. "Startup script : " . join(",", @scripts) . "\n"
		. "Agent home     : $GPHOME\n"
		. "Owner          : $USER\n"
		. "OK ?(y/n)", \$yesno);

	exit (-1) if ($yesno ne 'y');

	for my $service(@services) {
		open(IN,  "$GPHOME/bin/${service}agent") || die "Can't onen : $!";
		my $buf = '';
		while(<IN>) {
			my $line = $_;
			$line =~s/__PTUNE_HOME__/$GPHOME/g;
			$line =~s/__PTUNE_USER__/$USER/g;
			$buf .= $line;
		}
		close(IN);

		my $script = "/etc/init.d/${service}agent";
		open(OUT, ">$script") || die "Can't onen $script : $!";
		print OUT $buf;
		close(OUT);
		chmod( 0755, $script) || die "Can't chmod $script : $!";
		
		for my $rc(qw( rc0.d/K20 rc1.d/K20 rc2.d/S20 rc3.d/S20 rc4.d/S20 rc5.d/S20 rc6.d/K20)) {
			my $dest = "/etc/$rc${service}agent";
			if ($dest=~/^(.+)\//) {
				my $dest_dir = $1;
				next if (! -d $dest_dir);
			}
			next if (-f $dest);
			my $cmd  = "ln -s $script $dest";
			my $rc = system($cmd);
			if ($rc != 0) {
				die "Can't execute $cmd : exit $rc";
			}
		}
	}
}
