use strict;
use warnings;
package Getperf::Deploy;
use JSON::XS;
use Text::Patch;
use Sys::Hostname;
use Getopt::Long;
use Path::Class;
use Template;
use DBI;
use Getperf::Config 'config';
use parent qw(Class::Accessor::Fast);
use Data::Dumper;
use Log::Handler app => "LOG";

__PACKAGE__->mk_accessors(qw/command/);

sub new {
	my $class = shift;

	my $base   = config('base');
	my $zabbix = config('zabbix');
	$base->add_screen_log;
	my $self = bless {
		command             => undef,
		ws_server           => undef,
		ws_suffix           => undef,
		ws_port             => undef,
		ws_port_run         => undef,
		ws_port_ajp         => undef,
		ws_port_ssl         => undef,
		ws_apache_home      => undef,
		ws_tomcat_home      => undef,
		force               => undef,
		home                => $base->{home},
		ws_tomcat_owner     => $base->{ws_tomcat_owner},
		ws_server_name      => $base->{ws_server_name},
		ws_server_admin     => $base->{ws_server_admin},
		ws_tomcat_dir       => $base->{ws_tomcat_dir},
		ws_apache_dir       => $base->{ws_apache_dir},
		ws_tomcat_dir       => $base->{ws_tomcat_dir},
		ws_admin_server     => $base->{ws_admin_server},
		ws_admin_suffix     => $base->{ws_admin_suffix},
		ws_admin_port_ssl   => $base->{ws_admin_port_ssl},
		ws_admin_port_run   => $base->{ws_admin_port_run},
		ws_admin_port_ajp   => $base->{ws_admin_port_ajp},
		ws_admin_port       => $base->{ws_admin_port},
		ws_data_server      => $base->{ws_data_server},
		ws_data_suffix      => $base->{ws_data_suffix},
		ws_data_port_ssl    => $base->{ws_data_port_ssl},
		ws_data_port_run    => $base->{ws_data_port_run},
		ws_data_port_ajp    => $base->{ws_data_port_ajp},
		ws_data_port        => $base->{ws_data_port},
		agent_major_ver     => $base->{agent_major_ver},
		agent_build         => $base->{agent_build},
		agent_build_date    => $base->{agent_build_date},
		mysql_passwd        => $base->{mysql_passwd},
		use_zabbix          => $zabbix->{GETPERF_AGENT_USE_ZABBIX},
		zabbix_server_ip    => $zabbix->{ZABBIX_SERVER_IP},
		zabbix_agent_ver    => $zabbix->{ZABBIX_AGENT_VERSION},
		zabbix_download_dir => $zabbix->{ZABBIX_AGENT_DOWNLOAD_DIR},
		ws_apache_verify_client => undef,
		@_,
	}, $class;
	return $self;
}

sub run {
	my $self = shift;

	my $command = $self->command || undef;
	return if (!$command);

	if ($command eq 'config_apache') {
		return $self->config_apache;
	} elsif ($command eq 'config_tomcat') {
		return $self->config_tomcat;
	} elsif ($command eq 'config_axis2') {
		return $self->config_axis2;
	} elsif ($command eq 'php') {
		return $self->config_php;
	} elsif ($command eq 'epel_repo') {
		return $self->config_epel_repo;
	} elsif ($command eq 'epel_repo') {
		return $self->config_epel_repo;
	} else {
		return;
	}

	return 1;
}

sub parse_command_option {
	my ($self, $args) = @_;

	my $usage = 'Usage : deploy.pl ' . 
		"\n\t(config_apache|config_tomcat|config_axis2) --suffix=(admin|data) [--apache=s] [--tomcat=s]".
		"\n\tconfig_sumupctl|deploy_agent_module\n";

	push @ARGV, grep length, split /\s+/, $args if ($args);
	GetOptions (
		'--apache=s' => \$self->{ws_apache_dir},
		'--tomcat=s' => \$self->{ws_tomcat_dir},
		'--suffix=s' => \$self->{ws_suffix},
		'--force'    => \$self->{force},
	);
	if ($0!~/deploy-ws\.pl/) {
		return 1;
	}
	unless (@ARGV) {
		print "No command\n" . $usage;
		return;
	}
	$self->{command} = shift(@ARGV);

 	$self->{ws_apache_home}  = $self->{ws_apache_dir} . '-' . $self->{ws_suffix};
 	$self->{ws_tomcat_home}  = $self->{ws_tomcat_dir} . '-' . $self->{ws_suffix};
 	if ($self->{ws_suffix} eq 'admin') {
 		$self->{ws_server}   = $self->{ws_admin_server};
 		$self->{ws_port}     = $self->{ws_admin_port};
 		$self->{ws_port_ajp} = $self->{ws_admin_port_ajp};
 		$self->{ws_port_ssl} = $self->{ws_admin_port_ssl};
 		$self->{ws_port_run} = $self->{ws_admin_port_run};
 		$self->{ws_apache_verify_client} = 'optional';
	} elsif ($self->{ws_suffix} eq 'data') {
 		$self->{ws_server}   = $self->{ws_data_server};
 		$self->{ws_port}     = $self->{ws_data_port};
 		$self->{ws_port_ajp} = $self->{ws_data_port_ajp};
 		$self->{ws_port_ssl} = $self->{ws_data_port_ssl};
 		$self->{ws_port_run} = $self->{ws_data_port_run};
 		$self->{ws_apache_verify_client} = 'require';
	} else {
		print "suffix invalid\n" . $usage;
		return;
	}
	return 1;
}

