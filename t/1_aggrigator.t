use FindBin;
use lib "$FindBin::Bin/../lib";
use strict;
use Test::More;
use Log::Handler app => "LOG";
use Getperf;
use Getperf::Config 'config';
use Getperf::Aggregator;
use Getperf::Container qw/command/;
use Getperf::Data::DataInfo;
use Time::HiRes;
use lib "$FindBin::Bin/lib";
use Getperf::Test::Initializer;

use strict;

# replace with the actual test
use_ok("Getperf");
config('base')->add_screen_log;

subtest 'basic' => sub {
	{
		Getperf::Test::Initializer::reset_alanysis_dir;
		my $file = $FindBin::Bin . '/cacti_cli/analysis/ostrich/Linux/20150509/051000/vmstat.txt';
		my $data_info = Getperf::Data::DataInfo->new(file_path => $file);
		my $class_name = 'Base::' . $data_info->metric . '::' . $data_info->file_name;
		print $class_name . "\n";
		my $start_time = [Time::HiRes::gettimeofday()];
		command($class_name)->parse($data_info);
		my $diff = Time::HiRes::tv_interval($start_time);
		my @nodes = ();
		for my $metric(@{$data_info->metrics}) {
			if (defined($metric->devices)) {
				push(@nodes, {metric=>$metric->metric, devices=>$metric->devices});
			} else {
				push(@nodes, {metric=>$metric->metric});
			}
		}
		
		print "elapse=$diff\n";
		is  (scalar(@nodes), 1, 'node count');
	}
};

 subtest 'container' => sub {
 	{
 		my $file = $FindBin::Bin . '/cacti_cli/analysis/ostrich/Linux/20150509/051000/vmstat.txt';
 		my $data_info = Getperf::Data::DataInfo->new(file_path => $file);
 		my $site_info = $data_info->{site_info};
 		$site_info->switch_site_command_lib_link;
 		my $aggregator = Getperf::Aggregator->new();
 		ok $aggregator->run($data_info);
 		ok $aggregator->flush();
 		print "elapse=" . $aggregator->elapse_command . "\n";
		
	}
};

done_testing;
