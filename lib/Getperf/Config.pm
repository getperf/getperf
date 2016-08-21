use strict;
use warnings;
package Getperf::Config;

use Data::Dumper;
use Log::Handler app => "LOG";
use Log::Handler::Output::File::Stamper;
use File::Basename qw(dirname);
use File::Copy;
use Object::Container -base;
use FindBin;
use Path::Class;
use JSON::XS;
use File::Basename qw(dirname);
use constant {
	PATH_TIME_STAMP => 1,
	PATH_TIME_SHIFT => 2,
};

our $GETPERF_HOME     = $ENV{'GETPERF_HOME'} ||file(dirname(__FILE__) . '/../..')->absolute->resolve->stringify;
our $GETPERF_CONF_DIR = $ENV{'GETPERF_CONF_DIR'} || "$GETPERF_HOME/config";
our $AUTO_AGGREGATE   = 1;
our $AUTO_DEPLOY      = 1;
our $GETPERF_INIT;

sub read_config {
	my ($json_file) = @_;
	my $config_file = file($GETPERF_CONF_DIR, $json_file);
	if ($config_file->stat) {
		my $config_json_text = $config_file->slurp || die $@;
    	return decode_json($config_json_text);
	}
	return {};
}

sub read_sitekeys {
	my @sites = ();
	my @site_lists = dir($GETPERF_CONF_DIR, 'site')->children;
	for my $site ( sort @site_lists ) {
		next if ($site->basename!~/^(.+?)\.json/);
    	push(@sites, $1);
	}
	return @sites;
}

sub read_site_config {
	my ($sitekey) = @_;
	return read_config("site/$sitekey.json");
}

sub dump_site_config_json {
	my ($sitekey, $c) = @_;

	sub nvl {
		my ($src, $default) = @_;
		return (defined($src))?$src:$default;
	}

	my @json = (
		'{' ,
		'	"site_key":   "' . $sitekey . '",' ,
		'	"access_key": "' . nvl($c->{access_key}, '') . '",' ,
		'	"home":       "' . nvl($c->{home}, '') . '",' ,
		'	"user":       "' . nvl($c->{user}, '') . '",' ,
		'	"group":      "' . nvl($c->{group}, '') . '",' ,
		'',
		'	"auto_aggregate": ' . nvl($c->{auto_aggregate}, $AUTO_AGGREGATE) . ',' ,
		'	"auto_deploy":    ' . nvl($c->{auto_deploy}, $AUTO_DEPLOY) ,
		'}',
	);

	return join("\n", @json);
}

sub write_site_config {
	my ($sitekey, $c) = @_;

	my $config = "$GETPERF_CONF_DIR/site/${sitekey}";
	my $config_json = $config . '.json';
	my $config_tmp  = $config . '.tmp';
	my $config_bak  = $config . '.bak';

	my $config_file = file($config_tmp);
	my $writer = file($config_file)->open('w') || die "$! : $config_file";
	my $buf = dump_site_config_json($sitekey, $c);
	$writer->print($buf);
	$writer->close;

	if (-f $config_json) {
		move $config_json, $config_bak || die $!;
	}
	move $config_tmp,  $config_json || die $!;

	return 1;
}