sub parse_command_option_package {
	my ($self, $args) = @_;

	my $usage = 'Usage : config-pkg.pl ' . 
		"\n\t(php|epel_repo)\n";

	push @ARGV, grep length, split /\s+/, $args if ($args);
	GetOptions (
	);
	unless (@ARGV) {
		print "No command\n" . $usage;
		return;
	}
	$self->{command} = shift(@ARGV);

 	if ($self->{command}!~/(php|epel_repo)/) {
		print "invalid command\n" . $usage;
		return;
	}

	return 1;
}

sub config_php {
	my $self = shift;

	my @config_files = qw|/etc/php.ini /etc/php5/cli/php.ini /etc/php5/apache2/php.ini|;
	for my $config_file(@config_files) {
		next if (!-f $config_file);
		LOG->notice("patch $config_file");
	 	eval {
			$config_file = file($config_file);
	     	my @lines = $config_file->slurp or die $!;
	     	my @out;
	 		for my $line(@lines) {
	 			chomp($line);
	 			if ($line=~/max_execution_time\s=/) {
	 				push @out, "max_execution_time = 300";
	 			} elsif ($line=~/max_input_time\s=/) {
	 				push @out, "max_input_time = 60";
	 			} elsif ($line=~/memory_limit\s=/) {
	 				push @out, "memory_limit = 768M";
	 			} elsif ($line=~/date\.timezone\s=/) {
	 				push @out, "date.timezone = 'Asia/Tokyo'";
	 			} else {
	 				push @out, $line;
	 			}
	 		}

	 		my $writer = $config_file->open('w') or die $!;
	 		$writer->print(join("\n", @out));
	 		$writer->close;
	 	};
	 	if ($@) {
	 		LOG->error($@);
	 		return;
	 	}
	}

	return 1;
}

sub config_epel_repo {
	my $self = shift;

	my @config_files = qw|/etc/yum.repos.d/epel.repo|;
	for my $config_file(@config_files) {
		next if (!-f $config_file);
		LOG->notice("patch $config_file");
	 	eval {
			$config_file = file($config_file);
	     	my @lines = $config_file->slurp or die $!;
	     	my @out;
	 		for my $line(@lines) {
	 			chomp($line);
	 			# baseurl=http://download.fedoraproject.org/pub/epel/6/$basearch
				# #mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=epel-6&arch=$basearch

	 			if ($line=~/^\#baseurl=(.*)$/) {
	 				push @out, "baseurl=$1";
	 			} elsif ($line=~/^mirrorlist=(.*)$/) {
	 				push @out, "#mirrorlist=$1";
	 			} else {
	 				push @out, $line;
	 			}
	 		}

	 		my $writer = $config_file->open('w') or die $!;
	 		$writer->print(join("\n", @out));
	 		$writer->close;
	 	};
	 	if ($@) {
	 		LOG->error($@);
	 		return;
	 	}
	}

	return 1;
}

sub config_apache_httpd {
	my $self = shift;
 	my $config_file = file($self->{ws_apache_home}, 'conf/httpd.conf');
	LOG->notice("patch $config_file");
 	eval {
     	my @lines = $config_file->slurp or die $!;
     	my @out;
     	my $first_patch = 1;
 		for my $line(@lines) {
 			chomp($line);
 			if ($line=~/^Listen \d+/) {
 				push @out, "Listen " . $self->{ws_port};
 			} elsif ($line=~/LoadModule ssl_module modules\/mod_ssl\.so/) {
 				push @out, "LoadModule ssl_module modules/mod_ssl.so";
 			#CustomLog "logs/access_log" common
 			} elsif ($line=~/^\s*CustomLog "logs\/access_log" common/) {
 				push @out, '#CustomLog "logs/access_log" common';
 			} elsif ($line=~m|LoadModule proxy_module modules/mod_proxy\.so|) {
 				push @out, "LoadModule proxy_module modules/mod_proxy.so";
 			} elsif ($line=~m|LoadModule proxy_connect_module modules/mod_proxy_connect\.so|) {
 				push @out, "LoadModule proxy_connect_module modules/mod_proxy_connect.so";
 			} elsif ($line=~m|LoadModule proxy_http_module modules/mod_proxy_http\.so|) {
 				push @out, "LoadModule proxy_http_module modules/mod_proxy_http.so";
 			} elsif ($line=~m|LoadModule proxy_ajp_module modules/mod_proxy_ajp\.so|) {
 				push @out, "LoadModule proxy_ajp_module modules/mod_proxy_ajp.so";
 			} elsif ($line=~m|LoadModule socache_shmcb_module modules/mod_socache_shmcb\.so|) {
 				push @out, "LoadModule socache_shmcb_module modules/mod_socache_shmcb.so";
 			# } elsif ($line=~/LoadModule slotmem_shm_module/) {
 			# 	push @out, "LoadModule slotmem_shm_module modules/mod_slotmem_shm.so";

 			} else {
 				push @out, $line;
 			}
 			$first_patch = 0 if ($line=~m|conf/extra/httpd-proxy|);
 		}
 		if ($first_patch) {
	 		push @out, (
				'Include conf/extra/httpd-proxy.conf',
				'Include conf/extra/httpd-ssl.conf',
				'<Location />',
				'Order Deny,Allow',
				'Allow from all',
				'</Location>',
				'<Location /axis2>',
				'Order Deny,Allow',
				'Allow from all',
				'</Location>',
				'',
	 		);			
 		}

 		my $writer = $config_file->open('w') or die $!;

 		$writer->print(join("\n", @out));
 		$writer->close;
 	};
 	if ($@) {
 		LOG->error($@);
 		return;
 	}
	return 1;
}

