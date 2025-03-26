package Getperf::Command::Master::OracleConf;
use strict;
use warnings;
use Exporter 'import';

our @EXPORT = qw/alias/;

our $db = {
	_node_dir => undef,
};

sub new {bless{},+shift}

1;
