package Getperf::Command::Master::AIX;
use strict;
use warnings;
use Exporter 'import';

our @EXPORT = qw/alias_node_path alias alias_df_k/;

our $db = {
	_node_dir => undef,
};

sub new {bless{},+shift}

sub alias_node_path {
	my ($host) = @_;
    return "/SiView/$host";
}

sub alias {
	my ($object, $instance) = @_;
	my $label = '';

	return $label;
}

sub alias_df_k {
	my ($host, $mount) = @_;

	return if (!$mount);
	if ($mount eq '/') {
		return 'root';
	} elsif ($mount=~/^\/(devices|system|proc|etc|platform|dev)/) {
		return;
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
