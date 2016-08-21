#!/usr/bin/perl
use strict;
use utf8;
use Encode;
use Data::Dumper;
use Getopt::Long;

# ディレクトリの設定
my $SHOWVER   = 0;
my $COMMUNITY = 'public';
my $SNMP_VER  = '1';
my $NETWORK   = '';
my $DEVICES   = '';
my $INTERVAL  = 30;
my $NTIMES    = 11;
my $ODIR      = ".";
my $USAGE     = "get_snmp, version : 2.5.0(UNIX)\n" .
	"Usage : get_snmp.pl [--interval=i] [--ntimes=i] [--community=public] [--version=[1|2c|3]]\n" .
	"    [--switch=...] [--devices=1,2,5,...]\n";

GetOptions('--odir=s' => \$ODIR, '--help' => \$SHOWVER, 
	'--interval=i' => \$INTERVAL, '--ntime=i' => \$NTIMES,
	'--version=s' => \$SNMP_VER, '--community=s' => \$COMMUNITY, 
	'--switch=s' => \$NETWORK, '--devices=s' => \$DEVICES) || die $USAGE;

if ($SHOWVER) {
	print $USAGE ;
	exit 0;
}
mkdir($ODIR) if (!-d $ODIR);

my @devs = split(/,/, $DEVICES);
if ($NETWORK eq '' || scalar(@devs) == 0) {
	die $USAGE;
}

my $outpath = "$ODIR/get_snmp__$NETWORK.txt";
open OUT, ">$outpath" || die "Can't open $outpath : $@";
my @mibs = qw/ifOperStatus ifInOctets ifOutOctets
	ifInUcastPkts ifOutUcastPkts ifInNUcastPkts ifOutNUcastPkts
	ifInDiscards ifInErrors ifOutDiscards ifOutErrors/;
my $head = 'Date       Time     ID ' .
	join(' ', map { sprintf("%14s", $_) } @mibs);

my $ok = 1;
MONITOR:for my $count(1..$NTIMES) {
	print OUT $head . "\n";
	for my $id(@devs) {
		my ($ss, $mm, $hh, $DD, $MM, $YY, $wday, $yday, $isdst) = localtime();
		my $tms = sprintf("%04d/%02d/%02d %02d:%02d:%02d", 
				$YY + 1900, $MM + 1, $DD, $hh, $mm, $ss);

		my $cmd = "snmpget -c ${COMMUNITY} -v ${SNMP_VER} ${NETWORK} ";
		$cmd .= join(' ', map {$_ . ".$id"} @mibs);
		my %dat = ();
		open(IN , "$cmd|");
		while (<IN>) {
			chomp;
			# IF-MIB::ifOperStatus.5 = INTEGER: up(1)
			next if ($_!~/::(\S*)\.(\d+) = (.+?):\s+(.+?)$/);
			my ($oid, $device_id, $type, $value) = ($1, $2, $3, $4);
			$value = $1 if ($value=~/\((\d+)\)/);
			$dat{$oid} = $value;
		}
		close(IN);

		my $line = sprintf("%s %4d", $tms, $id);
		for my $mib(@mibs) {
			if (defined($dat{$mib})) {
	 			$line .= sprintf(" %14u", $dat{$mib});
			} else {
	 			$line .= sprintf(" %14s", 'NaN');
	 			$ok = 0;
			}
		}
		print OUT $line . "\n";
		last MONITOR if ($ok == 0);
	}
	sleep($INTERVAL) if ($count < $NTIMES);
}
close(OUT);
exit;

