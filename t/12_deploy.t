use FindBin;
use lib "$FindBin::Bin/../lib";
use strict;
use Test::More;
use Path::Class;
use Getperf;
use Getperf::Config 'config';
use Getperf::Deploy;
use Getperf::Container qw/command/;
use lib "$FindBin::Bin/lib";
use Getperf::Test::Initializer;
use Data::Dumper;

use strict;

# replace with the actual test
use_ok("Getperf");

subtest 'deploy' => sub {
	{
		ok my $base = config('base');
		ok $base->{ws_apache_dir};
	}
	# {
	# 	ok my $deploy = Getperf::Deploy->new();
	# 	ok $deploy->config_apache;
	# }
	{
		ok my $deploy = Getperf::Deploy->new();
		ok $deploy->config_tomcat;
	}
};

done_testing;
