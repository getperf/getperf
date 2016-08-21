use strict;
use warnings;
package Getperf::Domain;
use Sys::Hostname;
use Getopt::Long;
use Path::Class;
use Template;
use DBI;
use Getperf::Config 'config';
use parent qw(Class::Accessor::Fast);
use Data::Dumper;
use Log::Handler app => "LOG";
use JSON::XS;

__PACKAGE__->mk_accessors(qw/command/);

sub new {
	my $class = shift;

	my $base = config('base');
	my $self = bless {
		site_key     => undef,
	 	home         => undef,
		domains      => undef,
		access_key   => undef,
		site_config_dir => $base->{site_config_dir},

		@_,
	}, $class;
	return $self;
}

sub read_site_config {
	my ($self, $site_key) = @_;

	my $site_config = file($self->{site_config_dir}, $site_key . ".json");
	if ($site_config->stat) {
		my $site_config_text = $site_config->slurp;
		my $json = decode_json($site_config_text);
		%$self = (%$self, %$json);
	} else {
		die "Not found : ${site_config}";
		return;
	}

	return 1;
}

sub write_site_config {
	my $self = shift;

	my $domain_json = '';
	if (defined($self->{domains})) {
		my @lists = map { "\"$_\"" } @{$self->{domains}};
		my $domains_text = join("," , @lists);
		$domain_json = 		"	\"domains\": [$domains_text],";
	}
	my @config_json = (
		"{" ,
		"	\"site_key\": \"$self->{site_key}\"," ,
		"	\"home\": \"$self->{home}\"," ,
		$domain_json,
		"	\"access_key\": \"$self->{access_key}\"" ,
		"}",
	);

	my $site_config = file($self->{site_config_dir}, $self->{site_key} . ".json");
	my $writer = file($site_config)->open('w') || die "$! : $site_config";
	$writer->print(join("\n", @config_json));
	$writer->close;

	return 1;
}

sub parse_command_option {
	my ($self, $args) = @_;

	my ($list_opt, $add_opt, $remove_opt);
	my $usage = 'Usage : domain.pl --list {site_key}' . "\n" .
		'        or ' . "\n" .
		'       domain.pl (--add|--remove) {site_key} {domain}' . "\n";

	push @ARGV, grep length, split /\s+/, $args if ($args);
	GetOptions (
		'--list'   => \$list_opt,
		'--add'    => \$add_opt,
		'--remove' => \$remove_opt,
	);
	unless (@ARGV) {
		print "No site_key\n" . $usage;
		return;
	}
	my $site_key = shift(@ARGV);
	if (! $self->read_site_config( $site_key )) {
		die "read site config error";
		return;
	}
	if ($list_opt) {
		return $self->list;
	} 

	unless (@ARGV) {
		print "No domain\n" . $usage;
		return;
	}
	my $domain = shift(@ARGV);
	if ($add_opt) {
		return $self->add($domain);
	} elsif ($remove_opt) {
		return $self->remove($domain);
	} else {
		print "Invarid command\n" . $usage;
		return;
	}

	return 1;
}

sub list {
	my $self = shift;

	if ($self->{domains}) {
		for my $domain(@{$self->{domains}}) {
			print $domain . "\n";
		}
	}
	return 1;
}

sub add {
	my ($self, $new_domain) = @_;

	if ($self->{domains}) {
		for my $domain(@{$self->{domains}}) {
			if ($domain eq $new_domain) {
				die "Domain alerady exsists $domain";
				return;
			}
		}
	}
	push(@{$self->{domains}}, $new_domain);

	return $self->write_site_config;
}

sub remove {
	my ($self, $remove_domain) = @_;

	my $found = 0;
	if ($self->{domains}) {
		my @new_domains;
		for my $domain(@{$self->{domains}}) {
			if ($domain eq $remove_domain) {
				$found = 1;
			} else {
				push @new_domains, $domain;
			}
		}
		if ($found) {
			$self->{domains} = \@new_domains;
			return $self->write_site_config;
		}
	}
	if (!$found) {
		die "Domain not found : $remove_domain";
		return;
	}
	return 1;
}

1;
