use FindBin;
use lib "$FindBin::Bin/../lib";
use strict;
use Test::More;
use Data::Dumper;
use Getperf;
use Log::Handler app => "LOG";
use Getperf::Config 'config';
use Getperf::Aggregator;
use Getperf::Data::DataInfo;
use Time::HiRes;
use lib "$FindBin::Bin/lib";
use Getperf::Test::Initializer;

use strict;

# replace with the actual test
use_ok("Getperf");

subtest 'loader' => sub {
	{
		Getperf::Test::Initializer::reset_alanysis_dir;

		my $t = [Time::HiRes::gettimeofday()];
		my $file = $FindBin::Bin . '/cacti_cli/analysis/ostrich/Linux/20150509/051000/vmstat.txt';
		my $data_info = Getperf::Data::DataInfo->new(file_path => $file);
 		my $site_info = $data_info->{site_info};
 		$site_info->switch_site_command_lib_link;
		my $aggregator = Getperf::Aggregator->new();
		ok $aggregator->run($data_info);
		ok $aggregator->flush();

		print "Elapse:" . Time::HiRes::tv_interval($t) . "\n";
	}
};

done_testing;
