use FindBin;
use lib "$FindBin::Bin/../lib";
use strict;
use Test::More;
use Getperf;
use Getperf::Config 'config';
use Getperf::Aggregator;
use Getperf::Container qw/command/;
use Getperf::Data::DataInfo;
use lib "$FindBin::Bin/lib";
use Getperf::Test::Initializer;

use strict;

# replace with the actual test
use_ok("Getperf");

subtest 'aggregator' => sub {
	{
		Getperf::Test::Initializer::reset_alanysis_dir;

		my $file = $FindBin::Bin . '/cacti_cli/analysis/ostrich/Linux/20150509/051000/vmstat.txt';
		ok my $data_info = Getperf::Data::DataInfo->new(file_path => $file);
 		my $site_info = $data_info->{site_info};
 		$site_info->switch_site_command_lib_link;
		ok my $aggregator = Getperf::Aggregator->new();
		ok $aggregator->run($data_info);
		ok $aggregator->flush();
		print "elapse=" . $aggregator->elapse_command . "\n";
	}
};

done_testing;
