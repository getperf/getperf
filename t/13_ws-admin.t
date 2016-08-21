use FindBin;
use lib "$FindBin::Bin/../lib";
use strict;
use Test::More;
use Data::Dumper; $Data::Dumper::Indent = 1;
use Log::Handler app => "LOG";
use Getperf;
use Getperf::Config 'config';
use Time::HiRes;
use SOAP::Lite; # +trace => qw(debug);
#use SOAP::Lite;
use SOAP::Lite::Packager;
use MIME::Entity;
use POSIX;

# replace with the actual test
use_ok("SOAP::Lite");

my $config = config('base');
$config->add_screen_log;

# SSL Certificate
$ENV{HTTPS_CA_FILE}   = $config->{ssl_admin_dir} . '/ca/ca.crt';

# クライアント認証
#$ENV{HTTPS_CERT_FILE} = 'clcert.pem';
#$ENV{HTTPS_KEY_FILE}  = 'client.key';

#my $URL  ='http://localhost:57000/';
#my $URL  ='https://localhost:57443/';
my $hostname = $config->{ws_server_name};
my $URL  = "https://$hostname:57443/axis2/services/GetperfService";

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
			-> proxy($URL)
			-> helloJedis($msg)
			-> result;
		is $res, 'HelloJedis test', 'HelloJedis';
	}
	{
		my $res = SOAP::Lite 
			-> uri('http://perf.getperf.com')
			-> proxy($URL)
			-> getLatestVersion()
			-> result;
		is $res, '2', 'getLatestVersion test';
	}
	{
		my $res = SOAP::Lite 
			-> uri('http://perf.getperf.com')
			-> proxy($URL)
			-> checkAgent('kawasaki', 'host1', 'QTo+s2VoyuBorFdD8Xa7qTHFDhE')
			-> result;
		is $res, 'OK', 'checkAgent test';
	}
	{
		my $res = SOAP::Lite 
			-> packager(SOAP::Lite::Packager::MIME->new)
			-> uri('http://perf.getperf.com')
			-> proxy($URL)
			-> registAgent('kawasaki', 'host1', 'QTo+s2VoyuBorFdD8Xa7qTHFDhE')
			;
		is $res->result, 'OK', 'registAgent test';

		# open OUT, ">/tmp/siteconf.zip";
		# my $part = shift(@{$res->parts});
		# $part->print_header(\*STDOUT);
		# $part->print_body(\*OUT);
		# close(OUT);
	}
	{
		my $res = SOAP::Lite 
			-> uri('http://perf.getperf.com')
			-> proxy($URL)
			-> sendMessage('kawasaki', 'host1', 1, 'Test')
			-> result;
		is $res, 'Invarid role', 'sendMessage test';
	}

};
done_testing;
