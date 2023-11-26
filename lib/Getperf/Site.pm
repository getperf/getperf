use strict;
use warnings;
package Getperf::Site;
use Cwd;
use Digest::SHA1;
use Sys::Hostname;
use Getopt::Long;
use Path::Class;
use Template;
use DBI;
use Git::Repository;
use Getperf::Container;
use Getperf::Config 'config';
use parent qw(Class::Accessor::Fast);
use Data::Dumper;
use Log::Handler app => "LOG";
use Getperf::Data::SiteInfo;

__PACKAGE__->mk_accessors(qw/command/);

sub new {
	my ($class, $argv) = shift;

	my $base = config('base');
	my $use_influxdb     = config('influx')->{GETPERF_USE_INFLUXDB} || 0;
	my $domain_templates = config('cacti')->{GETPERF_CACTI_DOMAIN_TEMPLATES} || ['Linux', 'Windows'];

	my $self = bless {
		command           => undef,
		home              => $base->{home},
		mysql_passwd      => $base->{mysql_passwd},
		staging_dir       => $base->{staging_dir},
		hostname          => $base->{ws_server_name},
		site_dir          => undef,
	 	site_home         => undef,
		sitekey           => undef,
		site_config       => undef,
		additional_sites  => undef,
		cacti_url         => undef,
		domain_templates  => $domain_templates,
		git_url           => undef,
		force             => 0,
		disable_git_clone => 0,
		site_mysql_passwd => undef,
		use_influxdb      => $use_influxdb,
		@_,
	}, $class;

	$base->add_screen_log;
	return $self;
}

sub parse_command_option {
	my ($self, $args) = @_;

	$self->{usage} = "Usage : initsite {site_dir}\n" .
	               "\t[--update] [--drop] [--template] [--force] " .
	               "[--init] [--report-rrd] " .
	               "[--disable-git-clone] [--mysql-passwd=s]\n" .
	               "\t[--addsite=\"AAA,BBB\"]\n";

	push @ARGV, grep length, split /\s+/, $args if ($args);
	my ($update_opt, $template_opt, $cacit_templates_opt, $sitekeys_opt, $drop_opt, $report_rrd_opt, $init_opt);
	GetOptions (
		'--update'            => \$update_opt,
		'--drop'              => \$drop_opt,
		'--init'              => \$init_opt,
		'--report-rrd'        => \$report_rrd_opt,
		'--template'          => \$template_opt,
		'--force'             => \$self->{force},
		'--disable-git-clone' => \$self->{disable_git_clone},
		'--mysql-passwd=s'    => \$self->{site_mysql_passwd},
		'--addsite=s'         => \$sitekeys_opt,
	) || die $self->{usage};
	unless (@ARGV) {
		print "No sitedir\n" . $self->{usage};
		return;
	}

	$self->parse_sitekeys_options($sitekeys_opt);
	$self->parse_site_home(shift(@ARGV)) || die $self->{usage};

	$self->{command} = 'report_rrd';
	if ($drop_opt) {
		$self->{command} = 'drop_site';
	} elsif ($init_opt) {
		$self->{command} = 'init_site';
	} elsif ($report_rrd_opt) {
		$self->{command} = 'report_rrd';
	} elsif ($update_opt) {
		$self->{command} = 'update_site';
	} elsif ($template_opt) {
		$self->{command} = 'update_template';
	}
	return 1;
}

sub parse_sitekeys_options {
	my ($self, $argv) = @_;
	if ($argv) {
		my @sitekeys = split(/,/, $argv);
		for my $sitekey(@sitekeys) {
			if ($sitekey!~/^\w[\w|_|-|\.]+$/) {
				die "Invalid sitekey: $sitekey\n" . $self->{usage};
			}
		}
		$self->{additional_sites} = \@sitekeys;
	}
}

sub parse_site_home {
	my ($self, $argv) = @_;

	my $base = config('base');
	my $site_dir = dir($argv)->absolute;
	my $sitekey  = $site_dir->basename;

	if ($sitekey!~/^\w+$/) {
		LOG->crit("Site key is required to be written in alphanumeric or '_' : $sitekey");
		return;
	}
	$self->{site_dir}    = $site_dir->stringify;
	$self->{site_home}   = $site_dir->parent->stringify;
	$self->{sitekey}     = $sitekey;
	$self->{site_config} = file($base->{site_config_dir}, "${sitekey}.json")->stringify;

	return 1;
}

