package Getperf::Container;

use strict;
use warnings;
use Cwd;
use FindBin;
use Path::Class;
use Time::Moment;
use Data::Dumper;
use Time::HiRes;
use File::Path::Tiny;
use String::CamelCase qw(camelize decamelize);
use Object::Container::Exporter -base;
use DBI;
use parent qw(Class::Accessor::Fast);
use Getperf::Data::DataInfo;
use Getperf::Loader;

__PACKAGE__->mk_accessors(qw/data_info elapse_command step/);

our $VERSION = '0.01';

register cacti_db => sub {
    my $self = shift;

    my $sitekey   = undef;
    my $site_info = undef;
    if (my $site_home = dir($ENV{'SITEHOME'})) {
        my @site_dirs = @{$site_home->{dirs}};
        $sitekey      = $site_dirs[$#site_dirs];
        $site_info = Getperf::Data::SiteInfo->instance($sitekey, $site_home);
    }
    if (!$site_info) {
        return;
    }
    my $passwd = $site_info->{site_mysql_passwd};
    print "PASS:$sitekey,$passwd\n";
    DBI->connect("dbi:mysql:$sitekey", $sitekey, $passwd, {
        RaiseError        => 1,
        PrintError        => 0,
        mysql_enable_utf8 => 1,
    });
};

sub step {
	my $self = shift;
	return 60;
}

register command => sub {
	my $self = shift;
};

1;