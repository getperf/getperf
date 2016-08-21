package Getperf::Command::Master::Linux;
use strict;
use warnings;
use Exporter 'import';

our @EXPORT = qw/alias_iostat alias_diskutil/;

our $db = {
	_node_dir => undef,
};

sub new {bless{},+shift}

sub alias_iostat {
	my ($host, $device) = @_;
	if ($device=~/^sd[a-z]$/ || $device=~/^dm-/) {
		return $device;
	}
	return;
}

sub alias_diskutil {
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