sub config_apache_ajp {
	my $self = shift;

	my @out = (
		'<Location / >',
		'  ProxyPass ajp://localhost:' . $self->{ws_port_ajp} . '/ secret=getperf',
		'</Location>',
		'',
	);

 	my $config_file = file($self->{ws_apache_home}, 'conf/extra/httpd-proxy.conf');
	LOG->notice("patch $config_file");
 	eval {
 		my $writer = $config_file->open('w') or die $!;
 		$writer->print(join("\n", @out));
 		$writer->close;
 	};
 	if ($@) {
 		LOG->error($@);
 		return;
 	}
	return 1;
}

sub config_apache_ssl {
	my $self = shift;
 	my $config_file = file($self->{ws_apache_home}, 'conf/extra/httpd-ssl.conf');
	LOG->notice("patch $config_file");
 	eval {
     	my @lines = $config_file->slurp or die $!;
     	my @out;
     	my $first_patch = 1;
 		for my $line(@lines) {
 			chomp($line);
 			if ($line=~/^\s*Listen \d+/) {
 				push @out, "Listen " . $self->{ws_port_ssl};
 			} elsif ($line=~/<VirtualHost _default_:\d+>/) {
 				push @out, "<VirtualHost _default_:$self->{ws_port_ssl}>";
 			} elsif ($line=~/^\s*SSLCertificateFile\s+"/) {
 				push @out, 'SSLCertificateFile      "/etc/getperf/ssl/server/server.crt"';
 			} elsif ($line=~/^\s*SSLCertificateKeyFile\s+"/) {
 				push @out, 'SSLCertificateKeyFile   "/etc/getperf/ssl/server/server.key"';
 			} elsif ($line=~/SSLCACertificateFile\s+".*"$/) {
 				push @out, 'SSLCACertificateFile    "/etc/getperf/ssl/ca/ca.crt"';
 			} elsif ($line=~/SSLCertificateChainFile\s+".*"$/) {
 				push @out, 'SSLCertificateChainFile "/etc/getperf/ssl/inter/ca.crt"';
 			} elsif ($line=~/^\s*ServerName\s+/) {
 				push @out, "ServerName $self->{ws_server}:$self->{ws_port_ssl}";
 			} elsif ($line=~/SSLVerifyClient\s+/) {
 				push @out, "SSLVerifyClient  $self->{ws_apache_verify_client}";
 			} elsif ($line=~/^\s*ServerAdmin\s+/) {
 				push @out, 'ServerAdmin ' . $self->{ws_server_admin};
 			} elsif ($line=~/^(\s*TransferLog .*)$/) {
 				push @out, '# ' . $1;
 			} elsif ($line=~/^(\s*CustomLog .*)$/) {
 				push @out, '# ' . $1;
 				$line = shift(@lines);
 				push @out, '# ' . $line;
 			} else {
 				push @out, $line;
 			}
 		}

 		my $writer = $config_file->open('w') or die $!;

 		$writer->print(join("\n", @out));
 		$writer->close;
 	};
 	if ($@) {
 		LOG->error($@);
 		return;
 	}
	return 1;
}

sub config_apache_init_script {
	my $self = shift;

	my $ws_suffix = $self->{ws_suffix};
 	my $config_file = file("/etc/init.d", "apache2-${ws_suffix}");

	LOG->notice("patch $config_file");
 	eval {
 		my $writer = $config_file->open('w');
		unless ($writer) {
	        LOG->crit("Could not write $config_file: $!");
	        return;
		}
		chdir($self->{home});
		my $config_template = "script/template/apache2.tpl";
		my $tt = Template->new;
		my $vars = { 
        	ws_apache_home => $self->{ws_apache_home},
		};
		$tt->process($config_template, $vars, \my $output) or die $tt->error;
		$writer->print($output);
		$writer->close;
 		$self->change_owner('root', $config_file) or die $!;
 		chmod 0744, $config_file;
 	};
 	if ($@) {
 		LOG->error($@);
 		return;
 	}
	return 1;
}

sub config_sumup_init_script {
	my $self = shift;

 	my $config_file = file("/etc/init.d", "sumupctl");

	LOG->notice("patch $config_file");
 	eval {
 		my $writer = $config_file->open('w');
		unless ($writer) {
	        LOG->crit("Could not write $config_file: $!");
	        return;
		}
		chdir($self->{home});
		my $config_template = "script/template/sumupctl.tpl";
		my $tt = Template->new;
		my $vars = { 
        	getperf_home => $self->{home},
		};
		$tt->process($config_template, $vars, \my $output) or die $tt->error;
		$writer->print($output);
		$writer->close;
 		$self->change_owner('root', $config_file) or die $!;
 		chmod 0744, $config_file;
 	};
 	if ($@) {
 		LOG->error($@);
 		return;
 	}
	return 1;
}

