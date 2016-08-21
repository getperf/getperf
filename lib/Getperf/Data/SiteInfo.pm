package Getperf::Data::SiteInfo;

use strict;
use warnings;
use Log::Handler app => "LOG";
use Getperf::Config 'config';
use Path::Class;
use Data::Dumper;
use Storable;
use parent qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors(qw/sitekey staging_dir analysis summary storage site node view lib html tmpfs/);

our $VERSION = '0.01';

my %instances = ();

sub get_site_info {
	my $sitekey = shift;
	my $base = config('base');

	my $site_info = undef;
	my $site_json = "site/${sitekey}.json";
	my $site_config = file($base->{config_dir}, $site_json);
	if (-f $site_config) {
		$site_info = Getperf::Config::read_config($site_json) || return;
	}
	return $site_info;
}

sub instance {
    my ($class, $sitekey, $site_home, $site_mysql_passwd) = @_;

    if (!defined($instances{$sitekey})) {
		my $base = config('base');

		my $site_info = get_site_info($sitekey);

		if (!defined($site_home)) {
			if ($site_info) {
				$site_home = $site_info->{home};
			} else {
				$site_home = $base->{site_dir} . '/' . $sitekey;			
			}
		}

		if (!defined($site_mysql_passwd)) {
			if ($site_info) {
				$site_mysql_passwd = $site_info->{access_key};
			}			
		}
    	my $staging_dir = $base->{staging_dir};
    	my $site_tmpfs  = undef;
    	if (defined(my $tmpfs_dir = $base->{tmpfs_dir})) {
    		$site_tmpfs = $tmpfs_dir . '/' . $sitekey;
    		dir($site_tmpfs)->mkpath if (-d $site_tmpfs);
    	}
	    $instances{$sitekey} = bless {
	    	sitekey  => $sitekey,
	    	home     => $site_home,
	    	analysis => $site_home . '/analysis',
	    	summary  => $site_home . '/summary',
	    	storage  => $site_home . '/storage',
	    	site     => $site_home . '/site',
	    	node     => $site_home . '/node',
	    	view     => $site_home . '/view',
	    	lib      => $site_home . '/lib',
	    	html     => $site_home . '/html',
	    	var      => $site_home . '/var',
	    	tmpfs    => $site_tmpfs,
	    	user     => $site_info->{user},
	    	group    => $site_info->{group},
	    	staging_dir       => $staging_dir . '/' . $sitekey,
	    	staging_idx       => $staging_dir . '/json/' . $sitekey,
	    	auto_aggregate    => $site_info->{auto_aggregate},
	    	auto_deploy       => $site_info->{auto_deploy},
	    	purge_data_hour   => $base->{purge_data_hour},
	    	site_mysql_passwd => $site_mysql_passwd,
	    }, $class;
	}
    return $instances{$sitekey};
}

sub get_instance_from_path {
    my ($class, $input_path) = @_;

   	if (my $result = $class->parse_path($input_path)) {
   		return $class->instance($result->{sitekey}, $result->{site_home});
    }
}

sub get_storable_info {
	my ($self, $key) = @_;
	my $storable_file = $self->{var} . '/' . $key;
	return if (!-f $storable_file);
	return retrieve($storable_file);
}

sub put_storable_info {
	my ($self, $key, $info) = @_;

	my $store_path = file($self->{var}, $key);
	if (!-d (my $store_dir = $store_path->parent)) {
		eval {
			$store_dir->mkpath;
		};
		if ($@) {
			LOG->crit("Can't make directory '$store_dir' : $!");
			return;
		}
	}
	return store($info, $store_path);
}

sub parse_path {
	my ($self, $input_path) = @_;

	my $result = undef;
	my $input_path_absolute = undef;
	eval {
		$input_path_absolute = file($input_path)->absolute->resolve->stringify;
	};
	if ($@) {
		LOG->crit("parse path error '../{site}/{analysis or node}/' : $input_path");
		die "$! : $input_path";
	}
	if ($input_path_absolute=~m|^(.*?)/(analysis\|node)(/\|$)|) {
		my $postfix = $1;
		# Real directory. Test or development use only
		if ($postfix =~/^(\.|)(.*)\/(.*?)$/) {
			$result->{site_home} = dir("$1$2", $3)->stringify;
			$result->{sitekey}  = $3;
		} else {
			$result->{sitekey} = $postfix;
		}
	}
	unless ($result) {
		LOG->crit("parse path error '../{site}/analysis/' : $input_path");
	}
	return $result;
}

sub switch_site_command_lib_link {
	my ($self) = @_;
	my $src_lib  = $self->{lib} . '/Getperf/Command/Site';
	my $dest_lib = config('base')->{lib_dir} . '/Getperf/Command/Site';
	if (!-d $src_lib) {
		LOG->crit("Site command link not found '$src_lib'");
		return;
	}

	return 1;
}

1;