package Getperf::Command::Master::Jvmstat;
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
    my ($args) = @_;

    my ($id, $text);
    if ($args=~m|-Dcatalina\.base=(.*?) -| || 
        $args=~m|-Dcatalina\.home=(.*?) -|) {
        # catalina.home=C:\Apache Group\tomcat\7\Tomcat7_101
        my $catalina_path = $1;
        my @paths = split(/\/|\\/, $catalina_path);
        my $catalina_base = pop(@paths);
        $text = "Apache Tomcat - ${catalina_base}";
        $catalina_base =~ s/(?:_|\/|-)(.)/\U$1/g;
        $catalina_base =~ s/\s+/_/g;
        $id   = "tomcat.${catalina_base}";

    } elsif ($args=~m|-Dwrapper.tra.file=(.*)$|) {
        # RTD_PreOperation_151003-Process_Archive-1.tra
        my $trafile = $1;
        $trafile=~s|.*/||g;
        if ($trafile=~/^(.+)_\d+-Process_Archive/) {
            my $tra = $1;
            $text = "Tibco BW - $tra";
            $id   = $tra;
        }
    }
    return ($id) ? {device => $id, device_text => $text} : undef;
}

1;