sub config_apache_tomcat {
	my $self = shift;

 	my $config_file = file($self->{ws_tomcat_home}, 'conf/server.xml');
	LOG->notice("patch $config_file");
 	eval {
# 		$config_file->parent->mkpath;
 		my $writer = $config_file->open('w') or die $!;
		unless ($writer) {
	        LOG->crit("Could not write $config_file: $!");
	        return;
		}
		chdir($self->{home});
		my $config_template =  'script/template/axis2-server-8.5.88-xml.tpl';
		my $tt = Template->new;
		my $vars = { 
			ws_port_run => $self->{ws_port_run},
		   ws_port_ajp => $self->{ws_port_ajp}, 
		   ws_port_ssl => $self->{ws_port_ssl}, 
		};
		$tt->process($config_template, $vars, \my $output) || die $tt->error;
		$writer->print($output);
		$writer->close;
 	};
 	if ($@) {
 		LOG->error($@);
 		return;
 	}
	return 1;

 	# eval {
   #   	my @lines = $config_file->slurp or die $!;
   #   	my @out;
   #   	my $first_patch = 1;
 	# 	while (my $line = shift(@lines)) {
 	# 		chomp($line);

	# 		# @Comment out 8080 port
	# 		# +<!--
	# 	    # <Connector port="8080" protocol="HTTP/1.1"
	# 	    #            connectionTimeout="20000"
	# 	    #            redirectPort="8443" />
	# 		# +-->
 	# 		if ($line=~m|<Connector port="\d+" protocol="HTTP/1.1"|) {
 	# 			if ($line=~/patched/) {
 	# 				$first_patch = 0;
 	# 				push @out, $line;
 	# 			} else {
 	# 				push @out, '<!--';
 	# 				push @out, $line . ' patched';
 	# 				while (my $line = shift(@lines)) {
 	# 					chomp($line);
 	# 					push @out, $line;
 	# 					last if ($line=~m|/>|);
 	# 				}
 	# 				push @out, '-->';
 	# 			}

	# 		# @@ -20,7 +22,7 @@
	# 		# - <Server port="8005" shutdown="SHUTDOWN">
	# 		# + <Server port="58005" shutdown="SHUTDOWN">
	# 		} elsif ($line=~m|<Server port="\d+" shutdown="SHUTDOWN"|) {
 	# 			push @out, '<Server port="' . $self->{ws_port_run} . '" shutdown="SHUTDOWN">';

	# 		# @@ -90,7 +92,7 @@
	# 		#      <!-- Define an AJP 1.3 Connector on port 8009 -->
	# 		# -    <Connector port="8009" protocol="AJP/1.3" redirectPort="8443" />
	# 		# +    <Connector port="57009" protocol="AJP/1.3" redirectPort="8443" />
 	# 		} elsif ($line=~m|<Connector port="\d+" protocol="AJP/1.3" redirectPort="\d+"|) {
 	# 			push @out, '    <Connector port="' . $self->{ws_port_ajp} . 
 	# 				'" protocol="AJP/1.3" redirectPort="' . $self->{ws_port_ssl} . '" />';

 	# 		} else {
 	# 			push @out, $line;
 	# 		}
 	# 	}
 	# 	my $writer = $config_file->open('w') or die $!;

 	# 	$writer->print(join("\n", @out));
 	# 	$writer->close;
 	# 	$self->change_owner($self->{ws_tomcat_owner}, $config_file);
 	# };
 	# if ($@) {
 	# 	LOG->error($@);
 	# 	return;
 	# }
	# return 1;
}

sub change_owner {
	my ($self, $owner, $path) = @_;

	LOG->notice("change owner $owner to $path");
	my ($uid, $gid);
 	eval {
	 	($uid, $gid) = (getpwnam $owner)[2,3] or die "getpwnam $owner : $!";
 	};
 	if ($@) {
 		LOG->error($@);
 		return;
 	}

	return chown $uid, $gid, $path;
}

sub config_apache_tomcat_setenv_script {
	my $self = shift;

 	my $config_file = file($self->{ws_tomcat_home}, 'bin/setenv.sh');

	LOG->notice("patch $config_file");
 	eval {
# 		$config_file->parent->mkpath;
 		my $writer = $config_file->open('w') or die $!;
		unless ($writer) {
	        LOG->crit("Could not write $config_file: $!");
	        return;
		}
		chdir($self->{home});
		my $config_template =  'script/template/tomcat-setenv.tpl';
		my $tt = Template->new;
		my $vars = { 
        	getperf_home => $self->{home},
        	getperf_ws_role => $self->{ws_suffix},
		};
		$tt->process($config_template, $vars, \my $output) or die $tt->error;
		$writer->print($output);
		$writer->close;
 		$self->change_owner($self->{ws_tomcat_owner}, $config_file) or die $!;
 		chmod 0744, $config_file;
 	};
 	if ($@) {
 		LOG->error($@);
 		return;
 	}
	return 1;
}

