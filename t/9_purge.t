use FindBin;
use lib "$FindBin::Bin/../lib";
use strict;
use Test::More;
use Data::Dumper;
use File::Basename qw(dirname);
use Getperf;
use Path::Class;
use Getperf::Monitor;
use Getperf::Extractor;
use lib "$FindBin::Bin/lib";
use Getperf::Test::Initializer;
use Getperf::Config 'config';
use Time::HiRes;
use Time::Moment;

use strict;
my $COMPONENT_ROOT = Path::Class::file(dirname(__FILE__) . '/..')->absolute->resolve->stringify;

subtest 'config' => sub {
	Getperf::Test::Initializer::create_getperf_site_json("$COMPONENT_ROOT/t");
	config->remove('base');
	my $site = Getperf::Data::SiteInfo->instance('site');
	ok $site->{purge_data_hour}{summary};
};

subtest 'extractor' => sub {
	Getperf::Test::Initializer::create_getperf_site_json("$COMPONENT_ROOT/t");
	config->remove('base');
	config->remove('rsync');
	&Getperf::Test::Initializer::reset_staging_dir;
	&Getperf::Test::Initializer::create_getperf_rsync_json;

	my $monitor = Getperf::Monitor->new;
	ok $monitor->rsync;

	my $site = Getperf::Data::SiteInfo->instance('site');
	my $zips = $monitor->{zips}{'site'};
	{
#		my $extractor = Getperf::Extractor->new(sitekey=>'site', zips=>$zips);
		my @zips = ('test');
		my $extractor = Getperf::Extractor->new(sitekey=>'site', zips=>\@zips);
		ok $extractor->unzip;
		$extractor->{timestamp} = Time::Moment->from_string('2014-10-09T15:05:00Z');
		ok $extractor->purge();
		ok (-d "$COMPONENT_ROOT/t/site/analysis/t00051900cap04/SCO23ELA/20141009/1410");
		$extractor->{timestamp} = Time::Moment->from_string('2014-10-09T16:05:00Z');
		ok $extractor->purge();
		ok !(-d "$COMPONENT_ROOT/t/site/analysis/t00051900cap04/SCO23ELA/20141009/1410");
	}
	{
#		my $extractor = Getperf::Extractor->new(sitekey=>'site', zips=>$zips);
		my @zips = ('test');
		my $extractor = Getperf::Extractor->new(sitekey=>'site', zips=>\@zips);
		ok $extractor->unzip;
		ok $extractor->purge();
	}
};

done_testing;
