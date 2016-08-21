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

use strict;

# replace with the actual test
use_ok("Getperf");
config('base')->add_screen_log;

 subtest 'container' => sub {
 	{
 		my $json = $FindBin::Bin . '/cacti_cli/view/_default/Linux.json';
		my $writer = file($json)->open('w') or die $!;
		my $data = '
[
   "hogehoge1",
   "hogehoge2"
]
';
		$writer->print($data);
		$writer->close;

      my $file = $FindBin::Bin . '/cacti_cli/analysis/ostrich/Linux/20150509/051000/vmstat.txt';
 		my $data_info = Getperf::Data::DataInfo->new(file_path => $file);
 		my $aggregator = Getperf::Aggregator->new();
 		ok $aggregator->run($data_info);
 		print "elapse=" . $aggregator->elapse_command . "\n";
 		ok $aggregator->flush();
 		
		my @lines = file($json)->slurp;
		is scalar(@lines), 5, "view config";
	}
};

done_testing;
