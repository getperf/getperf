package Getperf::Command::Master::Oracle;
use strict;
use warnings;
use Path::Class;
use Exporter 'import';

our @EXPORT = qw/alias_instance/;

our $db = {
	_node_dir => undef,
	instances => undef,
};

sub new {bless{},+shift}

our $instances = {
    'K1RTD' => 'JIDOUKA',
    'K1STA' => 'JIDOUKA',
    'K1URA' => 'JIDOUKA',
};

sub alias_instance {
	my ($instance) = @_;

    if (my $site = $instances->{$instance}) {
        return $site;
    }
    my $site_home = $ENV{'SITEHOME'};
    if (my $site_home_dir = dir($site_home)) {
        my @site_dirs = @{$site_home_dir->{dirs}};
        my $sitekey = $site_dirs[$#site_dirs];
        return $sitekey;
    }
    return undef;
}

1;
