package Getperf::Command::Master::SystemInfo;
use strict;
use warnings;
use Exporter 'import';

our @EXPORT = qw/alias_host/;

our $db = {
	_node_dir => undef,
};

sub new {bless{},+shift}

sub alias_host {
	my ($host, $device) = @_;
	
	return $host;
}

1;
