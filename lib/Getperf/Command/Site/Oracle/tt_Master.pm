package Getperf::Command::Master::Oracle;
use strict;
use warnings;
use Exporter 'import';

our @EXPORT = qw/alias_instance/;

our $db = {
	_node_dir => undef,
	instances => undef,
};

sub new {bless{},+shift}

sub alias_instance {
	my ($device) = @_;

	return ($device == '') ? undef : $device;
}

1;
