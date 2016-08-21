use FindBin;
use lib "$FindBin::Bin/../lib";
use strict;
use Test::More;
use Data::Dumper;
use File::Basename qw(dirname);
use Getperf;
use Getperf::Site;
use Getperf::Data::SiteInfo;
use Getperf::Config 'config';
use lib "$FindBin::Bin/lib";
use Getperf::Test::Initializer;

my $COMPONENT_ROOT = Path::Class::file(dirname(__FILE__) . '/..')->absolute->resolve->stringify;

# replace with the actual test
use_ok("Getperf");

subtest 'basic' => sub {
	config->remove('base');
	my $site_info = Getperf::Data::SiteInfo->get_instance_from_path($FindBin::Bin .'/cacti_cli/analysis/');
	is ($site_info->analysis, "$COMPONENT_ROOT/t/cacti_cli/analysis", 'get analysis');
};

# subtest 'virtual path' => sub {
# 	config->remove('base');
# 	%Getperf::Data::SiteInfo::instances = ();
# 	&Getperf::Test::Initializer::create_getperf_site_json('/home');

# 	my $site_info = Getperf::Data::SiteInfo->get_instance_from_path('site99/analysis/');
# 	is ($site_info->analysis, "/home/site99/analysis", 'get analysis');
# };

subtest 'instance' => sub {
	config->remove('base');
	%Getperf::Data::SiteInfo::instances = ();
	&Getperf::Test::Initializer::create_getperf_site_json('/home');
	# {
	# 	my %input_paths = (
	# 		"./t/site/analysis/agent/cat/20141006/135100/" => 'site',
	# 		"$COMPONENT_ROOT/t/site/analysis/agent/cat/20141006/135100/" => 'site',
	# 	);
	# 	for my $input_path(keys %input_paths) {
	# 		my $sitekey = $input_paths{$input_path};
	# 		my $site_info = Getperf::Data::SiteInfo->get_instance_from_path($input_path);
	# 		is ($site_info->analysis, "$COMPONENT_ROOT/t/$sitekey/analysis", $input_path);
	# 	}
	# }
	# {

	# 	my %input_paths = (
	# 		"site2/analysis/" => 'site2',
	# 		"site2/analysis/agent/cat/20141006/135100/" => 'site2',
	# 	);
	# 	for my $input_path(keys %input_paths) {
	# 		my $sitekey = $input_paths{$input_path};
	# 		my $site_info = Getperf::Data::SiteInfo->get_instance_from_path($input_path);
	# 		is ($site_info->analysis, "/home/$sitekey/analysis", $input_path);
	# 	}
	# }
	{	
		{
			my $site_info = Getperf::Data::SiteInfo->instance('site');
			is ($site_info->sitekey, 'site', 'get site_info : site');
		}
		{
			my $site_info = Getperf::Data::SiteInfo->instance('site2');
			is ($site_info->sitekey, 'site2', 'get site_info : site2');
		}
		{
			my $site_info = Getperf::Data::SiteInfo->instance('hoge');
		}
	}
	
};

subtest 'site_info' => sub {
	config->remove('base');
	%Getperf::Data::SiteInfo::instances = ();
	&Getperf::Test::Initializer::create_getperf_site_json("$COMPONENT_ROOT/t");
	&Getperf::Test::Initializer::create_getperf_site_home_json('/tmp/site/site1');
	{
		my $site_info = Getperf::Data::SiteInfo->instance('test1');
		is ($site_info->sitekey, 'test1', 'get site_info : test1');
		is ($site_info->analysis, '/tmp/test/analysis', 'get site_info : test1');
	}
	{
		my $site_info = Getperf::Data::SiteInfo->instance('test2');
		is ($site_info->sitekey, 'test2', 'get site_info : test2');
		is ($site_info->analysis, "$COMPONENT_ROOT/t/test2/analysis", 'get site_info : test2');
	}
};

subtest 'site_init' => sub {
	config->remove('base');
	%Getperf::Data::SiteInfo::instances = ();
	&Getperf::Test::Initializer::create_getperf_site_json("$COMPONENT_ROOT/t");

	{
		my $site = new Getperf::Site();
		ok $site->parse_command_option('/tmp/test20 --force');
		ok $site->run;	
	}

	# {
	# 	my $site = new Getperf::Site();
	# 	ok $site->parse_command_option('init /tmp/test20');
	# 	!ok $site->run;	
	# }
};

subtest 'switch' => sub {
	config->remove('base');
	my $site_info = Getperf::Data::SiteInfo->get_instance_from_path($FindBin::Bin .'/cacti_cli/analysis/');
	ok $site_info->switch_site_command_lib_link();
};

done_testing;
