package Getperf::Command::Master::SystemInfo;
use strict;
use warnings;
use Exporter 'import';

our @EXPORT = qw//;

our $db = {
	_node_dir => undef,
};

sub new {bless{},+shift}

1;