sub run {
	my $self = shift;
	my $command = $self->command || undef;
	return if (!$command);

	if ($command eq 'init_site') {
        return $self->init_site;
	} elsif ($command eq 'drop_site') {
        return $self->drop_site;
	} elsif ($command eq 'update_site') {
        return $self->update_site;
	} elsif ($command eq 'update_template') {
        return $self->update_template;
	} elsif ($command eq 'report_rrd') {
        return $self->report_rrd;
	} else {
		return;
	}

	return 1;
}

sub drop_site {
	my $self = shift;

	my $sitekey  = $self->{sitekey};
	my $rootpass = $self->{mysql_passwd};
	my $site_dir = dir($self->{site_dir});
	my $current_dir = getcwd;
	if ($current_dir eq $site_dir) {
		die "Cannot remove '${sitekey}' home when cwd is the same '${site_dir}'.\n";
	}

	print "Drop all configuration file, MySQL DB, Git repository, site home directory " .
		  "for site '${sitekey}'.\nAre you OK ? [n] ";
	my $res = <>;
	$res =~ s/[\r\n]+//g;	# chomp
	if ($res ne 'y') {
		return;
	}

	# Stop sumup Daemon
	my $sumup_bin = $FindBin::Bin . "/sumup";
	system("${sumup_bin} stop");

	# Drop MySQL Database
	my $drh = DBI->install_driver('mysql');
	my $dbh = DBI->connect("dbi:mysql:${sitekey}",'root', $rootpass,
		                   { PrintError => 0, PrintWarn => 0 });
	if ($dbh) {
		LOG->notice("DropDB '${sitekey}'.");
		$drh->func('dropdb', $sitekey, 'localhost', 'root', $rootpass, 'admin');
	}

	# Drop Git repository
	my $base = config('base');
	my $git_dir  = $base->{home} . "/var/site/${sitekey}.git";
	if (-d $git_dir) {
		LOG->notice("Remove Git repository '${git_dir}'.");
		dir($git_dir)->rmtree || die "$! : $git_dir";
	}

	# Drop site home
	if (-d $site_dir) {
		LOG->notice("Remove site home '${site_dir}'.");
		dir($site_dir)->rmtree || die "$! : $git_dir";
	}

	# サイト構成ファイル削除
	my $site_config = $base->{home} . "/config/site/${sitekey}.json";
	if (-f $site_config) {
		LOG->notice("Remove site config '${site_config}'.");
		unlink $site_config || die "$! : $site_config";
	}
}

sub set_site_mysql_passwd {
	my $self = shift;

	if (!$self->{site_mysql_passwd}) {
		$self->{site_mysql_passwd} = Digest::SHA1::sha1_hex(rand() . $$ . {} . time);
	}
}

sub create_site_config {
	my ($self, $params) = @_;

	my $staging_dir = $self->{staging_dir} . '/' . $self->{sitekey};
	if (!-d $staging_dir) {
		mkdir $staging_dir || die "$! : $staging_dir";
	}

	my $site_config = file($self->{site_config});
	if (-f $site_config && !$self->{force}) {
		LOG->notice("[CREATE SITE CONFIG] $site_config is already exists. SKIP.");
		return;
	}

	my $domain_json = '';
	if ($self->{domains}) {
		my @lists = map { "\"$_\"" } @{$self->{domains}};
		my $domains_text = join("," , @lists);
		$domain_json = 		"	\"domains\": [$domains_text],";
	}
	# Get current process owner
	my $user  = scalar getpwuid($>);
	my $group = scalar getgrgid($));

	my @config_json = (
		"{" ,
		"	\"site_key\":   \"$self->{sitekey}\"," ,
		"	\"access_key\": \"$self->{site_mysql_passwd}\"," ,
		"	\"home\":       \"$self->{site_dir}\"," ,
		"	\"user\":       \"$user\"," ,
		"	\"group\":      \"$group\"," ,
		$domain_json,
		"	\"auto_aggregate\": $params->{auto_aggregate}," ,
		"	\"auto_deploy\":    $params->{auto_deploy}" ,
		"}",
	);
	my $writer = file($site_config)->open('w') || die "$! : $site_config";
	$writer->print(join("\n", @config_json));
	$writer->close;
	LOG->notice("[CREATE SITE CONFIG] $site_config.");
}


sub init_site {
	my $self = shift;

	my $params = {auto_aggregate => 1, auto_deploy => 1};

	$self->set_site_mysql_passwd;
	$self->create_site_config($params);
    $self->initialize_git_config;
    $self->create_sumup_command_skel;
    $self->git_push('first init');
    $self->create_cacti_site;
    $self->regist_influx_site_db;
    $self->add_addtional_sites if ($self->{additional_sites});
    $self->inform_site_complete;

	return 1;
}

