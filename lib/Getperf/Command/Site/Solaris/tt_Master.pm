package Getperf::Command::Master::Solaris;
use strict;
use warnings;
use Exporter 'import';

our @EXPORT = qw/alias_iostat alias_df_k/;

our $db = {
	_node_dir => undef,
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

	return if (!$mount);
	if ($mount eq '/') {
		return 'root';
	} elsif ($mount=~/\/(.*)$/) {
		$mount = $1;
		$mount =~s/\s+/_/g;
		$mount =~s/\//_/g;
		return $mount;
	} elsif ($mount=~/^(\w+):$/) {
		return $1;
	} else {
		return;
	}
}

1;
