use strict;
use warnings;
package Getperf::SSL;
use Sys::Hostname;
use Getopt::Long;
use Path::Class;
use JSON::XS;
use Getperf::Config 'config';
use Getperf::Aggregator;
use Getperf::Data::SiteInfo;
use parent qw(Class::Accessor::Fast);
use Data::Dumper;
use Time::Moment;
use Time::Seconds;
use File::Copy;
use Log::Handler app => "LOG";

__PACKAGE__->mk_accessors(qw/ca_root server_name ca_storage ca_index ca_serial ca_config cli_config inter_config server_cert client_cert command sitekey agent/);

sub new {
	my ($class, $ca_name, $ca_root) = @_;

	my $base     = config('base');
	my $zabbix   = config('zabbix');
	my $ssl_home = $base->{ssl_admin_dir};
	if (!$ca_root) {
		$ca_root = $ssl_home . '/ca';
	}
	if (!$ca_name) {
		$ca_name = 'getperf_ca';
	}
	my $self = bless {
		command        => undef,
		openssl        => $ENV{OPENSSL_PATH} || 'openssl',
		expiration_day => $base->{ssl_expiration_day},
		ssl_home       => $ssl_home,
		server_cert    => $ssl_home . '/server',
		client_cert    => $ssl_home . '/client',
		ca_root        => $ca_root,
		ca_name        => $ca_name,
		server_name    => $base->{ws_server_name},
		ca_storage     => $ca_root . '/ca.db.certs',	# Signed certificates storage
		ca_index       => $ca_root . '/ca.db.index',	# Index of signed certificates
		ca_serial      => $ca_root . '/ca.db.serial',	# Next (sequential) serial number
		ca_config      => $ca_root . '/ca.conf',
		cli_config     => $ca_root . '/client.conf',
		inter_config   => $ca_root . '/inter.conf',
		sitekey        => undef,
		agent          => undef,
		zabbix_host    => ($zabbix->{GETPERF_AGENT_USE_ZABBIX}) ? $zabbix->{ZABBIX_SERVER_IP} : undef,
	}, $class;

	return $self;
}

sub run {
	my $self = shift;

	my $command = $self->command || undef;
	return if (!$command);

	my $base = config('base');
	$base->add_screen_log;

	my $ssl_home = $self->{ssl_home};
	if ($command eq 'create_ca') {
		my $root_ca = Getperf::SSL->new($base->{ssl_root_ca}, "$ssl_home/ca");
		my $ca_root = $root_ca->{ca_root};
		if (-d $ca_root) {
			dir($ca_root)->rmtree or die $!;
		}
		if (!$root_ca->create_ca) {
			LOG->crit("Root CA create error");
			return;
		}
	} elsif ($command eq 'create_inter_ca') {
		my $root_ca  = Getperf::SSL->new($base->{ssl_root_ca},  "$ssl_home/ca");
		my $inter_ca = Getperf::SSL->new($base->{ssl_inter_ca}, "$ssl_home/inter");
		$root_ca->reset_certificate($inter_ca->{ca_name});
		if (-d (my $ca_root = $inter_ca->{ca_root})) {
			dir($ca_root)->rmtree or die $!;
		}
		return $self->create_inter_ca($root_ca, $inter_ca);

	} elsif ($command eq 'server_cert') {
		my $inter_ca = Getperf::SSL->new($base->{ssl_inter_ca}, "$ssl_home/inter");
		$inter_ca->reset_server_certificate;
		return $inter_ca->create_server_certificate;

	} elsif ($command eq 'client_cert') {
		my $inter_ca = Getperf::SSL->new($base->{ssl_inter_ca}, "$ssl_home/inter");
		$self->create_client_certificate($self->sitekey, $self->agent) || return;
		return $self->create_client_server_certificate($self->sitekey, $self->agent);
		
		# my $root = dir($self->client_cert, $self->sitekey, $self->agent, 'network');
		# $inter_ca->{server_cert} = $root;
		# $inter_ca->{server_name} = $self->agent;
		# # print Dumper $self;
		# $inter_ca->reset_server_certificate;
	 #    return $inter_ca->create_server_certificate;

	} elsif ($command eq 'update_client_cert') {
		my $inter_ca = Getperf::SSL->new($base->{ssl_inter_ca}, "$ssl_home/inter");
		return $inter_ca->update_client_certificate();

	} elsif ($command eq 'archive_ca') {
		return $self->archive_ca();

	} elsif ($command eq 'cross_root_cert') {
		my $cross_ca = Getperf::SSL->new('cross_ca', "$ssl_home/cross/ca");
		my $inter_ca = Getperf::SSL->new('inter_ca', "$ssl_home/cross/inter");
		return $self->create_ca_cross_root($cross_ca, $inter_ca);

	} else {
		return;
	}

	return 1;
}

