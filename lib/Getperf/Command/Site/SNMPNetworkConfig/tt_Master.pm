package Getperf::Command::Master::SNMPNetworkConfig;
use strict;
use warnings;
use Exporter 'import';

our @EXPORT = qw/alias_network alias_network_port/;

our $db = {
	_node_dir => undef,
};

sub new {bless{},+shift}

sub alias_network {
	my ($host) = @_;

	return $host;
}

sub alias_network_port {
	my ($host, $device) = @_;

	return $device;
}

1;