sub update_site {
	my $self = shift;

	my $params = {auto_aggregate => 0, auto_deploy => 0};
	$self->set_site_mysql_passwd;
	$self->create_site_config($params);
    $self->create_sumup_command_skel;
    $self->create_cacti_site;
    $self->regist_influx_site_db;
    $self->add_addtional_sites if ($self->{additional_sites});
    $self->inform_site_complete;

	return 1;
}

sub update_template {
	my $self = shift;

	my $params = {auto_aggregate => 0, auto_deploy => 0};
	$self->set_site_mysql_passwd;
	$self->create_site_config($params);
    $self->create_sumup_command_skel;
    $self->create_cacti_site;
    $self->regist_influx_site_db;
    $self->inform_site_complete;

	return 1;
}

sub exec_command {
	my ($self, $command) = @_;

	my $result = readpipe("$command 2>&1");

	LOG->info($command);
	if ($result=~/(Error|usage|failed)/) {
		LOG->crit($result);
		LOG->crit($command);
		return;
	}
	return 1;
}

sub create_sumup_command_skel {
	my $self = shift;
	my $base = config('base');
	my $site_dir = $self->{site_dir};

	# Copy site configuration from {getperf_home}/lib
	#
	# {site_home}/analysis...                                              (step.1)
	# {site_home}/lib/Getperf/Command/Site/{domain}/... aggrigation script (step.2)
	#                /graph/{domain}/...                                   (step.2)
	#                      /color/...                                      (step.2)
	#                /agent/{domain}/...                                   (step.2)
	#                      /Zabbix/...                                     (step.2)
	#
	#                /cacti/template/0.8.8e/cacti.dmp                      (step.3)
	#                               /0.8.8e/cacti_templates-{domain}.xml   (step.3)
	#
	#            /Rexfile                                                  (step.4)
	#            /script                                                   (step.4)
	#            /.gitignore                                               (step.5)

	# step.1
	# Create site base directory 
    for my $dir(qw/analysis summary storage node view lib html/) {
    	my $site_dir_child = dir($site_dir, $dir);
    	if (!-d $site_dir_child) {
	    	mkdir $site_dir_child || die "$! : $site_dir_child";
    	}
    }
    # step.2
    # Copy Linux, a Windows domain directory under '{getperf_home}/lib'
    if ($self->{command} eq 'init_site') {
		for my $lib_base('Getperf/Command/Site', 'graph', 'agent', 'zabbix') {
			my @domains = @{$self->{domain_templates}};
			push(@domains, 'SystemInfo') if ($lib_base ne 'zabbix');
			push(@domains, 'color') if ($lib_base eq 'graph');
			push(@domains, 'Zabbix') if ($lib_base eq 'agent');
			for my $domain(@domains) {
				my $lib_path = "/lib/${lib_base}/${domain}";
				my $source = $base->{home} . $lib_path;
				my $target = $site_dir . $lib_path;
				if (!-d $target) {
					my $copy_sumup_command = "mkdir -p $target; cp -rp $source/* $target/";
					$self->exec_command($copy_sumup_command) || return;
				}
				if ($lib_base eq 'zabbix') {
					my $source = $base->{home} . "/lib/${lib_base}/${domain}.json";
					my $target = $site_dir . "/lib/${lib_base}/${domain}.json";
					if (-f $source && ! -f $target) {
						my $copy_sumup_command = "cp -p $source $target";
						$self->exec_command($copy_sumup_command) || return;
					}
				}
			}
		}
    } elsif ($self->{command} eq 'update_template') {
    	my $domain = $self->{sitekey};
    	$domain=~s/^t_//g;
		for my $lib_base('Getperf/Command/Site', 'graph', 'agent') {
			my @domains = ($domain);
			push(@domains, 'color') if ($lib_base eq 'graph');
			for my $domain(@domains) {
				my $lib_path = "/lib/${lib_base}/${domain}";
				my $target = $site_dir . $lib_path;
				if (!-d $target) {
					my $command = "mkdir -p $target";
					$self->exec_command($command) || return;
				}
			}
		}
    }

    # step.3
	{
		my $cacti_config = config('cacti');
		my $cacti_template_dir = config('cacti')->{GETPERF_CACTI_TEMPLATE_DIR};
		my %lib_paths = ("/lib/cacti/${cacti_template_dir}" => 1);

		for my $lib_path(sort keys %lib_paths) {
			my $target = dir($site_dir, $lib_path);
			if (!-d $target) {
				$target->mkpath;
			}
			if (!-f (my $cacti_dump_target = file($target, 'cacti.dmp'))) {
				my $cacti_dump_source = file($base->{home}, $lib_path, 'cacti.dmp');
				if (!-f $cacti_dump_source) {
					die "Cacti dump file not found : $cacti_dump_source";
				}
				$self->exec_command("cp ${cacti_dump_source} ${cacti_dump_target}") || return;
			}
			if ($self->{command} eq 'init_site') {
				my @templates = dir($base->{home}, $lib_path)->children;
				for my $template(@templates) {
					for my $domain(@{$self->{domain_templates}}) {
						if ($template=~/\/cacti-.+-${domain}\.xml/) {
							my $template_target = file($target, $template->basename);
							if (!-f $template_target) {
								$self->exec_command("cp ${template} ${template_target}") || return;
							}
						}
					}
				}
			}
		}
	}

	# step.4
    if ($self->{command} eq 'init_site') {
		my $source = $base->{home} . '/lib/site';
		my $target = $site_dir;
		my $copy_sumup_command = "cp -rp $source/* $target/";
		$self->exec_command($copy_sumup_command) || return;
	}

	# step.5
	my $gitignore = file($site_dir, '.gitignore');
	if (! -f $gitignore || $self->{force}) {
		my @ignore_dir = map { "/$_/" } qw/analysis summary storage html/;
		my $writer = $gitignore->open('w') || die "$!";
		my @ignores = (@ignore_dir, qw/ .pid .stdout .stderr /);
		$writer->print(join("\n", @ignores));
		$writer->close;
	}
	LOG->notice("[CREATE SUMUP SKEL] site_home=$site_dir");
}

