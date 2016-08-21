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

my $config = config('base');
$config->add_screen_log;

# SSL Certificate
# クライアント認証
my $client_cert_dir='/etc/getperf/ssl/client/site01/host01';
if (! -d $client_cert_dir) {
	print "USAGE: client cert file not found.\n" . 
	"run sudo perl script/ssladmin.pl client_cert --sitekey=site01 --agent=host01\n";
	exit 1;
}

$ENV{HTTPS_CA_FILE}   = $config->{ssl_admin_dir} . '/ca/ca.crt';
$ENV{HTTPS_CERT_FILE} = "$client_cert_dir/client.crt";
$ENV{HTTPS_KEY_FILE}  = "$client_cert_dir/client.key";

#$ENV{HTTPS_CA_FILE}   = 'cacert.pem';
#$ENV{HTTPS_CERT_FILE} = "clcert.pem";
#$ENV{HTTPS_KEY_FILE}  = "client.key";

#my $URL  ='http://localhost:57000/';
#my $URL  ='https://localhost:57443/';
my $hostname = $config->{ws_server_name};
#my $URL  = "https://$hostname:58443/axis2/services/GetperfService";
my $URL  = "http://$hostname:58000/axis2/services/GetperfService";
#my $URL  = "https://$hostname:58443/";

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

};
done_testing;