sub parse_command_option {
	my ($self, $args) = @_;

	my $usage = 'Usage : ssladmin.pl ' . 
		"\n\tcreate_ca" .
		"\n\tarchive_ca" .
		"\n\tcreate_inter_ca" .
		"\n\tserver_cert" .
		"\n\tclient_cert [--sitekey=site] [--agent=host]]|" .
		"\n\tupdate_client_cert" .
		"\n\tcross_root_cert\n";

	push @ARGV, grep length, split /\s+/, $args if ($args);
	GetOptions (
		'--sitekey=s' => \$self->{sitekey},
		'--agent=s'   => \$self->{agent},
	);
	unless (@ARGV) {
		print "No command\n" . $usage;
		return;
	}
	$self->{command} = shift(@ARGV);

	if ($self->{command} eq 'client_cert' && (!$self->{sitekey} || !$self->{agent})) {
		print "No sitekey or agent\n" . $usage;
		return;
	}
	return 1;
}

sub openssl_command {
	my ($self, $command) = @_;

	my $openssl = $self->{openssl};
	my $result = readpipe("$openssl $command 2>&1");
	LOG->notice("$openssl $command");
	if (lc($result)=~/(error|usage|failed)/) {
		LOG->crit($result);
		LOG->crit($command);
		return;
	}
	return 1;	
}

sub create_ssl_config_file {
	my $self = shift;

	my @client_configs = (
		'[ req ]',
		'distinguished_name = generic_policy',
		'',
		'[ usr_cert ]',
		'nsCertType = client,email',
		'',
	);

	my @ca_configs = (
		'[ ca ]',
		'default_ca = ca_default',
		'',
		'[ ca_default ]',
		'dir              = ' . $self->ca_root,
		'certs            = $dir',
		'new_certs_dir    = $dir/ca.db.certs',
		'database         = $dir/ca.db.index',
		'serial           = $dir/ca.db.serial',
		'RANDFILE         = $dir/ca.db.rand',
		'certificate      = $dir/ca.crt',
		'private_key      = $dir/ca.key',
		'default_days     = ' . $self->{expiration_day},
		'default_crl_days = 30',
		'default_md       = sha256',
		'preserve         = no',
		'policy           = generic_policy',
		'',
	);

	my @generic_policys = (
		'[ generic_policy ]',
		'countryName            = optional',
		'stateOrProvinceName    = optional',
		'localityName           = optional',
		'organizationName       = optional',
		'organizationalUnitName = optional',
		'commonName             = supplied',
		'emailAddress           = optional',
		'',
	);

	my @v3_ca_configs = (
		'[ v3_ca ]',
		'subjectKeyIdentifier=hash',
		'basicConstraints = CA:true',
	);

	my $ca_config = file($self->ca_config);
    my $writer = $ca_config->openw || die "write error $ca_config : $!";
	$writer->print(join("\n", @ca_configs, @generic_policys));
	$writer->close;

	my $cli_config = file($self->cli_config);
    $writer = $cli_config->openw || die "write error $cli_config : $!";
	$writer->print(join("\n", @client_configs, @ca_configs, @generic_policys));
	$writer->close;

	my $inter_config = file($self->inter_config);
    $writer = $inter_config->openw || die "write error $inter_config : $!";
	$writer->print(join("\n", @ca_configs, 
						'x509_extensions	= v3_ca', 
						'', 
						@generic_policys, @v3_ca_configs));
	$writer->close;

	return 1;
}