sub create_cacti_repository_db {
	my $self = shift;

	my $sitekey = $self->{sitekey};
	my $rootpass = $self->{mysql_passwd};
	my $sitepass = $self->{site_mysql_passwd};
	my $rc       = 0;

	my $drh = DBI->install_driver('mysql');
	my $dbh = DBI->connect("dbi:mysql:${sitekey}",'root', $rootpass,
		                   { PrintError => 0, PrintWarn => 0 });
	if ($dbh && $self->{force}) {
		$drh->func('dropdb', $sitekey, 'localhost', 'root', $rootpass, 'admin');
		$dbh = undef;
	}
	if (!$dbh) {
		$drh->func('createdb', $sitekey, 'localhost', 'root', $rootpass, 'admin');
		$rc  = 1;
	}
	$dbh = DBI->connect("dbi:mysql:mysql", 'root', $rootpass);
	# $dbh->do("GRANT ALL ON $sitekey.* TO $sitekey\@localhost IDENTIFIED BY '$sitepass'");

	$dbh->do("CREATE USER IF NOT EXISTS '$sitekey'\@'%' IDENTIFIED BY '$sitepass'");
    $dbh->do("SET PASSWORD FOR '$sitekey'\@'%' = '$sitepass'");
	$dbh->do("GRANT all PRIVILEGES ON *.* TO '$sitekey'\@'%'  WITH GRANT OPTION");

	$dbh->disconnect();

	return $rc;
}

sub regist_influx_site_db {
	my $self = shift;
	my $sitekey = $self->{sitekey};

	if (!$self->{use_influxdb}) {
		return 1;
	}
	my $cmd = "influx -execute 'SHOW DATABASES'";
	my @databases = `$cmd`;
	if ($?) {
		LOG->error("Command faild : $cmd\nSkip");
		return;
	}
	my @db_exists = grep { chomp($_); $_ =~ /^$sitekey+$/ } @databases;
	if (@db_exists) {
		LOG->notice("influx database aleady exists : ${sitekey}\nSkip");
		return 1;
	}
	return $self->exec_command("influx -execute 'CREATE DATABASE ${sitekey}'");
}