sub config_apache_tomcat_init_script {
	my $self = shift;

	my $ws_suffix = $self->{ws_suffix};
 	my $config_file = file("/etc/init.d", "tomcat-${ws_suffix}");

	LOG->notice("patch $config_file");
 	eval {
 		my $writer = $config_file->open('w');
		unless ($writer) {
	        LOG->crit("Could not write $config_file: $!");
	        return;
		}
		chdir($self->{home});
		my $osname = `lsb_release -i -s`;
		chomp($osname);
		if ($osname!~/(CentOS|Ubuntu|Raspbian|RedHatEnterprise|AlmaLinux|OracleServer)/) {
	        LOG->crit("Can't find script/template/tomcat-$osname.tpl");
	        return;		
		}
		my $config_template = "script/template/tomcat-$osname.tpl";
		my $tt = Template->new;
		my $vars = { 
        	ws_tomcat_owner => $self->{ws_tomcat_owner},
        	ws_tomcat_dir => $self->{ws_tomcat_home},
		};
		$tt->process($config_template, $vars, \my $output) or die $tt->error;
		$writer->print($output);
		$writer->close;
 		$self->change_owner('root', $config_file) or die $!;
 		chmod 0744, $config_file;
 	};
 	if ($@) {
 		LOG->error($@);
 		return;
 	}
	return 1;
}

sub config_apache_axis2 {
	my $self = shift;

 	my $config_file = file($self->{ws_tomcat_home}, 'webapps/axis2/WEB-INF/conf/axis2.xml');
	LOG->notice("patch $config_file");
 	eval {
# 		$config_file->parent->mkpath;
 		my $writer = $config_file->open('w') or die $!;
		unless ($writer) {
	        LOG->crit("Could not write $config_file: $!");
	        return;
		}
		chdir($self->{home});
		my $config_template =  'script/template/axis2-1.5.6-xml.tpl';
		my $tt = Template->new;
		my $vars = { 
		    ws_port     => $self->{ws_port}, 
		    ws_port_ssl => $self->{ws_port_ssl}, 
		};
		$tt->process($config_template, $vars, \my $output) || die $tt->error;
		$writer->print($output);
		$writer->close;
 	};
 	if ($@) {
 		LOG->error($@);
 		return;
 	}
	return 1;
}

sub config_apache_axis2_web {
	my $self = shift;

 	my $config_file = file($self->{ws_tomcat_home}, 'webapps/axis2/WEB-INF/web.xml');
	LOG->notice("patch $config_file");
 	eval {
# 		$config_file->parent->mkpath;
 		my $writer = $config_file->open('w') or die $!;
		unless ($writer) {
	        LOG->crit("Could not write $config_file: $!");
	        return;
		}
		chdir($self->{home});
		my $config_template =  'script/template/axis2-web-1.5.6-xml.tpl';
		my $tt = Template->new;
		my $vars = { 
        	ws_tomcat_dir => $self->{ws_tomcat_home},
		};
		$tt->process($config_template, $vars, \my $output) || die $tt->error;
		$writer->print($output);
		$writer->close;
 	};
 	if ($@) {
 		LOG->error($@);
 		return;
 	}
	return 1;
}


sub create_zabbix_repository_db {
	my $self = shift;
	my $zabbix_config = config('zabbix');

	my $zabbix_ver     = $zabbix_config->{ZABBIX_SERVER_VERSION};
	my $zabbix_pass    = $zabbix_config->{ZABBIX_ADMIN_PASSWORD}; 
	my $zabbixdb       = 'zabbix';
	my $rootpass       = $self->{mysql_passwd};
	my $zabbix_sql_dir = '';
	my $zabbix_sql_tar = '';
	my @zabbix_dirs = `find /usr/share/doc/zabbix-server-mysql-*/create -type d`;
	for my $zabbix_dir(@zabbix_dirs) {
		$zabbix_sql_dir = $zabbix_dir;
		$zabbix_sql_dir=~s/(\r|\n)//g;
		last if ($zabbix_dir=~/mysql-${zabbix_ver}/);
	}
	my @zabbix_tars = `ls /usr/share/doc/zabbix-server-mysql-*/create.sql.gz`;
	for my $zabbix_tar(@zabbix_tars) {
		$zabbix_sql_tar = $zabbix_tar;
		$zabbix_sql_tar=~s/(\r|\n)//g;
		last if ($zabbix_tar=~/mysql-${zabbix_ver}/);
	}
	if (!$zabbix_sql_dir && !$zabbix_sql_tar) {
		die "zabbix ${zabbix_ver} not installed\n";
	}

	my $is_exist_db = 0;
	my $drh = DBI->install_driver('mysql');
	my $dbh;
	if ($dbh = DBI->connect("dbi:mysql:${zabbixdb}",'root', $rootpass, 
		{ PrintError => 0, PrintWarn => 0 })) {
		if ($self->{force}) {
			$drh->func('dropdb', $zabbixdb, 'localhost', 'root', $rootpass, 'admin');
		} else {
			$is_exist_db = 1;
			warn "$zabbixdb DB is already exists. If you want to delete, please use --force option\n";
		}
		$dbh->disconnect();
	} 
	if (!$is_exist_db) {
		$drh->func('createdb', $zabbixdb, 'localhost', 'root', $rootpass, 'admin');
		$dbh = DBI->connect("dbi:mysql:mysql", 'root', $rootpass);
		$dbh->do("ALTER DATABASE $zabbixdb DEFAULT CHARACTER SET=utf8");
		# $dbh->do("GRANT ALL ON $zabbixdb.* TO $zabbixdb\@localhost IDENTIFIED BY '${rootpass}'");
        $dbh->do("CREATE USER $zabbixdb\@localhost IDENTIFIED BY '${rootpass}'");
        $dbh->do("GRANT ALL PRIVILEGES ON $zabbixdb.* TO $zabbixdb\@localhost WITH GRANT OPTION");
		$dbh->disconnect();
		if ($zabbix_sql_dir) {
			for my $sql(qw/schema.sql images.sql data.sql/) {
				my $command = "mysql -uroot -p${rootpass} zabbix < ${zabbix_sql_dir}/$sql";
				if (system($command) != 0) {
					die "$!";
				}
			}
		} elsif ($zabbix_sql_tar) {
			# zcat create.sql.gz | mysql -uroot zabbix
			my $command = "zcat ${zabbix_sql_tar} | mysql -uroot -p${rootpass} zabbix";
			if (system($command) != 0) {
				die "$!";
			}
		}
	}

	{
		my $sql = "update zabbix.users set passwd=md5('${zabbix_pass}') where alias='Admin'";
		my $command = "mysql -uroot -p${rootpass} zabbix -e \"$sql\"";
		if (system($command) != 0) {
			die "$!";
		}
	}

	return 1;
}