sub create_ca {
	my $self = shift;

	# Generate CA directory
	my $ca_root = dir($self->ca_root);
	if (!-d $ca_root) {
		LOG->notice("create ca_root config : $ca_root");
		if (!dir($ca_root)->mkpath) {
			LOG->crit("create path error $ca_root : $!");
			return;
		}
		dir($self->ca_storage)->mkpath;
		file($self->ca_index)->touch;
		$self->create_ssl_config_file;

		my $ca_serial = file($self->ca_serial);
	    my $writer = $ca_serial->openw || die "write error $ca_serial : $!";
		$writer->print("00\n");
	}

	# Generate CA private key
	{
		# my $command = "genrsa -out $ca_root/ca.key -des3 2048";
		my $command = "genrsa -out $ca_root/ca.key 2048";
		$self->openssl_command($command) || return;
	}	

	# Create Certificate Signing Request
	{
		my $ca_name = $self->{ca_name};
		my $subject = "\"/commonName=${ca_name}\"";
	    my $command = "req -new -sha256 -key $ca_root/ca.key -out $ca_root/ca.csr -subj $subject";
	    $self->openssl_command($command) || return;
    }    

	# Create self-signed certificate
	{
		my $options = "-days 10000";
		my $command = "x509 -req -in $ca_root/ca.csr -out $ca_root/ca.crt -signkey $ca_root/ca.key";

	    $self->openssl_command("$command $options") || return;
	}

	return 1;
}

sub archive_ca {
	my $self = shift;

	# Archive CA directory
	my $ca_root = dir($self->ca_root);
	if (!-d $ca_root) {
		LOG->error("Not found $ca_root. Run 'ssladmin.pl create_ca'");
		return;
	}
	{
		my $tar_file = file(config('base')->{home}, '/var/ssl/ca.tar.gz');
		if (!-d (my $tar_dir = $tar_file->parent)) {
			eval {
				$tar_dir->mkpath;
			};
			if ($@) {
				die "Mkdir error '$tar_dir' : $@";
			}
		}

		chdir $self->{ssl_home};
		my $tar_command = "tar cvf - ca | gzip > ${tar_file}";
		my $result = `$tar_command`;
		if ($result=~/(ERROR|usage|failed)/) {
			LOG->crit($result);
			LOG->crit($tar_command);
			return;
		}
		LOG->notice("save '$tar_file'.");
	}

	return 1;
}

sub create_inter_ca {
	my ($self, $root_ca, $inter_ca) = @_;

	# Generate inter CA directory
	my $ca_root = dir($inter_ca->ca_root);
	if (!-d $ca_root) {
		LOG->notice("create ca_root config : $ca_root");
		if (!dir($ca_root)->mkpath) {
			LOG->crit("create path error $ca_root : $!");
			return;
		}		
		dir($inter_ca->ca_storage)->mkpath;
		file($inter_ca->ca_index)->touch;
		$inter_ca->create_ssl_config_file;

		my $ca_serial = file($inter_ca->ca_serial);
	    my $writer = $ca_serial->openw || die "write error $ca_serial : $!";
		$writer->print("00\n");
	}
	$inter_ca->create_ssl_config_file;

	# Generate CA private key.
	{
		my $ca_home = $inter_ca->{ca_root};
		my $command = "genrsa -out $ca_home/ca.key 2048";
		$self->openssl_command($command) || return;
	}	

	# Create Certificate Signing Request. Copy local root CA commonName
	{
		my $ca_home = $inter_ca->{ca_root};
		my $ca_name = $inter_ca->{ca_name};
		my $subject = "\"/commonName=$ca_name\"";
	    my $command = "req -new -sha256 -key $ca_home/ca.key -out $ca_home/ca.csr -subj $subject";
	    $self->openssl_command($command) || return;
    }    

	# Create self-signed certificate from Cross root CA
	{
		my $ca_home = $inter_ca->{ca_root};
		my $root_ca  = $root_ca->{ca_root};
		my $options = "-days 10000";
		my $command = "ca -config $root_ca/inter.conf -in $ca_home/ca.csr -out $ca_home/ca.crt -keyfile $root_ca/ca.key -batch";

	    $self->openssl_command("$command $options") || return;
	}

	return 1;
}

