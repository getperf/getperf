use FindBin;
use lib "$FindBin::Bin/../lib";
use strict;
use Test::More;
use Time::HiRes;
use File::Basename qw(dirname);
use Log::Handler app => "LOG";
use Getperf;
use Getperf::Aggregator;
use Getperf::Data::DataInfo;
use Getperf::Config 'config';
use lib "$FindBin::Bin/lib";
use Getperf::Test::Initializer;
use Data::Dumper;

use strict;
my $COMPONENT_ROOT = Path::Class::file(dirname(__FILE__) . '/..')->absolute->resolve->stringify;

# replace with the actual test
use_ok("Getperf");

subtest 'config' => sub {
	{
		Getperf::Test::Initializer::create_getperf_site_json('/home/getperf');
		config->remove('base');
		ok my $base = config('base');
		is ($base->{site_dir}, "/home/getperf", '/home/getperf');
	}
	{
		Getperf::Test::Initializer::create_getperf_site_json("$COMPONENT_ROOT/t");
		config->remove('base');
		ok my $base = config('base');
		is ($base->{site_dir}, "$COMPONENT_ROOT/t", 'test home');		
	}
};

subtest 'rsync' => sub {
	Getperf::Test::Initializer::create_getperf_rsync_json;
	config->remove('rsync');
	ok my $rsync = config('rsync');
	is ($rsync->{site}{GETPERF_RSYNC_SOURCE}, 'staging_data', 'rsync GETPERF_RSYNC_SOURCE');
	ok $rsync->{site};
};

subtest 'queue' => sub {
	Getperf::Test::Initializer::create_getperf_queue_json;
	config->remove('queue');
	ok my $queue = config('queue');
	is ($queue->{GETPERF_REDIS_HOST}, 'localhost', 'queue GETPERF_REDIS_HOST');
	ok $queue;
};

subtest 'loader' => sub {
	{
		ok my $base = config('base');
		my $file = $FindBin::Bin . '/cacti_cli/analysis/ostrich/Linux/20150509/051000/vmstat.txt';
		ok my $data_info = Getperf::Data::DataInfo->new(file_path => $file);
		is ($data_info->{absolute_storage_dir}, 
			"$FindBin::Bin/cacti_cli/storage", 
			'storage home');		
	}
};


subtest 'instance' => sub {
	&Getperf::Test::Initializer::create_getperf_site_json("$COMPONENT_ROOT/t");
	config->remove('base');
	ok my $base = config('base');
	is ($base->{home}, $Getperf::Config::GETPERF_HOME, 'default home');

	my $conf = "$FindBin::Bin/../config/getperf_site.json";
	if (-f $conf) {
		unlink $conf;
		print "rm $conf\n";
	}
	config->remove('base');
	ok my $base = config('base');
	is ($base->{home}, $Getperf::Config::GETPERF_HOME, 'default home2');
};

subtest 'siteinfo' => sub {
	&Getperf::Test::Initializer::create_getperf_site_json("$COMPONENT_ROOT/t");

	ok my @lists = Getperf::Config::read_sitekeys();
	# print Dumper(\@lists);
	ok my $site  = Getperf::Config::read_site_config('test1');
	unlink "$COMPONENT_ROOT/config/site/test1.bak";
	ok Getperf::Config::write_site_config('test1', $site);
	ok (-f "$COMPONENT_ROOT/config/site/test1.bak");
	ok my $site2 = Getperf::Config::read_site_config('test1');
	print Dumper($site2);

};

# subtest 'staging_data' => sub {
# 	for my $testid('cacti_cli', 'kawasaki') {
# 		config->remove('base');
# 		ok my $monitor   = Getperf::Monitor->new;
# 		$monitor->{sitekey} = $testid;
# 		ok my %zips      = $monitor->read_zips();
# 		ok my %lastzips  = $monitor->parse_lastzips(\%zips);
# 		ok scalar(keys %lastzips) > 0;
# 	#	print Dumper(\%lastzips);
# 		ok $monitor->save_lastzips(\%lastzips);
# 		ok my %lastzips2 = $monitor->read_lastzips();
# 		ok scalar(keys %lastzips2) > 0;
# 	#	print Dumper(\%lastzips2);
# 	}
# };

done_testing;
