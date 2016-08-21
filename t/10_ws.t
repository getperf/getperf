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
use SOAP::Lite::Packager;
use MIME::Entity;
use POSIX;

# replace with the actual test
use_ok("SOAP::Lite");

config('base')->add_screen_log;

my $URL  ='http://localhost:57000/getperf-ws/services/SimpleService';
my $URL2 ='http://localhost:57000/getperf-ws/services/GetperfService';

my $msg = SOAP::Data->new(name => 'msg', value => 'test');

subtest 'basic' => sub {
	{
	my $res = SOAP::Lite 
		-> uri('http://perf.getperf.com')
		-> proxy($URL)
		-> helloService($msg)
		-> result;
	is $res, 'Hello test', 'hello';
	}
	{
	my $res = SOAP::Lite 
		-> uri('http://perf.getperf.com')
		-> proxy($URL2)
		-> helloService($msg)
		-> result;
	is $res, 'Hello test', 'hello';
	}
	{
	my $res = SOAP::Lite 
		-> uri('http://perf.getperf.com')
		-> proxy($URL)
		-> helloJedis($msg)
		-> result;
	is $res, 'HelloJedis test', 'HelloJedis';
	}

};

# subtest 'attached file' => sub {
# 	my $PWD = `dirname $0`; chop($PWD);
	
# 	my $ent = build MIME::Entity
# 	  Type        => "image/gif",
# 	  Encoding    => "base64",
# 	  Path        => "$PWD/test.txt",
# 	  Filename    => "test.txt",
# 	  Id          => 'test.txt',
# 	  Disposition => "attachment";
	
# 	my $som = SOAP::Lite
# 	  ->packager(SOAP::Lite::Packager::MIME->new)
# 	  ->uri('http://perf.getperf.com')
# 	  ->parts([ $ent ])
# 	  ->proxy($URL)
# 	  ->testGetAttachedFile()
# 	  ->result;
# };

done_testing;
