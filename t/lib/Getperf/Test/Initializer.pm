package Getperf::Test::Initializer;

use strict;
use FindBin;
use lib "$FindBin::Bin/../../../lib";
use Test::More;
use Data::Dumper;
use File::Basename qw(dirname);
use Getperf;
use Path::Class;
use Getperf::Config;
use Getperf::Monitor;
use Getperf::Extractor;
use Getperf::Aggregator;
use Getperf::Data::SiteInfo;
use Getperf::Data::DataInfo;
use Time::HiRes;
use JSON;

my $COMPONENT_ROOT = Path::Class::file(dirname(__FILE__) . '/../../../../')->absolute->resolve->stringify;

sub create_json_config {
	my ($config, $json_config_file, $orders) = @_;

	my %item_order = ();
	my $row = 1;
	for my $item(@$orders) {
		$item_order{$item} = $row ++;
	}
	sub sort_function {
		$item_order{$JSON::Converter::a} gt $item_order{$JSON::Converter::b};
	}
#	my $json = new JSON(pretty => 1, keysort => \&sort_function);
#	my $config_json = $json->objToJson($config);

	my $config_json = JSON::XS->new->pretty(1)->encode ($config);
	
	my $config_path = $COMPONENT_ROOT . '/config/' . $json_config_file;
	my $writer = file($config_path)->open('w') || die "$! : $config_path";
	$writer->print($config_json);
	$writer->close;
}

sub create_getperf_site_json {
	my ($site_home) = @_;

my $config_json = << "EOF";
{
	"GETPERF_HOME":        "$COMPONENT_ROOT",
	"GETPERF_SITE_DIR":    "$site_home",
	"GETPERF_STAGING_DIR": "$COMPONENT_ROOT/t/staging_data",
	"GETPERF_TMPFS_DIR":   "/tmp",
	"GETPERF_LOG_DIR":     "$COMPONENT_ROOT/log",
	"GETPERF_LOG_LEVEL":   "info",

	"GETPERF_DISK_UTIL_LIMIT_MB": 100,

	"GETPERF_REDIS_PORT": 6379,
	"GETPERF_REDIS_HOST": "localhost",
	"GETPERF_QUEUE":      "getperf:queue:default",

	"GETPERF_CACTI_MYSQL_ROOT_PASSWD": "getperf",

	"GETPERF_ADMIN_SSL_DIR":	 "/etc/getperf/ssl",
	"GETPERF_ADMIN_WS_SUFFIX":	 "ws",
	"GETPERF_ADMIN_MANAGE_PORT": 8443,
	"GETPERF_ADMIN_DATA_PORT":   58443,
	"GETPERF_ADMIN_CACTI_DIR":	 "/etc/getperf/ssl",

	"GETPERF_WS_APACHE_HOME":  "/usr/local/apache",
	"GETPERF_WS_TOMCAT_HOME":  "/usr/local/tomcat",

	"GETPERF_PURGE_DATA_HOUR": {
		"analysis": 1,
		"summary": 1
	}
}
EOF
#	print $config_json;
	my $config_path = $COMPONENT_ROOT . '/config/getperf_site.json';
	my $writer = file($config_path)->open('w') || die "$! : $config_path";
	$writer->print($config_json);
	$writer->close;
}

sub create_getperf_rsync_json {
	my $config = {
		site => {
			GETPERF_RSYNC_SOURCE => 'staging_data',
			GETPERF_RSYNC_ZIP_KEYWORD => '(ELA|SQL)',
			GETPERF_RSYNC_HOST => 'localhost',
		},
	};
	my @orders = qw/GETPERF_RSYNC_SOURCE GETPERF_RSYNC_ZIP_KEYWORD GETPERF_RSYNC_HOST/;
	
	create_json_config($config, 'getperf_rsync.json', \@orders);
}

sub create_getperf_queue_json {
	my $config = {
		GETPERF_REDIS_HOST => 'localhost',
		GETPERF_REDIS_PORT => 6379,
		GETPERF_QUEUE => 'getperf:queue:default',
	};
	my @orders = qw/GETPERF_REDIS_HOST GETPERF_REDIS_PORT GETPERF_QUEUE/;
	
	create_json_config($config, 'getperf_queue.json', \@orders);
}

sub create_getperf_site_home_json {
	my $site_path = shift;

	my $site = file($site_path);
	my $parent = $site->parent;
	my $sitekey = $site->basename;
	if (!-d $parent) {
		$parent->mkpath || die "$! : $parent";
	}

	my @config_json = (
		'{' ,
		'	"GETPERF_SITE_HOME": "' . $parent . '",' ,
		'	"GETPERF_SITE_KEY":  "' . $sitekey .'",' ,
		'	"GETPERF_SITE_DIR": "' . $parent . '/' . $sitekey . '"' ,
		'}',
	);
	my $json_text = join("\n", @config_json);
	my $site_config = file($COMPONENT_ROOT . '/config/site/' . $sitekey);
	print "Write $site_config\n\n$json_text\n";
	my $writer = $site_config->open('w') || die "$! : $site";
	$writer->print($json_text);
	$writer->close;
}

sub reset_staging_dir {
	my $config = Getperf::Config->instance;
	my $staging_dir = '/tmp/staging_tmp';
	if (-d $staging_dir) {
		my $command = "rm -r $staging_dir/*";
		print $command . "\n";
		system($command);
	} else {
		if (!File::Path::Tiny::mk($staging_dir)) {
	        LOG->crit("Could not make path '$staging_dir': $!");
	        return;
		}
	}
	{
		my $command = "cp -r $COMPONENT_ROOT/t/staging_data/site/* $staging_dir";
		print $command . "\n";
		return system($command);
	}
	return;
}

sub reset_alanysis_dir {
	create_getperf_site_json("$COMPONENT_ROOT/t");
	create_getperf_rsync_json();
	my @zips = qw/arc_t00051900cap04__ELA_20141009_1400.zip 
		arc_t00051900cap04__ELA_20141009_1410.zip 
		arc_t00051900cap04__SCO23ELA_20141009_1400.zip 
		arc_t00051900cap04__SCO23ELA_20141009_1410.zip/;
	my $extractor = Getperf::Extractor->new(sitekey=>'site', zips=>\@zips);
	$extractor->unzip;
}
1;
