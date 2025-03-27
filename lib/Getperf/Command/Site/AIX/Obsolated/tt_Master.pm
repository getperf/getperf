package Getperf::Command::Master::AIX;
use strict;
use warnings;
use Exporter 'import';

our @EXPORT = qw/alias/;

our $db = {
	_node_dir => undef,
};

sub new {bless{},+shift}

sub alias {
	my ($object, $instance) = @_;
	my $label = '';

	return $label;
}

1;
