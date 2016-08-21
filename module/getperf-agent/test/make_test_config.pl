#!/bin/perl
use strict;
use warnings;
use Path::Class;
use Data::Dumper;
use Getopt::Long;
use JSON::XS;
use File::Basename qw(dirname);
use Sys::Hostname; 
use Socket;
use FindBin;
use lib "$FindBin::Bin/../../../lib";
use lib "$ENV{'HOME'}/getperf/lib";
use Log::Handler app => "LOG";
use Getperf;
use Getperf::Config 'config';

# Read config file
config('base')->add_screen_log;
my $COMPONENT_ROOT = file(config('base')->{home});

my $a = config('base');
my $site = 'test1';
my $agent = 'paas';
my $ws_server_name    = $a->{ws_server_name};
my $ws_admin_port_ssl = $a->{ws_admin_port_ssl};
my $ws_data_port_ssl  = $a->{ws_data_port_ssl};
my $ws_admin_port     = $a->{ws_admin_port};
my $ws_data_port      = $a->{ws_data_port};
my $site_config_dir   = $a->{site_config_dir};
my $ssl_admin_dir     = $a->{ssl_admin_dir};

my $USAGE   = "$0 [--site=s] [--agent=s]\n";
GetOptions(
	'--site=s'   => \$site,
	'--agent=s'  => \$agent,
) || die $USAGE;

# Read site config file
my $config_file = file($site_config_dir, "$site.json");
print "read $config_file\n";
die $@ if (!$config_file->stat);
my $config_json = decode_json($config_file->slurp) || die $@;
my $access_key = $config_json->{access_key};

# CA certificate file
my $cacert = file($ssl_admin_dir, 'ca', 'ca.crt');

# Exec Client certificate create
#perl script/ssladmin.pl client_cert --sitekey=site01 --agent=host01
{
	my $ssladmin = file($a->{home}, 'script/ssladmin.pl' );
	my $command = "perl ${ssladmin} client_cert --sitekey=${site} --agent=${agent}";
	print $command; 
	system($command);
}

# Client cert
#/etc/getperf/ssl/client/sitekey/agent/ssl/client.pem
my $client_cert = file($ssl_admin_dir, 'client', $site, $agent, 'network', 'client.pem');

# Copy cert file to sum test directory
for my $ssl_dir ('./cfg/ssl', './cfg/network', './home/network') {
	my $ssl = file($ssl_dir);
	system("cp ${cacert} ${client_cert} ${ssl}");
}

# Copy bin to test
{
	for my $bin(qw/getperf getperfctl getperfsoap getperfzip/) {
		system("cp ../src/$bin .");
	}
}
# Test admin connect(no ssl)
my $url_cm_no_ssl = "http://${ws_server_name}:${ws_admin_port}/axis2/services/GetperfService";
my $url_pm_no_ssl = "http://${ws_server_name}:${ws_data_port}/axis2/services/GetperfService";
{
	my $wget = "wget --no-proxy --output-document=/dev/null $url_cm_no_ssl?wsdl";
	print $wget . "\n";
	system($wget);
}
{
	my $wget = "wget --no-proxy --output-document=/dev/null $url_pm_no_ssl?wsdl";
	print $wget . "\n";
	system($wget);
}

# Test admin connect
my $url_cm = "https://${ws_server_name}:${ws_admin_port_ssl}/axis2/services/GetperfService";
my $url_pm = "https://${ws_server_name}:${ws_data_port_ssl}/axis2/services/GetperfService";
{
	my $wget = "wget --no-proxy --output-document=/dev/null --ca-certificate=$cacert $url_cm?wsdl";
	print $wget . "\n";
	system($wget);
}
{
	my $wget = "wget --no-proxy --output-document=/dev/null --ca-certificate=$cacert --certificate=$client_cert $url_pm?wsdl";
	print $wget . "\n";
	system($wget);
}

mkdir("home/network") if (!-d "home/network");
mkdir("cfg/network")  if (!-d "cfg/network");
open my $out, ">home/network/getperf_ws.ini" || die "$!";
print $out "REMHOST_ENABLE = true\n";
print $out "URL_CM = ${url_cm}\n";
print $out "URL_PM = ${url_pm}\n";
print $out "SITE_KEY = ${site}\n";
close $out;
system("cp home/network/getperf_ws.ini cfg/network/getperf_ws.ini");

# print test_config.h
open OUT2, ">test_config.h" || die "$!";
print OUT2 << "EOF2"

#define AGENT_HOSTNAME "host1"
#define SITE_KEY       "${site}"
#define ACCESS_KEY     "${access_key}"
#define URL_CM         "${url_cm}"
#define URL_PM         "${url_pm}"
#define URL_CM_NO_SSL  "${url_cm_no_ssl}"
#define URL_PM_NO_SSL  "${url_pm_no_ssl}"

EOF2
