#!/bin/perl
use strict;
use warnings;

my $major_ver = 2;
my $build     = 4;
my @archs     = qw/CentOS6-x86_64 Ubuntu14-x86_64 Windows-Win32/;

for my $arch(@archs) {
	my $arch_dir  = "./update/$arch/$major_ver/$build";
	my $arch_file = "getperf-bin-$arch-$build.zip";
	my $arch_path = "$arch_dir/$arch_file";
	next if (-f $arch_path);
	print "Generate : $arch_path\n";
	system("mkdir -p $arch_dir");
	system("dd if=/dev/zero bs=1K count=1 of=$arch_path");	
}
