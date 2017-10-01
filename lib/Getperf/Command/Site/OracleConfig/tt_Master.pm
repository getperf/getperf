package Getperf::Command::Master::OracleConfig;
use strict;
use warnings;
use Exporter 'import';

our @EXPORT = qw/alias/;

our $db = {
	_node_dir => undef,
};

sub new {bless{},+shift}

1;