sub create_ca_cross_root {
	my ($self, $cross_ca, $inter_ca) = @_;

	# Generate inter CA directory
	my $ca_root = dir($inter_ca->ca_root);
	if (!-d $ca_root) {
		LOG->notice("create ca_root config : $ca_root");
		if (!dir($ca_root)->mkpath) {
			LOG->crit("create path error $ca_root : $!");
			return;
		}		
		dir($inter_ca->ca_storage)->mkpath;
		file($inter_ca->ca_index)->touch;
		$inter_ca->create_ssl_config_file;

		my $ca_serial = file($inter_ca->ca_serial);
	    my $writer = $ca_serial->openw || die "write error $ca_serial : $!";
		$writer->print("00\n");
	}
	$cross_ca->create_ssl_config_file;

	# Check Cross root ca directory
	my $cross_ca_root = $cross_ca->ca_root;
	if (!-d $cross_ca_root) {
		LOG->crit('No cross route SSL CA directory exists.');
		LOG->crit('You should copy from other CA root (/etc/getperf/ssl/ca) of cross route to /etc/getperf/ssl/cross/ .');
		exit -1;
	}

	# Generate CA private key. Copy local root CA key
	{
		my $root_ca_pkey  = $self->{ca_root} . '/ca.key';
		my $inter_ca_pkey = $inter_ca->{ca_root} . '/ca.key';

		LOG->notice("copy ${root_ca_pkey} ${inter_ca_pkey}");
		if (copy ($root_ca_pkey, $inter_ca_pkey) == 0) {
			LOG->crit($!); 
			return;
		}
	}	

	# Create Certificate Signing Request. Copy local root CA commonName
	{
		my $inter_ca = $inter_ca->{ca_root};
		my $ca_name = config('base')->{ssl_root_ca};
		my $subject = "\"/commonName=$ca_name\"";
	    my $command = "req -new -sha256 -key $inter_ca/ca.key -out $inter_ca/ca.csr -subj $subject";
	    $self->openssl_command($command) || return;
    }    

	# Create self-signed certificate from Cross root CA
	{
		my $inter_ca = $inter_ca->{ca_root};
		my $cross_ca = $cross_ca->{ca_root};
		my $options = "-days 10000";
		my $command = "ca -config $cross_ca/inter.conf -in $inter_ca/ca.csr -out $inter_ca/ca.crt -keyfile $cross_ca/ca.key -batch";

	    $self->openssl_command("$command $options") || return;
	}

	return 1;
}

sub create_server_certificate {
	my $self = shift;

	# Generate Server certificate directory
	my $root = dir($self->server_cert);
	my $server_key  = "$root/server.key";
	my $server_csr  = "$root/server.csr";
	my $server_crt  = "$root/server.crt";
	if (!-d $root) {
		LOG->notice("create dir : $root");
		if (!dir($root)->mkpath) {
			LOG->crit("create path error $root : $!");
			return;
		}
	}

	# Generate private key
	{
		my $command = "genrsa -out $server_key 2048";
		$self->openssl_command($command) || return;
	}	

	# Create Certificate Signing Request
	{
		my $server_name = $self->{server_name};
		my $subject = "\"/commonName=${server_name}\"";
	    my $command = "req -new -sha256 -key $server_key -out $server_csr -subj $subject";
	    $self->openssl_command($command) || return;
    }    

	# Create self-signed certificate
	{
		my $ca_config = $self->{ca_config};
		my $options = "-config $ca_config -batch";
		my $command = "ca -in $server_csr -out $server_crt";

	    $self->openssl_command("$command $options") || return;
	}

	return 1;
}

sub reset_certificate {
	my ($self, $common_name) = @_;

	return unless ($common_name);

	my $ca_index = file($self->ca_index);
	my @index_in = $ca_index ->slurp;
	my @index_out = grep !/CN=$common_name/, @index_in;

    my $writer = $ca_index->openw || die "write error $ca_index : $!";
	$writer->print(@index_out);
	$writer->close;
	return 1;
}


sub reset_server_certificate {
	my ($self) = @_;

	my $server_name = $self->{server_name};
	return $self->reset_certificate($server_name);
}