sub create_zabbix_repository_db_ubuntu {
	my $self = shift;
	my $zabbix_config = config('zabbix');

	my $zabbix_ver  = $zabbix_config->{ZABBIX_SERVER_VERSION};
	my $zabbix_pass = $zabbix_config->{ZABBIX_ADMIN_PASSWORD}; 
	my $zabbixdb    = 'zabbix';
	my $rootpass    = $self->{mysql_passwd};

	my @zabbix_zips = `ls /usr/share/zabbix-server-mysql/*\.sql\.gz`;
	if (!@zabbix_zips) {
		die "zabbix ${zabbix_ver} not installed\n";
	}

	my $is_exist_db = 0;
	my $drh = DBI->install_driver('mysql');
	my $dbh;
	if ($dbh = DBI->connect("dbi:mysql:${zabbixdb}",'root', $rootpass, 
		{ PrintError => 0, PrintWarn => 0 })) {
		if ($self->{force}) {
			$drh->func('dropdb', $zabbixdb, 'localhost', 'root', $rootpass, 'admin');
		} else {
			$is_exist_db = 1;
			warn "$zabbixdb DB is already exists. If you want to delete, please use --force option\n";
		}
		$dbh->disconnect();
	} 
	if (!$is_exist_db) {
		$drh->func('createdb', $zabbixdb, 'localhost', 'root', $rootpass, 'admin');
		$dbh = DBI->connect("dbi:mysql:mysql", 'root', $rootpass);
		$dbh->do("GRANT ALL ON $zabbixdb.* TO $zabbixdb\@localhost IDENTIFIED BY '${rootpass}'");
		$dbh->disconnect();
		for my $zabbix_zip_base(qw/schema images data/) {
			my $zabbix_zip = "/usr/share/zabbix-server-mysql/${zabbix_zip_base}.sql.gz";
			my $command = "sudo zcat ${zabbix_zip} | mysql -u${zabbixdb} -p${rootpass} ${zabbixdb}";
			print $command . "\n";
			if (system($command) != 0) {
				die "$!";
			}
		}
	}

	{
		my $sql = "update zabbix.users set passwd=md5('${zabbix_pass}') where alias='Admin'";
		my $command = "mysql -uroot -p${rootpass} zabbix -e \"$sql\"";
		if (system($command) != 0) {
			die "$!";
		}
	}

	return 1;
}

