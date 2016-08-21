use Rex; # -feature => ['1.0'];
use Rex::Commands::Gather;
use Data::Dumper;
use File::Path;
use lib $ENV{GETPERF_HOME} . '/lib';
use Getperf::Config 'config';

#$Rex::Logger::debug = 1;

desc "Get Disk Free";
task "disk_free", sub {
	my $params = shift;
   my $output = run "df -h .";
	say "DISKFREE:$params->{node}:$output";
};


desc "Get uptime";
task "uptime", sub {
	my $params = shift;
	my $output = run "uptime";
	say "UPTIME:$params->{node}:$output";
};

desc "Backup agent";
task "backup_agent", sub {
	my $params = shift;

	my $domain = $params->{domain};
	my $node   = $params->{node};
 	my $target = $ENV{SITEHOME} . "/var/archive/${domain}/${node}";

 	if (! -d $target) {
		eval { mkpath($target); };
		if ($@) { die "$@"; } 		
 	}

	file "/tmp/backup_agent.sh",
		content   => template("script/backup_agent.sh", 
			home => $params->{home});
	my $output = run "sh /tmp/backup_agent.sh";
	if ($? != 0) {
	   Rex::Logger::info("$output\nEXIT:$?", "error");
	}
	download "/tmp/getperf_config.tar.gz", "$target/getperf_config.tar.gz";

	return -1;
};

sub _upload {
	my ($params, $subdir) = @_;

	my $domain = $params->{domain};
	my $node   = $params->{node};
	my $home   = $params->{home} || '~/ptune';
	
	if (!defined($params->{file})) {
		Rex::Logger::info("--file=s must specified", "error");
		return;
	}
	my $output = run "mkdir -p ${home}/${subdir}";
	if ($? != 0) {
	   Rex::Logger::info("$output\nEXIT:$?", "error");
	   return;
	}
  	upload $params->{file}, "${home}/${subdir}/";

	if (defined($params->{extract})) {
		my $upload_file = $params->{file};
		$upload_file =~s/^.*\///g;
		my $output = run "cd ${home}/${subdir}; gzip -cd ${upload_file} | tar xvf -";
		if ($? != 0) {
		   Rex::Logger::info("$output\nEXIT:$?", "error");
		   return;
		}
	}
	return 1;
}

desc "Upload file to agent home";
task "upload", sub {
	my $params = shift;
	_upload($params);
};

desc "Upload file to agent home/script";
task "upload_script", sub {
	my $params = shift;

	_upload($params, 'script');
};

desc "Upload file to agent home/bin";
task "upload_bin", sub {
	my $params = shift;

	_upload($params, 'bin');
};

desc "Upload file to agent home/conf";
task "upload_conf", sub {
	my $params = shift;

	_upload($params, 'conf');
};

desc "Start Getperf agent";
task "agent_start", sub {
	my $params = shift;
	my $home   = $params->{home} || '/tmp';

	my $output = run "${home}/bin/getperfctl start";
	Rex::Logger::info("$output\nEXIT:$?", "error") if ($? != 0);
};

desc "Stop Getperf agent";
task "agent_stop", sub {
	my $params = shift;
	my $home   = $params->{home} || '/tmp';

	my $output = run "${home}/bin/getperfctl stop";
	Rex::Logger::info("$output\nEXIT:$?", "error") if ($? != 0);
};

desc "Restart Getperf agent";
task "agent_restart", sub {
	my $params = shift;
	my $home   = $params->{home} || '/tmp';

	for my $command(qw/stop start/) {
		my $output = run "${home}/bin/getperfctl ${command}";
		Rex::Logger::info("$output\nEXIT:$?", "error") if ($? != 0);
	}
};

sub get_zabbix_agent_platform_linux {
	my ($kernelrelease, $architecture) = @_;

	if ($kernelrelease!~/^(\d+)\.(\d+)\./) {  # 2.6.32-279.el6.x86_64
		Rex::Logger::info("Unkown kernelrelease : $kernelrelease", "error");
		return;
	}
	my $kernel_version = "$1.$2";
	if ($kernel_version < 2.4 ) {
		Rex::Logger::info("Unsupport kernel : $kernel_version", "error");
		return;
	}
	my $agent_kernel = ($kernel_version == 2.4) ? '2_4' : '2_6';
	if ($architecture!~/(x86_64|i\d+)/) {
		Rex::Logger::info("Unkown arch : $architecture", "error");
		return;
	}
	my $agent_arch = ($architecture eq 'x86_64') ? 'amd64' : 'i386';

	return "linux${agent_kernel}.${agent_arch}";
}	

sub get_zabbix_agent_download_file {
	my ($agent_platform) = @_;

	my $zabbix_config = config('zabbix');
	my %download_agent_platforms = map { $_ => 1 } @{$zabbix_config->{DOWNLOAD_AGENT_PLATFORMS}};
	if (!defined($download_agent_platforms{$agent_platform})) {
		Rex::Logger::info("No download list : $agent_platform", "error");
		return;	
	}
	my $zabbix_agent_version = $zabbix_config->{ZABBIX_AGENT_VERSION};
	return "zabbix_agents_${zabbix_agent_version}.${agent_platform}.tar.gz";
}

task "start_zabbix_agent", sub {
	my $params = shift;
	my $home   = $params->{home} || '~/ptune';

	my $command = "${home}/sbin/zabbix_agentd -c ${home}/zabbix_agentd.conf";
	my $output = run $command;
	if ($? != 0) {
	   Rex::Logger::info("$output\nEXIT:$?", "error");
	   return;
	}
};

task "stop_zabbix_agent", sub {
	my $params = shift;
	my $home   = $params->{home} || '~/ptune';

	my $command = "[ -f /tmp/zabbix_agentd.pid ] && kill `cat /tmp/zabbix_agentd.pid`";
	my $output = run $command;
	if ($? != 0) {
	   Rex::Logger::info("$output\nEXIT:$?", "error");
	   return;
	}
};
