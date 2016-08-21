use strict;
use warnings;
package Getperf::Node;
use Getopt::Long;
use Path::Class;
use Template;
use IO::CaptureOutput qw/capture/;
use JSON::XS;
use Crypt::CBC;
use Getperf::Config 'config';
use parent qw(Class::Accessor::Fast);
use Data::Dumper;
use Log::Handler app => "LOG";
use Getperf::Data::SiteInfo;
use Getperf::Data::NodeInfo;

__PACKAGE__->mk_accessors(qw/command/);

sub new {
	my ($class, $sitekey) = @_;
	config('base')->add_screen_log;

	if  (!$sitekey) {
		if (my $site_home_dir = dir($ENV{'SITEHOME'})) {
			$sitekey = pop(@{$site_home_dir->{dirs}});
		}
		die "Invalid 'SITEHOME' env." if (!$sitekey);
	}
	my $site_info = Getperf::Data::SiteInfo->instance($sitekey);
	bless {
		sitekey           => $sitekey,
		command           => undef,
		node_path         => undef,
		node_info         => undef,
		home              => $site_info->{home},
		lib               => $site_info->{lib},
		site_mysql_passwd => $site_info->{site_mysql_passwd},
	}, $class;
}

sub add_node_config_ssh {
	my ($self, $args) = @_;

	my $password = $self->{site_mysql_passwd};
	my $isok = 1;
	for my $key(qw/user pass home/) {
		if (!$args->{$key}) {
			print "ERROR: --${key} must be specified\n";
			$isok = 0;
		}
		if ($key eq 'pass') {
			my $plain_text = $args->{$key};
			my $cbc = Crypt::CBC->new({key => $password, cipher => 'Blowfish' });
			$args->{$key} = $cbc->encrypt_hex($plain_text);
		}
	}
	if (!$isok) {
		return;
	}

	my $node_count = 0;
	my $node_infos = $self->{node_info};
	my $buf = JSON::XS->new->pretty(1)->canonical(1)->encode ($args);
	my $add_config_count = $node_infos->write('ssh.json', $buf);

	# refresh .ssh/known_hosts
	my $node = $node_infos->fetch_first_node;
	my $home = $ENV{'HOME'};
	while($node) {
		if (my $host = $node->{node_info}->{ip}) {
			$self->exec_command("ssh-keygen -R $host") || die "ssh-keygen failed";
			$self->exec_command("ssh-keyscan -H $host >> ${home}/.ssh/known_hosts") || die "ssh-keygen failed";

		}
		$node = $node_infos->fetch_next_node;
	}

	return 1;
}

sub add_node_config_node_dir {
	my ($self, $node_dir) = @_;

	my $node_count = 0;
	my $node_infos = $self->{node_info};

	my $node = $node_infos->fetch_first_node;
	while($node) {
		my $domain_name = $node->{domain};
		my $node_name   = $node->{node};
		my $info_file   = 'node_path.json';

		$node = $node_infos->fetch_next_node;
		my $info_path = file($node_infos->{site_info}->{home}, 'node', $domain_name, $node_name, 'info', $info_file);
		if (-f $info_path) {
			LOG->error("'$info_path' already exists. Remove the file if you update.");
			return;
		}
		my $info_path_dir = $info_path->parent;
		$info_path_dir->mkpath if (!-d $info_path_dir);
		my $buf = JSON::XS->new->pretty(1)->canonical(1)->encode ({node_path => "${node_dir}/${node_name}"});
		my $writer = $info_path->open('w') || die "$! : $info_path";
		$writer->print($buf);
		$writer->close;
	}

	return 1;
}

sub retrieve_node_ssh_info {
	my ($self) = @_;

	my @node_ssh_infos;
	my $ip_lookup = $self->{node_info}->{ip_lookup};
	if (!$ip_lookup) {
		die "ip lookup table of '/etc/hosts', '.hosts' not found";
	}
	dir($self->{home}, $self->{node_path})->recurse(callback => sub {
		my $config_file = shift;
		if ($config_file=~m|node/(.+)/(.+)/info/ssh\.json$|) {
			my ($domain, $node) = ($1, $2);
			my $node_ssh_info_json = $config_file->slurp;
			my $node_ssh_info = decode_json($node_ssh_info_json);
			$node_ssh_info->{domain} = $domain;
			$node_ssh_info->{node}   = $node;
			if (my $ip = $ip_lookup->{$node}) {
				$node_ssh_info->{ip} = $ip;
	  			push(@node_ssh_infos, $node_ssh_info);
			} else {
				LOG->warn("IP lookup failed '$node'. skip");
			}
		}
	});
	return @node_ssh_infos;
}