sub inform_site_complete {
	my $self = shift;

	my @messages = (
		'',
		'Welcome to Getperf monitoring site !',
		'====================================',
		'',
		'Please memo these information.',
		'',
		'The site key is "' . $self->{sitekey} . '" .',
		'The access key is "' . $self->{site_mysql_passwd} . '" .',
		'',
		'"' . $self->{site_dir} .'" has created as a site home directory .',
		'Under this directory , it include the collected data , aggregated script , ',
		'graph definition , and a monitoring site html directory .',
		"\n",
	);

	push (@messages, (
		'If you want to clone the site remotely,',
		'',
		'git clone ' . $self->{git_url},
		"\n",
	)) if ($self->{git_url});

	push (@messages, (
		'URL for Cacti monitoring will be following .',
		'',
		$self->{cacti_url},
		'',
		'login user is "admin",and password is "admin" , after login , please change the password .',
		"\n",
	)) if ($self->{cacti_url});

	my $output = join("\n", @messages);
	print $output;

	my $readme_path = file($self->{site_dir}, 'site_info.txt');
	my $writer = $readme_path->open('w');
	unless ($writer) {
        LOG->crit("Could not write $readme_path: $!");
        return;
	}
	$writer->print($output);
	$writer->close;

	return 1;
}

sub git_run {
	my ($self, @argvs) = @_;

	my $sitekey = $self->{sitekey};
	my $output = Git::Repository->run(@argvs);
	if ($? == 0) {
	    LOG->info("[git run ${sitekey}] '$output'");
	    return 1;
	} else {
	    LOG->crit("[git run ${sitekey}] '$output' : $?");
	    return;
	}
}

sub initialize_git_config {
	my $self = shift;
	my $base = config('base');
    my $cwd  = getcwd();

	# cd $site_dir
	my $site_dir = $self->{site_dir};
	my $sitekey  = $self->{sitekey};
	my $git_dir  = $base->{home} . "/var/site/${sitekey}.git";
    my $user     = $base->{ws_tomcat_owner};
	my $server   = $base->{ws_server_name};
	my $git_url  = "ssh://${user}\@${server}/${git_dir}";

	# Force remove existing directory
	if ($self->{force}) {
		if (-d $git_dir) {
			dir($git_dir)->rmtree || die "$! : $git_dir";
		}
		if (-d $site_dir) {
			dir($site_dir)->rmtree || die "$! : $site_dir";
		}
	}

	# Case of git initialize with remote repos.
	if (!$self->{disable_git_clone}) {
	    # Create a new repo 
	    # (mkdir project.git && cd project.git && git init --bare --shared=group).
		if (!-d $git_dir) {
		    dir($git_dir)->mkpath || die "$! : $git_dir";
		    chdir $git_dir;
		    $self->git_run(qw/ init --bare /);
		    chdir $cwd;
		}
	    # Clone the remote repo 
	    # (git clone ssh://yourserver.com/var/gitroot/project.git)
		if (!-d $site_dir) {
		    $self->git_run( clone => $git_url, $site_dir , { quiet => 1 } );
		}
		$self->{git_url} = $git_url;

	# Case of git initialize local(git init .)
	} else {
		if (!-d $site_dir) {
		    $self->git_run( init => $site_dir , { quiet => 1 } );
		}
	}
	return 1;
}

sub git_push {
	my ($self, $commit_message) = @_;

	if ($self->{disable_git_clone}) {
		return;
	}
	my $site_dir = $self->{site_dir};
    my $git = Git::Repository->new( work_tree => $site_dir );
	$git->run('add', '.');
	$git->run('commit', '-a', '-m', $commit_message);
	my $output = $git->run('push', 'origin', 'master', { quiet => 1 } );
	if ($? != 0) {
	    LOG->crit("[git push ${site_dir}] '$output' : $?");
	    return;
	}
	return 1;
}

