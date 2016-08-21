use FindBin;
use lib "$FindBin::Bin/../lib";
use strict;
use Test::More;
use Data::Dumper;
use File::Basename qw(dirname);
use Getperf;
use Path::Class;
use Getperf::Monitor;
use lib "$FindBin::Bin/lib";
use Getperf::Test::Initializer;
use Getperf::Config 'config';
use Time::HiRes;

use strict;
my $COMPONENT_ROOT = Path::Class::file(dirname(__FILE__) . '/..')->absolute->resolve->stringify;

subtest 'basic' => sub {
	Getperf::Test::Initializer::create_getperf_site_json("$COMPONENT_ROOT/t");
	config->remove('base');
	config->remove('rsync');
	&Getperf::Test::Initializer::reset_staging_dir;
	&Getperf::Test::Initializer::create_getperf_rsync_json;
	my $monitor = Getperf::Monitor->new;
	ok $monitor->rsync;
	my @targets = ();
	for my $sitekey(keys %{$monitor->{zips}}) {
		my $zips = $monitor->{zips}{$sitekey};
		my $extractor = Getperf::Extractor->new(sitekey=>$sitekey, zips=>$zips);
		$extractor->unzip;
	}
};

# subtest 'keyword filter' => sub {
# 	&Getperf::Test::Initializer::purge_staging_data;
# 	my $monitor = Getperf::Monitor->new;
# 	ok $monitor->read_rsync_config;
# 	$monitor->{rsync_configs}{kawasaki}{GETPERF_RSYNC_ZIP_KEYWORD} = 'hoge';
# 	ok $monitor->rsync;
# };

done_testing;