{
	package BaseConfig;
	use Log::Handler app => "LOG";
	use Data::Dumper;

	sub new {
	    my ($class) = @_;

		my $config = Getperf::Config::read_config('getperf_site.json');
	    my $self = bless {
		    root_instance      => 1, 
			config_file        => "$GETPERF_CONF_DIR/getperf_site.conf",
			config_dir         => $GETPERF_CONF_DIR,
			site_config_dir    => "$GETPERF_CONF_DIR/site",
			debug              => 0,
			fork               => 1,
			max_processes      => 16,
			sitekey            => undef,
			home               => $config->{GETPERF_HOME} || $GETPERF_HOME,
			ssl_admin_dir      => $config->{GETPERF_ADMIN_SSL_DIR} || "/etc/getperf/ssl",
			ssl_expiration_day => $config->{GETPERF_SSL_EXPIRATION_DAY} || 365,
			ssl_root_ca        => $config->{GETPERF_SSL_COMMON_NAME_ROOT_CA} || 'getperf_ca',
			ssl_inter_ca       => $config->{GETPERF_SSL_COMMON_NAME_INTER_CA} || 'getperf_inter',
			license_policy     => $config->{GETPERF_LICENSE_POLICY} || 'none',
			ws_tomcat_owner    => $config->{GETPERF_WS_TOMCAT_OWNER} || 'pscommon',
			ws_server_name     => $config->{GETPERF_WS_SERVER_NAME} || '127.0.0.1',
			ws_server_admin    => $config->{GETPERF_WS_SERVER_ADMIN} || 'you@example.com',
			ws_protocol        => $config->{GETPERF_WS_PROTOCOL} || 'https',
			ws_apache_dir      => $config->{GETPERF_WS_APACHE_HOME} || "/usr/local/apache",
			ws_tomcat_dir      => $config->{GETPERF_WS_TOMCAT_HOME} || "/usr/local/tomcat",
			ws_admin_server    => $config->{GETPERF_WS_ADMIN_SERVER} || '127.0.0.1',
			ws_admin_suffix    => $config->{GETPERF_WS_ADMIN_SUFFIX} || "admin",
			ws_admin_port_ssl  => $config->{GETPERF_WS_ADMIN_PORT_SSL} || 57443,
			ws_admin_port_run  => $config->{GETPERF_WS_ADMIN_PORT_RUN} || 57005,
			ws_admin_port_ajp  => $config->{GETPERF_WS_ADMIN_PORT_AJP} || 57009,
			ws_admin_port      => $config->{GETPERF_WS_ADMIN_PORT} || 57000,
			ws_admin_dir       => $config->{GETPERF_WS_ADMIN_DIR} || '/axis2/services/GetperfService',
			ws_data_server     => $config->{GETPERF_WS_DATA_SERVER} || '127.0.0.1',
			ws_data_suffix     => $config->{GETPERF_WS_DATA_SUFFIX} || "data",
			ws_data_port_ssl   => $config->{GETPERF_WS_DATA_PORT_SSL} || 58443,
			ws_data_port_run   => $config->{GETPERF_WS_DATA_PORT_RUN} || 58005,
			ws_data_port_ajp   => $config->{GETPERF_WS_DATA_PORT_AJP} || 58009,
			ws_data_port       => $config->{GETPERF_WS_DATA_PORT} || 58000,
			ws_data_dir        => $config->{GETPERF_WS_DATA_DIR} || '/axis2/services/GetperfService',
			staging_dir        => $config->{GETPERF_STAGING_DIR} || "$GETPERF_HOME/staging",
			site_dir           => $config->{GETPERF_SITE_DIR} ||    "$GETPERF_HOME/site",
			tmpfs_dir          => $config->{GETPERF_TMPFS_DIR} ||   "$GETPERF_HOME/tmpfs",
			lib_dir            => $config->{GETPERF_LIB_DIR} ||     "$GETPERF_HOME/lib",
			log_dir            => $config->{GETPERF_LOG_DIR} ||     "$GETPERF_HOME/log",
			agent_tar          => $config->{GETPERF_AGENT_TAR} ||   "$GETPERF_HOME/var/agent",
			agent_major_ver    => $config->{GETPERF_AGENT_MAJOR_VERSIOPN} || 2,
			log_level          => $config->{GETPERF_LOG_LEVEL} ||   'info', 
			stdout_log_level   => $config->{GETPERF_STDOUT_LOG_LEVEL} ||   'error', 
			disk_util_limit    => $config->{GETPERF_DISK_UTIL_LIMIT_MB} || 100,
			purge_data_hour    => $config->{GETPERF_PURGE_DATA_HOUR} || undef,
			admin_schedule     => $config->{GETPERF_ADMIN_SCHEDULE} || undef,
			mysql_passwd       => $config->{GETPERF_CACTI_MYSQL_ROOT_PASSWD} || undef,
	    }, $class;
	    $self->_init_log if (!$GETPERF_INIT);
		$GETPERF_INIT = 1;
	    return $self;
	}

	sub _init_log {
		my ($self) = @_;

		LOG->add(
			'Log::Handler::Output::File::Stamper' => +{
				filename       => $self->{log_dir} . '/getperf.log.%d{yyyyMMdd}',
				maxlevel       => $self->{log_level},
				permissions    => "0664",
				timeformat     => "%Y/%m/%d %H:%M:%S",
				message_layout => "%T [%L] %m",
			},
		);
		# Log owner to change the owner it was written in the config. 
		# problems that owners become root when root run.
		my $owner = $self->{ws_tomcat_owner};
		eval {
			my ($uid, $gid) = (getpwnam $owner)[2,3] or die "getpwnam $owner";
			if (my $filename = LOG->{outputs}[0]->{output}->{filename}) {
				chown $uid, $gid, $filename;
			}
		};
	}

	sub add_screen_log {
		my ($self) = @_;
		LOG->add(
			screen => {
				log_to   => "STDOUT",
				maxlevel => $self->{stdout_log_level},
				timeformat      => "%Y/%m/%d %H:%M:%S",
				message_layout => "%T [%L] %m",
			},
		);
	}
}

