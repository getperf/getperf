use FindBin;
use lib "$FindBin::Bin/../lib";
use strict;
use Test::More;
use Path::Class;
use Getperf;
use Getperf::Config 'config';
use Getperf::SSL;
use Getperf::Container qw/command/;
use Getperf::Data::DataInfo;
use lib "$FindBin::Bin/lib";
use Getperf::Test::Initializer;
use Data::Dumper;

use strict;

# replace with the actual test
use_ok("Getperf");

subtest 'ssl' => sub {
	{
		ok my $base = config('base');
		print $base->{ssl_admin_home};
	}
	{
		ok my $ssl = Getperf::SSL->new();
		my $ca_root = $ssl->{ca_root};
		print "CA_ROOT: $ca_root\n";	
		if (-d $ca_root) {
			dir($ca_root)->rmtree or die $!;
		}
		ok $ssl->create_ca;
		ok $ssl->create_ca(force=>1);
	}
	{
		ok my $ssl = Getperf::SSL->new();
		ok $ssl->create_server_certificate;
	}
	{
		ok my $ssl = Getperf::SSL->new();
		ok $ssl->create_client_certificate('sitekey', 'agent');
		ok $ssl->create_client_certificate('kawasaki', 'host1');
	}
	{
		ok my $ssl = Getperf::SSL->new();
		my $expired = $ssl->get_ssl_expired;
		print "expired=$expired\n";
	}
};

done_testing;