sub reset_client_certificate {
	my ($self, $sitekey, $agent) = @_;

	return unless ($sitekey && $agent);

	my $site_agent = $sitekey . '__' . $agent;
	my $ca_index = file($self->ca_index);
	my @index_in = $ca_index ->slurp;
	my @index_out = grep !/CN=$site_agent/, @index_in;

    my $writer = $ca_index->openw || die "write error $ca_index : $!";
	$writer->print(@index_out);
	$writer->close;
	return 1;
}

sub get_ssl_expired {
	my ($self) = @_;

	my $tm = Time::Moment->now()->plus_days($self->{expiration_day});
	my $expired = $tm->strftime('%Y%m%d');
	return $expired;
}

sub get_admin_web_service_url {
	my ($self) = @_;
	my $base = config('base');

	my $url = undef;
	my $server = $base->{ws_admin_server};
	my $ws_dir = $base->{ws_admin_dir};

	if ($base->{ws_protocol} eq 'https') {
		my $port = $base->{ws_admin_port_ssl};
		$url = "https://${server}:${port}${ws_dir}";
	} elsif ($base->{ws_protocol} eq 'http') {
		my $port = $base->{ws_admin_port};
		$url = "http://${server}:${port}${ws_dir}";
	}
	return $url;
}

sub get_data_web_service_url {
	my ($self) = @_;
	my $base = config('base');

	my $url = undef;
	my $server = $base->{ws_data_server};
	my $ws_dir = $base->{ws_data_dir};

	if ($base->{ws_protocol} eq 'https') {
		my $port = $base->{ws_data_port_ssl};
		$url = "https://${server}:${port}${ws_dir}";
	} elsif ($base->{ws_protocol} eq 'http') {
		my $port = $base->{ws_data_port};
		$url = "http://${server}:${port}${ws_dir}";
	}
	return $url;
}

# １週間後に切れるライセンスは更新ポリシーに従ってライセンスの更新をする
sub update_client_certificate {
	my ($self) = @_;
	my $root = dir($self->client_cert);

	my $tm = Time::Moment->now()->plus_days( 7 );
	my $expired_check = $tm->strftime('%Y%m%d');

	my @license_files;
	$root->recurse(callback => sub {
		my $license_file = shift;
		if ($license_file=~m|/network/License\.txt$|) {
			push(@license_files, $license_file);
		}
	});
	LOG->notice("update_client_certificate");
	my %licese_check_counts = ('target', 0, 'update', 0);
	for my $license_file(@license_files) {
		# /client/cacti_cli/localhost/network/License.txt
		my ($sitekey, $agent);
		if ($license_file!~m|/client/(.+?)/(.+?)/network/License\.txt|) {
			next;
		}
		$licese_check_counts{'target'} ++;
		($sitekey, $agent) = ($1, $2);
		LOG->info("check : $sitekey, $agent");
		my $license_expired = '';
		eval {
			map {
				chomp;
				if ($_=~/^EXPIRE=(\d{8})$/) {
					$license_expired = $1;
				}		
			} $license_file->slurp;
		};
		if ($@) {
			LOG->crit("License file parse error '$license_file' : $!");
			return;
		}
		if ( $license_expired && $license_expired lt $expired_check ) {
			LOG->info("update : $sitekey, $agent");
			$licese_check_counts{'update'} ++;
			$self->create_client_certificate( $sitekey, $agent ) || return;
		}
	}
	my $result = sprintf("%d/%d", $licese_check_counts{'update'}, $licese_check_counts{'target'});
	LOG->notice("check client_certificate : ${result}");
	return 1;
}

sub create_client_server_certificate {
	my ($self, $sitekey, $agent) = @_;

	my $base = config('base');
	my $ssl_home = $self->{ssl_home};
	my $inter_ca = Getperf::SSL->new($base->{ssl_inter_ca}, "$ssl_home/inter");
	my $root = dir($self->client_cert, $sitekey, $agent, 'network', 'server');
	$inter_ca->{server_cert} = $root;
	$inter_ca->{server_name} = $agent;
	$inter_ca->reset_server_certificate;
	return $inter_ca->create_server_certificate;
}

