#!/usr/local/bin/perl

use strict;



# パッケージ読込

BEGIN { 

    my $pwd = `dirname $0`; chop($pwd);

    push(@INC, "$pwd/libs", "$pwd/"); 

}

use Time::Local;

use Getopt::Long;



# 環境変数設定

$ENV{'LANG'}='C';

my $ODIR = $ENV{'PS_ODIR'} || '.';

my $IDIR = $ENV{'PS_IDIR'} || '.';

my $IFILE = $ENV{'PS_IFILE'} || 'vmstat.txt';



my %ref_param = (

'DEFAULT buffer cache' => 'default_buffer',

'KEEP buffer cache'    => 'keep_buffer',

'java pool'            => 'java_pool',

'keep_use_size'        => 'keep_use',

'large pool'           => 'large_pool',

'sga_max_size'         => 'sga_max',

'shared pool'          => 'shared_pool',

'db_cache_size'        => 'default_buffer',

'db_keep_cache_size'   => 'keep_buffer',

'java_pool_size'       => 'java_pool',

'keep_use_size'        => 'keep_use',

'large_pool_size'      => 'large_pool',

'shared_pool_size'     => 'shared_pool',

);



# 実行オプション解析

my $interval = 5;

GetOptions ('--interval=i' => \$interval,

	'--idir=s' => \$IDIR,

	'--ifile=s' => \$IFILE,

	'--odir=s' => \$ODIR);



# メイン

my ($MM, $DD, $YY) = ($1, $2, $3);



# ファイルオープン

my $ofile = "$ODIR/$IFILE";

my $infile = "$IDIR/$IFILE";



print "$infile\n";

print "$ofile\n";



open(IN, $infile) || die "Can't open infile. $!\n";



my ($tms, %data);

while (<IN>) {

	chop;

	# Date:06/07/29 13:00:01

	if ($_=~/^Date:(\d\d\/\d\d\/\d\d \d\d:\d\d:\d\d)$/) {

		$tms = $1;

		next;

	}

	if ($_=~/^(.*?),(.*?)$/) {

		my ($item, $val) = ($1, $2);

		my $key = $ref_param{$item};

		$data{$key} = $val;

	}

}

close(IN);



my @items = qw|keep_use sga_max keep_buffer default_buffer shared_pool large_pool java_pool|;

my $hd = "Date       Time     ";

for my $it (@items) {

	$hd .= sprintf(" %13s", $it);

}



open(OUT, ">$ofile") || die "Can't open outfile. $!\n";

print OUT $hd . "\n";

print OUT $tms;

for my $it (@items) {

	my $buf = sprintf(" %13d", $data{$it});

	print OUT $buf;

}

print OUT "\n";

close(OUT);