sub deploy_agent_module {
	my $self = shift;

	my $agent_source_home = dir($self->{home}, 'module/getperf-agent');
	my $major_ver   = $self->{agent_major_ver};
	my $build       = $self->{agent_build};
	my $build_date  = $self->{agent_build_date};
	my $getperf_ver = file($self->{home}, 'RELEASE')->slurp;
	$getperf_ver =~s/(\r|\n)//g;

	# Check Agent BUILD
	my $build_file = file($agent_source_home, 'BUILD');
	if (-f $build_file) {
		my $build_json = $build_file->slurp;
		my $build_info = decode_json($build_json);
		$build      = $build_info->{BUILD};
		$build_date = $build_info->{BUILD_DATE};
	}

	# Copy CA Cert (cp /etc/getperf/ssl/ca/ca.crt src/conf/ssl/ca/)
	{
		my $ca_cert = file('/etc/getperf/ssl/ca/ca.crt');
		for my $ca_dest_postfix('src/conf/ssl/ca/', 'var/network/') {
			my $ca_dest = dir($agent_source_home, $ca_dest_postfix);
			my $copy_command = "cp ${ca_cert} ${ca_dest}";
			LOG->info("EXECUTE:$copy_command");
			die "not found ${ca_cert}\n"  if (! -f $ca_cert);
			if (! -d $ca_dest) {
				$ca_dest->mkpath || die "Can't mkpath $ca_dest";
			}
			if (system($copy_command) != 0) {
				die "$!";
			}
		}
	}
	
	# Make Web admin URL(https://ip:57443/axis2/services/GetperfService)
	my $ws_protocol = $self->{ws_protocol};
	my $ws_server = $self->{ws_admin_server};
	my $ws_port = $self->{ws_admin_port_ssl};
	my $url = "https://${ws_server}:${ws_port}/axis2/services/GetperfService";

	# Modify URL of Agent.pm
	{
		my $agent_config_source = file($agent_source_home, 'Agent.pm.sample');
		my $agent_config_target = file($agent_source_home, 'Agent.pm');
		eval {
			my @buffer = $agent_config_source->slurp;
			map { $_=~s/\$BUILD         = (\d+);/\$BUILD         = ${build};/g; } @buffer;
			map { $_=~s/URL_CM = (.*)/URL_CM = '${url}';/g; } @buffer;
	 		my $writer = $agent_config_target->open('w') or die $!;
	 		$writer->print(@buffer);
	 		$writer->close;
	 	};
	 	if ($@) {
	 		LOG->error($@);
	 		return;
	 	}
	}

	# Create Network config file for partial updates
	{
		my $network_config = file($agent_source_home, 'var/network/getperf_ws.ini');
		eval {
			my @buffer = (
				'REMHOST_ENABLE = true',
				'URL_CM = ' . $url,
				'URL_PM = ' . $url,
				'SITE_KEY = ZZZ9999',
			);
	 		my $writer = $network_config->open('w') or die $!;
	 		my $buf = join("\n", @buffer);
	 		$writer->print($buf);
	 		$writer->close;
	 	};
	 	if ($@) {
	 		LOG->error($@);
	 		return;
	 	}
	}

	# Modify include/gpf_common.h
	#define GPF_MAJOR_VER     2
	#define GPF_VERSION       "2.6.0"
	#define GPF_BUILD         4
	#define GPF_BUILD_DATE    "20150316.1615"

	{
		my $include_gpf_common_source = file($agent_source_home, 'include/gpf_common.h');
		eval {
			my @buffer = $include_gpf_common_source->slurp;
			map { 
				$_=~s/#define GPF_MAJOR_VER .*$/#define GPF_MAJOR_VER     ${major_ver}/g; 
				$_=~s/#define GPF_VERSION .*$/#define GPF_VERSION       "${getperf_ver}"/g; 
				$_=~s/#define GPF_BUILD_DATE .*$/#define GPF_BUILD_DATE    "${build_date}"/g; 
				$_=~s/#define GPF_BUILD .*$/#define GPF_BUILD         ${build}/g; 
			} @buffer;
	 		my $writer = $include_gpf_common_source->open('w') or die $!;
	 		$writer->print(@buffer);
	 		$writer->close;
	 	};
	 	if ($@) {
	 		LOG->error($@);
	 		return;
	 	}
	}

	# Zabbix configure
	if ($self->{use_zabbix}) {
		my $server_ip  = $self->{zabbix_server_ip};
		my $zabbix_source_var = dir($agent_source_home, 'var');
		if (!-d $zabbix_source_var) {
			LOG->warn("Not found '$zabbix_source_var'.\nRun 'rex prepare_zabbix' in advance.");
			goto loop;
#			return;
		}
		my $zabbix_agent_source_dir = dir($self->{home}, '/lib/agent/Zabbix');
		for my $os(qw/win unix/) {
			my $zabbix_agentd_conf = "/$os/script/zabbix/zabbix_agentd_src.conf";
			my $zabbix_agentd_conf_src  = file($zabbix_agent_source_dir, $zabbix_agentd_conf);
			my $zabbix_agentd_conf_dest = file($zabbix_source_var,       $zabbix_agentd_conf);
			if (!-f $zabbix_agentd_conf_src) {
				LOG->error("Not found '$zabbix_agentd_conf_src'.");
				next;
			}
			eval {
				my @buffer = $zabbix_agentd_conf_src->slurp;
				map { 
					$_=~s/__SERVER__/$server_ip/g; 
					$_=~s/__SERVER_ACTIVE__/$server_ip/g; 
				} @buffer;
		 		my $writer = $zabbix_agentd_conf_dest->open('w') or die "$! : $zabbix_agentd_conf_dest";
		 		$writer->print(@buffer);
		 		$writer->close;
		 	};
		 	if ($@) {
		 		LOG->error($@);
		 		return;
		 	}
		}
		print "update zabbix_agentd.conf\n";
	}
	loop:

	# archive (network-config-${hostname}.zip)
	{
		my $hostname = hostname;
		my $zip_name  = "network-config-${hostname}.zip";
		my $zip_path  = dir($self->{home}, "var/docs/agent/", $zip_name);
		unlink ${zip_path} if (-f ${zip_path});
		eval {
	 		$zip_path->parent->mkpath;
	 		chdir $agent_source_home . '/var';
	 		my @outputs = `zip -r ${zip_path} ./network`;
	 		for my $output(@outputs) {
				if ($output=~/Error|error/ && $output!~/adding|updating/) {
			 		LOG->error($output);
				}	 			
	 		}
	 	};
	 	if ($@) {
	 		LOG->error($@);
	 		return;
	 	}
	}

	# archive (getperf-2.x-Build?-source.zip)
	{
		my $zip_name  = "getperf-${major_ver}.x-Build${build}-source.zip";
		my $zip_path  = dir($self->{home}, "var/docs/agent/", $zip_name);
		my @zip_list  = qw/Agent.pm Makefile.* aclocal.m4 compile configure* delobj.bat 
			depcomp deploy.pl include install-sh make_header.pl m4 gsoap src win32 /;
		if ($self->{use_zabbix}) {
			push( @zip_list, 'var');
		}
		unlink ${zip_path} if (-f ${zip_path});
		@zip_list = map { "getperf-agent/$_" } @zip_list;
		my $zip_command = "zip -r ${zip_path} " . join(" ", @zip_list);
		LOG->info("EXECUTE: $zip_command"); 		
		eval {
	 		$zip_path->parent->mkpath;
	 		chdir $self->{home} . '/module';
	 		my @outputs = `$zip_command`;
	 		for my $output(@outputs) {
				if ($output=~/Error|error/ && $output!~/adding|updating/) {
			 		LOG->error($output);
				}	 			
	 		}
	 	};
	 	if ($@) {
	 		LOG->error($@);
	 		return;
	 	}
	 	print "ARCHIVED: ${zip_path}\n";	
	}

	return 1;
}

