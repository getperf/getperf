#!/usr/bin/perl
#
# Config file creation 
#

use strict;
use warnings;
use Path::Class;
use Data::Dumper;
use File::Basename qw(dirname);
use Sys::Hostname; 
use Getopt::Long;
use Crypt::CBC;
use Template;
use Socket;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Log::Handler app => "LOG";
use Getperf;
use Getperf::Config 'config';

my $usage = "Usage: cre_config.pl -h --getperf_vip=s --zabbix_vip=s\n";

my ($GETPERF_VIP, $ZABBIX_VIP);
GetOptions('--getperf_vip=s' => \$GETPERF_VIP, '--zabbix_vip=s' => \$ZABBIX_VIP) ||
die $usage;

config('base')->add_screen_log;
my $COMPONENT_ROOT = file(config('base')->{home});
my $TEMPLATE_ROOT  = "$COMPONENT_ROOT/script/template/config";

my $LOCAL_IP            = &local_ip();
my $OS_USER             = getpwuid($>);
my $MYSQL_ROOT_PASSWD   = 'getperf';
my $ZABBIX_ADMIN_PASSWD = 'getperf';
my $GRAPHITE_SECRET_KEY = &random_string();
my $GRAPHITE_DB_PASS    = 'getperf';

&main();
exit 0;

sub random_string {
	my @set = ('0' ..'9', 'A' .. 'F');
	my $str = join '' => map $set[rand @set], 1 .. 8;
	return $str;
}

sub local_ip {
	socket(SOCKET, PF_INET, SOCK_DGRAM, 0);
	my $host_addr = pack_sockaddr_in(9999, inet_aton("1.1.1.1"));
	connect(SOCKET, $host_addr); 
	my @sock_addr = unpack_sockaddr_in(getsockname(SOCKET));
	my $local_ip = inet_ntoa($sock_addr[1]);
	close(SOCKET);

	return $local_ip;
}

sub patch_config {
	my ($config_file, $vars) = @_;

	chdir($TEMPLATE_ROOT);
	my $tt = Template->new;
	$tt->process($config_file, $vars, \my $output) || die $tt->error;
	my $config_path = $COMPONENT_ROOT . '/config/' . $config_file;
	my $writer = file($config_path)->open('w') || die "$! : $config_path";
	unless ($writer) {
        LOG->crit("Could not write $config_path: $!");
        return;
	}
	$writer->print($output);
	$writer->close;
	LOG->info("Generate : $config_path");

	return 1;
}

sub main {

	# Patch config/getperf_site.json
	{
		my $common_name_root_ca  = 'getperf_ca_' . $LOCAL_IP;
		my $common_name_inter_ca = 'getperf_inter_' . $LOCAL_IP;
		my $getperf_server_ip    = ($GETPERF_VIP) ? $GETPERF_VIP : $LOCAL_IP;
		my $vars = { 
		    COMPONENT_ROOT           => $COMPONENT_ROOT, 
		    MYSQL_ROOT_PASSWD        => $MYSQL_ROOT_PASSWD,
		    GETPERF_SERVER_IP        => $getperf_server_ip,
		    user                     => $OS_USER, 
		    local_ip                 => $LOCAL_IP,
		    ssl_common_name_root_ca  => $common_name_root_ca,
		    ssl_common_name_inter_ca => $common_name_inter_ca,
		};
		patch_config('getperf_site.json', $vars) || return;
	}

	# Patch config/getperf_rrd.json
	{
		my $vars = { 
		    COMPONENT_ROOT    => $COMPONENT_ROOT, 
		};
		patch_config('getperf_rrd.json', $vars) || return;
	}

	# Patch config/getperf_cacti.json
	{
		my $vars = { 
		    COMPONENT_ROOT    => $COMPONENT_ROOT, 
		};
		patch_config('getperf_cacti.json', $vars) || return;
	}

	# Patch config/getperf_zabbix.json
	{
		my $zabbix_server_ip    = ($ZABBIX_VIP) ? $ZABBIX_VIP : $LOCAL_IP;
		my $vars = { 
		    COMPONENT_ROOT          => $COMPONENT_ROOT, 
		    ZABBIX_ADMIN_PASSWORD   => $ZABBIX_ADMIN_PASSWD,
		    ZABBIX_SERVER_IP        => $zabbix_server_ip,
			 ZABBIX_SERVER_ACTIVE_IP => $zabbix_server_ip,
		};
		patch_config('getperf_zabbix.json', $vars) || return;
	}

	# Patch config/getperf_graphite.json
	{
		my $vars = { 
		    GRAPHITE_SECRET_KEY => $GRAPHITE_SECRET_KEY, 
		    GRAPHITE_DB_PASS => $GRAPHITE_DB_PASS,
		};
		patch_config('getperf_graphite.json', $vars) || return;
	}

	# Patch config/getperf_influxdb.json
	{
		my $vars = { 
		    INFLUX_HOST     => 'localhost', 
		    INFLUX_PORT     => 8086, 
		    INFLUX_DATABASE => 'mydb', 
		    INFLUX_DB_USER  => 'scott', 
		    INFLUX_DB_PASS  => 'tiger', 
		};
		patch_config('getperf_influx.json', $vars) || return;
	}

	return 1;
}

