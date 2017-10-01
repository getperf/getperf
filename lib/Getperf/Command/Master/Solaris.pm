package Getperf::Command::Master::Solaris;
use strict;
use warnings;
use Data::Dumper;
use Exporter 'import';

our @EXPORT = qw/alias_iostat alias_df_k/;
my %ignore_df_dirs = (
	devices  => 1,
	system   => 1,
	proc     => 1,
	etc      => 1,
	platform => 1,
	dev      => 1,
);

our $db = {
  '_node_dir' => {
    'test_a1' => 'test1'
  }
};

sub new {bless{},+shift}

sub alias_iostat {
	my ($host, $device) = @_;
	
	$device=~s/\(.+\)//g;
	$device=~s/[\/|:]/_/g;
	if ($device=~/^c\d/) {
		return $device;
	} 
	return;
}

sub alias_df_k {
	my ($host, $mount) = @_;

	my $alias = undef;
	return if (!$mount);
	if ($mount eq '/') {
		$alias = 'root';
	} elsif ($mount=~/^(\w+):$/) {
		$alias = $1;
	} elsif ($mount=~/^\/(.*)$/) {
		$mount = $1;
		my @paths = split('/', $mount);
		if (!exists($ignore_df_dirs{$paths[0]})) {
			$mount =~s/\s+/_/g;
			$mount =~s/\//_/g;
			$alias = $mount;
		}
	}
	return $alias;
}

1;