sub create_cacti_site {
	my $self = shift;

	my $cacti_conf = config('cacti');
	my $sitekey    = $self->{sitekey};
	my $rootpass   = $self->{mysql_passwd};
	my $sitepass   = $self->{site_mysql_passwd};
	my $hostname   = $self->{hostname};
	my $site_html  = $self->{site_dir} . '/html';
	my $cacti_home = $cacti_conf->{GETPERF_CACTI_HOME};
	my $cacti_html = $cacti_conf->{GETPERF_CACTI_HTML};
	$self->{cacti_url} = "http://${hostname}/${sitekey}";

	# Extract archive to Cacti site
	{
		my $cacti_archive_dir = $cacti_conf->{GETPERF_CACTI_ARCHIVE_DIR};
		my $cacti_archive = $cacti_conf->{GETPERF_CACTI_ARCHIVE};
		my $cacti_tar     = "$cacti_archive_dir/$cacti_archive";
		my $cacti_module  = $cacti_archive;
		$cacti_module=~s/.*(cacti-.*?)\.tar\.gz/$1/g;
		if (! -d "$site_html/$cacti_module") {
			$self->exec_command("cd ${site_html}; tar xvf ${cacti_tar}");
		}
		if (! -e "$site_html/cacit") {
			$self->exec_command("cd ${site_html}; ln -s ${cacti_module} cacti");
		}
	}

	# Create Cacti MySQL Repository
	if ($self->create_cacti_repository_db) {
		my $cacti_dump = $cacti_home . '/' . $cacti_conf->{GETPERF_CACTI_DUMP};
		my $cmd = "mysql -uroot -p${rootpass} ${sitekey} < ${cacti_dump}";
		$self->exec_command($cmd);
		LOG->notice("[IMPORT CACTI] dump_file=${cacti_dump}");
	}

	# Link Cacti site home to /var/www/html
	{
		my $cacti_link = file($cacti_html, $sitekey);
		if (-e $cacti_link && $self->{force}) {
			unlink $cacti_link;
		}
		if (!-e $cacti_link) {
			$self->exec_command("ln -s ${site_html}/cacti ${cacti_link}");
		}
	}

	# Link storage home to Cacti rra
	if (-d (my $cacti_rra = "$site_html/cacti/rra")) {
		$self->exec_command("rm -r $cacti_rra") || return;
		$self->exec_command("cd ${site_html}/cacti; ln -s ../../storage rra") || return;
	}

	# Patch cacti/include/config.php
	{
		chdir($cacti_home);
		my $config_template = $cacti_conf->{GETPERF_CACTI_CONFIG};
		my $tt = Template->new;
		my $vars = {
		    sitekey  => $sitekey,
		    sitepass => $sitepass,
		};

		$tt->process($config_template, $vars, \my $output) || die $tt->error;
		my $writer = file($site_html, 'cacti/include/config.php')->open('w');
		unless ($writer) {
	        LOG->crit("Could not write $site_html/cacti/include/config.php: $!");
	        return;
		}
		$writer->print($output);
		$writer->close;
	}

	return 1;
}


sub clone_site {
	my ($self, $src_sitekey, $dest_sitekey) = @_;

	my $base = config('base');
	my $dest_site_config_json = file($base->{site_config_dir}, "$dest_sitekey.json");

	if (!$self->{force} && -f $dest_site_config_json) {
		LOG->warning("File already exists '$dest_site_config_json'. SKIP");
	} else {
		my $site_config = Getperf::Data::SiteInfo::get_site_info( $src_sitekey );
		my $access_key = $site_config->{access_key};
		my $site_home  = $site_config->{home};

		my @config_json = (
			"{" ,
			"	\"site_key\":   \"$dest_sitekey\"," ,
			"	\"access_key\": \"$access_key\"," ,
			"	\"home\":       \"$site_home\"" ,
			"}",
		);
		LOG->notice("Write $dest_site_config_json");
		my $writer = $dest_site_config_json->openw || die "$! : $dest_site_config_json";
		$writer->print(join("\n", @config_json));
		$writer->close;
	}

	my $dest_staging_dir = $self->{staging_dir} . '/' . $dest_sitekey;
	if (!-d $dest_staging_dir ) {
		mkdir( $dest_staging_dir );
	}
}

sub add_addtional_sites {
	my ($self, $opts) = @_;

	my @new_sitekeys = @{$self->{additional_sites}};

	for my $new_sitekey(@new_sitekeys) {
		$self->clone_site( $self->{sitekey}, $new_sitekey);
	}
	return 1;
}

sub report_rrd {
	my ($self, $opts) = @_;
	my $sitekey = $self->{sitekey};
	my $rootpass = $self->{mysql_passwd};
	my $dbh = DBI->connect("dbi:mysql:${sitekey}",'root', $rootpass, {
        RaiseError        => 1,
        PrintError        => 1,
        mysql_enable_utf8 => 1,
    });
    my $query_rrds = "select distinct data_source_path from data_template_data";
    my $rows = $dbh->selectall_arrayref($query_rrds);
    my $reports;
    for my $row(@{$rows}) {
    	my $rrd_file = $row->[0];
    	next if !($rrd_file=~m|<path_rra>/(.+?)/(.+?)/(.+).rrd|);
    	my ($platform, $node, $metric) = ($1, $2, $3);
    	push(@{$reports->{$platform}->{$node}}, $metric);
    }
    for my $platform(sort keys %{$reports}) {
    	for my $node(sort keys %{$reports->{$platform}}) {
    		print "${platform}/${node}\n";
    	}
    }

	return 1;
}


1;
