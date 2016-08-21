use FindBin;
use lib "$FindBin::Bin/../lib";
use strict;
use Test::More;
use Data::Dumper;
use Log::Handler app => "LOG";
use Getperf;
use Getperf::Config 'config';
use Getperf::Aggregator;
use Getperf::Container qw/command/;
use Getperf::Data::DataInfo;
use Time::HiRes;

use strict;

# replace with the actual test
use_ok("Getperf");
config('base')->add_screen_log;

subtest 'basic' => sub {
	{
		my $file = $FindBin::Bin . '/cacti_cli/analysis/ostrich/Linux/20150509/051000/vmstat.txt';
		ok my $data_info = Getperf::Data::DataInfo->new(file_path => $file);
		my $class_name = 'Base::' . $data_info->metric . '::' . $data_info->file_name;
		is (command($class_name)->step(), 60, 'step');
	}
};

done_testing;
