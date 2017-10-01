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
	# trim prefix word. 
	if ($host=~/^(.+)/) {
		$host=~s/^.+-//g;
		return $host;
	}
	return;
}

sub alias_network_port {
	my ($host, $device) = @_;
	if ($device=~/^(Ethernet|port-channel)/) {
		my $main_port = 0;
		if ($device=~m|Ethernet1/(\d+)$|) {
			my $port_id = $1;
			$main_port = 1 if ($port_id != 49 and $port_id != 50);
		}
		return {main_port => $main_port, device => $device};
	}
	return;
}

1;