sub config_graphite_init_script {
	my $self = shift;

 	my $config_file = file("/etc/graphite-web/local_settings.py");
 	my $graphite_config = config('graphite');

	LOG->notice("patch $config_file");
 	eval {
 		my $writer = $config_file->open('a');
		unless ($writer) {
	        LOG->crit("Could not write $config_file: $!");
	        return;
		}
		my @buffer = (
			"SECRET_KEY = '$graphite_config->{GRAPHITE_SECRET_KEY}'",
			"TIME_ZONE = '$graphite_config->{GRAPHITE_TIME_ZONE}'",
			"",
			"DATABASES = {",
			"  'default': {",
			"    'NAME': '$graphite_config->{GRAPHITE_DB}',",
			"    'ENGINE': 'django.db.backends.mysql',",
			"    'USER': '$graphite_config->{GRAPHITE_DB_USER}',",
			"    'PASSWORD': '$graphite_config->{GRAPHITE_DB_PASS}',",
			"    'HOST': 'localhost',",
			"    'PORT': '3306',",
			"  }",
			"}",
			"",
		);

		my $output = join("\n", @buffer);
		$writer->print($output);
		$writer->close;
 		$self->change_owner('root', $config_file) or die $!;
 		chmod 0744, $config_file;
 	};
 	if ($@) {
 		LOG->error($@);
 		return;
 	}
	return 1;
}

sub create_graphite_repository_db {
	my $self = shift;
 	my $graphite_config = config('graphite');

	my $graphitedb    = 'graphite';
	my $rootpass    = $self->{mysql_passwd};
	my $graphite_script  = '/usr/lib/python2.6/site-packages/graphite/manage.py';
	if (!$graphite_script) {
		die "graphite '${graphite_script}' not installed\n";
	}

	my $is_exist_db = 0;
	my $drh = DBI->install_driver('mysql');
	my $dbh;
	if ($dbh = DBI->connect("dbi:mysql:${graphitedb}",'root', $rootpass, 
		{ PrintError => 0, PrintWarn => 0 })) {
		if ($self->{force}) {
			$drh->func('dropdb', $graphitedb, 'localhost', 'root', $rootpass, 'admin');
		} else {
			$is_exist_db = 1;
			warn "$graphitedb DB is already exists. If you want to delete, please use --force option\n";
		}
		$dbh->disconnect();
	} 
	if (!$is_exist_db) {
		$drh->func('createdb', $graphitedb, 'localhost', 'root', $rootpass, 'admin');
		$dbh = DBI->connect("dbi:mysql:mysql", 'root', $rootpass);
		$dbh->do("GRANT ALL ON $graphitedb.* TO $graphitedb\@localhost IDENTIFIED BY '$graphite_config->{GRAPHITE_DB_PASS}'");
		$dbh->disconnect();
	}

	{
		# my $options = "--verbosity=0 --noinput";
		# my $command = "sudo ${graphite_script} syncdb ${options}";
		my $command = "sudo ${graphite_script} syncdb --noinput";
		if (system($command) != 0) {
			die "$!";
		}
	}

	return 1;
}

sub influx_cli {
	my ($self, $sql, $database) = @_;
 	my $influx_config = config('influx');

 	my $cli = $influx_config->{INFLUX_CLI};
 	my $opt = ($database) ? "-database ${database}" : "";
 	my $cmd = "${cli} ${opt} -execute \"${sql}\"";
 	LOG->notice($cmd);
 	if (system($cmd) != 0) {
 		LOG->error($cmd);
 		return 0;
 	}
 	return 1;
}

sub create_influx_db {
	my $self = shift;
 	my $influx_config = config('influx');

	my $is_exist_db = 0;
	my $database = $influx_config->{INFLUX_DATABASE};
	my $db_user  = $influx_config->{INFLUX_DB_USER};
	my $db_pass  = $influx_config->{INFLUX_DB_PASS};

	if ($self->influx_cli("CREATE DATABASE ${database}")) {
		$self->influx_cli("CREATE RETENTION POLICY mypolicy ON ${database} DURATION 1d REPLICATION 1 DEFAULT") || return;
		$self->influx_cli("CREATE USER ${db_user} WITH PASSWORD '${db_pass}' WITH ALL PRIVILEGES", $database) || return;
	} else {
 		return;
	}

	return 1;
}

sub config_apache {
	my $self = shift;

	$self->config_apache_httpd || return;
	$self->config_apache_ajp   || return;
	$self->config_apache_ssl   || return;
	$self->config_apache_init_script || return;

	return 1;
}

sub config_tomcat {
	my $self = shift;
	$self->config_apache_tomcat || return;
	$self->config_apache_tomcat_setenv_script || return;
	$self->config_apache_tomcat_init_script || return;
	return 1;
}

sub config_axis2 {
	my $self = shift;
	$self->config_apache_axis2  || return;
	$self->config_apache_axis2_web  || return;
	return 1;
}

sub config_zabbix {
	my $self = shift;
	$self->create_zabbix_repository_db || return;
}

1;
