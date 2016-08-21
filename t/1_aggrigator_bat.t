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
use Path::Class;
use Data::Dumper;

use strict;

# replace with the actual test
use_ok("Getperf");
config('base')->add_screen_log;
my $conf = config('base');

 subtest 'container' => sub {
 	{
 		my $json = $FindBin::Bin . '/cacti_cli/view/_default/Linux/ostrich.json';
 		unlink $json;
 		LOG->info("test");
		my $in_dir = my $file = $FindBin::Bin . '/cacti_cli/analysis/ostrich/Linux/20150509/051000/';
 		my $aggregator = Getperf::Aggregator->new();
      	for my $infile(qw/df_k.txt  iostat.txt  memfree.txt  net_dev.txt  vmstat.txt/) {
	      	my $file = $in_dir . $infile;
	 		my $data_info = Getperf::Data::DataInfo->new(file_path => $file);
	 		ok $aggregator->run($data_info);
	 		print "elapse=" . $aggregator->elapse_command . "\n";
      	}
      	$aggregator->flush();

		my @lines = file($json)->slurp;
		is scalar(@lines), 1, "view config";
	}
};

done_testing;