{
	package SiteConfig;

	sub new {
	    my ($class) = @_;

		
		my @config = Getperf::Config::read_sitekeys();
	    bless {
	    	sites => \@config,
	    }, $class;
	}
}

{
	package RsyncConfig;

	sub new {
	    my ($class) = @_;

		my $config = Getperf::Config::read_config('getperf_rsync.json') || undef;
	    bless {
	    	($config)? %$config : (),
	    }, $class;		
	}
}

{
	package RRDConfig;

	sub new {
	    my ($class) = @_;

		my $config = Getperf::Config::read_config('getperf_rrd.json');
	    bless {
	    	rra => $config,
	    }, $class;
	}
}

{
	package QueueConfig;

	sub new {
	    my ($class) = @_;

		my $config = Getperf::Config::read_config('getperf_queue.json');
	    bless {
	    	%$config,
	    }, $class;
	}
}

{
	package CactiConfig;

	sub new {
	    my ($class) = @_;

		my $config = Getperf::Config::read_config('getperf_cacti.json');
	    bless {
	    	%$config,
	    }, $class;
	}
}

{
	package ZabbixConfig;

	sub new {
	    my ($class) = @_;

		my $config = Getperf::Config::read_config('getperf_zabbix.json');
	    bless {
	    	%$config,
	    }, $class;
	}
}

{
	package GraphiteConfig;

	sub new {
	    my ($class) = @_;

		my $config = Getperf::Config::read_config('getperf_graphite.json');
	    bless {
	    	%$config,
	    }, $class;
	}
}

{
	package InfluxConfig;

	sub new {
	    my ($class) = @_;

		my $config = Getperf::Config::read_config('getperf_influx.json');
	    bless {
	    	%$config,
	    }, $class;
	}
}

register 'base'     => sub { BaseConfig->new; };
register 'rsync'    => sub { RsyncConfig->new; };
register 'rrd'      => sub { RRDConfig->new; };
register 'queue'    => sub { QueueConfig->new; };
register 'cacti'    => sub { CactiConfig->new; };
register 'zabbix'   => sub { ZabbixConfig->new; };
register 'graphite' => sub { GraphiteConfig->new; };
register 'influx'   => sub { InfluxConfig->new; };
register 'sites'    => sub { SiteConfig->new; };

1;
