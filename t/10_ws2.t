use FindBin;
use lib "$FindBin::Bin/../lib";
use strict;
use Test::More;
use Data::Dumper;
use Log::Handler app => "LOG";
use Getperf;
use Getperf::Config 'config';
use Time::HiRes;
use SOAP::Lite +trace => qw(debug);
#use SOAP::Lite;

use strict;

# replace with the actual test
use_ok("SOAP::Lite");
config('base')->add_screen_log;
#my $URL='http://localhost:8080/services/GetperfService';
my $URL='http://paas.moi:57000/getperf-ws-axis17-2.5/services/SimpleService';
#my $URL='http://localhost:8080/services/SimpleService';
#my $URL='http://paas.moi:8080/services/SimpleService';
my $msg = SOAP::Data->new(name => 'msg', value => 'test');

subtest 'basic' => sub {
	{
	my $res = SOAP::Lite 
		-> uri('http://perf.getperf.com')
		-> proxy($URL)
		-> helloService($msg)
		-> result;
	is $res, 'Hello 2 test1', 'hello';
	}
};

done_testing;