sub create_client_certificate {
	my ($self, $sitekey, $agent) = @_;

	# Reset Client certificate index and directory
	$self->reset_client_certificate($sitekey, $agent) || return;

	# Generate Client certificate directory
	my $root = dir($self->client_cert, $sitekey, $agent, 'network');
	my $client_key  = "$root/client.key";
	my $client_csr  = "$root/client.csr";
	my $client_crt  = "$root/client.crt";

	my $cli_config  = $self->{cli_config};
	if (!-d $root) {
		LOG->notice("create dir : $root");
		if (!dir($root)->mkpath) {
			LOG->crit("create path error $root : $!");
			return;
		}
	}

	# Generate private key
	{
		my $command = "genrsa -out $client_key 2048";
		$self->openssl_command($command) || return;
	}	

	# Create Certificate Signing Request
	{
		my $site_agent = $sitekey . '__' . $agent;

		my $subject = "\"/commonName=${site_agent}\"";
	    my $command = "req -new -sha256 -key $client_key -out $client_csr -subj $subject";
	    my $options = "-config $cli_config";
	    $self->openssl_command("$command $options") || return;
    }    

	# Create self-signed certificate
	{
		my $ca_config = $self->{ca_config};
		my $options = "-config $cli_config -batch";
		my $command = "ca -in $client_csr -out $client_crt";

	    $self->openssl_command("$command $options") || return;
	}

	# Copy CA,Service certificate file
	{
		my $ca_cert     = file($self->ca_root,     'ca.crt');
		my $command = "cp -p $ca_cert $root";
		my $result = readpipe("$command 2>&1");
		LOG->notice("$command");
		if ($result=~/(Error|usage|failed)/) {
			LOG->crit("error $command : $!");
			return;
		}
	}
	# Merge self-signed certificate and private key
	{
		my $client_cert_merged = "$root/client.pem";
		my $command = "cat $client_crt $client_key > $client_cert_merged";
		my $result = readpipe("$command 2>&1");
		LOG->notice("$command");
		if ($result=~/(Error|usage|failed)/) {
			LOG->crit("error $command : $!");
			return;
		}
	}
	# Generate License.txt (hostname and ssl expired date).
	{
		my $site_info = Getperf::Config::read_config("site/$sitekey.json");
		my $expired = $self->get_ssl_expired;
		my $code = defined($site_info->{access_key})?$site_info->{access_key}:'';
		my @licenses = (
			'HOSTNAME=' . ${agent},
			'EXPIRE=' . ${expired},
			'CODE=' . $code,
		);
		my $license_file = file($root, 'License.txt');
	    my $writer = $license_file->openw || die "write error $license_file : $!";
		$writer->print(join("\n", @licenses));
		$writer->close;
	}

	# Generate Web service config.
	{
		my $url_cm = $self->get_admin_web_service_url;
		my $url_pm = $self->get_data_web_service_url;

		my @configs = (
			"; --------- WEB Service URL ---------------------------------",
			"; WEB Service enable, If it is false, the agent doesn't send performance data.",
			"REMHOST_ENABLE = true",
			"",
			"; Admin management web service url.",
			"URL_CM = " . $url_cm,
			"",
			"; Data management web service url.",
			"URL_PM = " . $url_pm,
			"",
			"; Site key.",
			"SITE_KEY = " . $sitekey,
		);		
		my $config_file = file($root, "getperf_ws.ini");
	    my $writer = $config_file->openw || die "write error $config_file : $!";
		$writer->print(join("\r\n", @configs));
		$writer->close;
	}

	# Generate Zabbix config.
	if (my $zabbix_host = $self->{zabbix_host}) {

		my @configs = (
			"; Zabbix server",
			"ZABBIX_HOST=" . $zabbix_host,
		);		
		my $config_file = file($root, "zabbix.ini");
	    my $writer = $config_file->openw || die "write error $config_file : $!";
		$writer->print(join("\n", @configs));
		$writer->close;
	}

	# Zip cirtificate file directory to sslconf.zip
	{
		my $home = dir($self->client_cert, $sitekey, $agent);
		chdir($home);
		my $command = "cd $home; zip -r sslconf.zip network/*";
		my $result = readpipe("$command 2>&1");
		LOG->notice("$command");
		if ($result=~/(Error|usage|failed|not found)/) {
			LOG->crit("error $command : $!");
			return;
		}
	}
	return 1;
}

1;