sub make_rex_command {
	my ($self, $node, $command) = @_;

	my $cbc = Crypt::CBC->new({key => $self->{site_mysql_passwd}, cipher => 'Blowfish'});
	my $password = $cbc->decrypt_hex($node->{pass});
	my $rex_options = '';
	$rex_options = "--home=$node->{home}" if ($node->{home});
	my $rex_command = "rex -u $node->{user} -p ${password} -H $node->{ip} " .
		"$command --node=$node->{node} --domain=$node->{domain} ${rex_options}";

	return $rex_command;
}

sub execute_rex {
	my ($self, $args) = @_;

	my @node_infos = $self->retrieve_node_ssh_info();
	if (!@node_infos) {
		print "ERROR: node ssh info not found. you must run nodeconfig --add command\n";
		return;
	}

	my $command = join(" ", @$args);
	for my $node_info(@node_infos) {
		# rex -u psadmin -p psadmin -H 127.0.0.1 uptime --host=abc
		my $rex_command = $self->make_rex_command($node_info, $command);
		if (!$rex_command) {
			print "ERROR: command be specified\n";
			next;
		}
		print "EXECUTE : $rex_command\n";
		if (! $self->exec_command($rex_command) ) {
			print "ERROR: command failed\n";
			next;
		}
	}
	return 1;
}

sub parse_command_option {
	my ($self, $args) = @_;

	Getopt::Long::Configure("pass_through");
	my ($ip, $ssh_user, $ssh_password, $agent_home, $node_path);
	my $usage = "Usage : nodeconfig\n" .
		"\t--add={node_path} [--user=s] [--pass=s] [--home=s] [--node_dir=s]\n" .
		"\t--rex={node_path} {command} {--param=s} ...\n" .
		"\t[--hosts=s]\n\n" .
		"ex) nodeconfig --rex=node/HW/test1 upload --file=/tmp/getperf-CentOS6-x86_64.tar.gz\n"; 

	push @ARGV, grep length, split /\s+/, $args if ($args);
	my %config = ();
	my $node_list_tsv = undef;
	my $node_dir      = undef;
	my $opts = GetOptions (
		'--add=s'      => \$self->{command}{add},
		'--rex=s'      => \$self->{command}{rex},
		'--user=s'     => \$config{user},
		'--pass=s'     => \$config{pass},
		'--home=s'     => \$config{home},
		'--node_dir=s' => \$node_dir,
		'--hosts=s'    => \$node_list_tsv,
		'--help'       => \$self->{help},
	);

	if ($self->{command}{add}) {
		$self->{node_path} = $self->{command}{add};
	} elsif ($self->{command}{rex}) {
		$self->{node_path} = $self->{command}{rex};
	} else {
		die "\t[--add|--rex] Required.\n\n" . $usage;
	}
	my $node_info = Getperf::Data::NodeInfo->new(
		file_path => $self->{node_path}, node_list_tsv => $node_list_tsv
	);
	$self->{node_info} = $node_info;
	if ($self->{command}{add}) {
		my $rc = 1;
		if ($node_dir) {
			$rc &&= $self->add_node_config_node_dir($node_dir);
		}
		if (defined($config{user})) {
			$rc &&= $self->add_node_config_ssh(\%config);
		}
		return $rc;

	} elsif ($self->{command}{rex}) {
		return $self->execute_rex(\@ARGV);
	}

	return;
}

sub exec_command {
	my ($self, $command) = @_;

	my ($stdout, $stderr);
	capture sub {
	  system($command);
	} => \$stdout, \$stderr;

	LOG->info($command);
	print $stdout;
	if ($stderr=~/\s(ERROR|Error|usage|failed)\s/) {

		LOG->crit($stderr);
		LOG->crit($command);
		return;
	}
	return 1;
}

1;
