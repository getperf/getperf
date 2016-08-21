use strict;
use warnings;
package Getperf::Monitor;
use Cwd;
use FindBin;
use Getopt::Long;
use Time::HiRes  qw( usleep gettimeofday tv_interval );
use Path::Class;
use File::Path::Tiny;
use JSON::XS;
use Getperf::Config 'config';
use Getperf::Extractor;
use parent qw(Class::Accessor::Fast);
use Data::Dumper;
use Log::Handler app => "LOG";

__PACKAGE__->mk_accessors(qw/rsync_configs site_configs data_info elapse_command elapse_load/);

sub new {
	my $class = shift;
	config('base')->add_screen_log;

	my $MONITOR_CYCLE = 30;
	my $MONITOR_TIMES = 9;
	my $rsync = config('rsync');
	my $sites = config('sites');
	my $base = config('base');

	my $sitekey = undef;
	my $script  = file($0)->basename;
	my $lastzip_dir = $base->{staging_dir} . '/.lastzip';
	my $lockfile = $base->{log_dir} . '/.pid_monitor';
	my $timefile = $base->{log_dir} . '/.time_schedule';
	my $daemon  = ($script eq 'sync.pl') ? 0 : 1;

	dir($lastzip_dir)->mkpath if (!-d $lastzip_dir);

	# check current directory is site directory
	my $pwd = getcwd();
	if ($pwd=~/\/([^\/]+?)$/) {
		my $site_dir = $1;
		map { $sitekey = $_ if ($_ eq $site_dir); } @{$sites->{sites}};
	}
	bless {
		script        => $script,
		sitekey       => $sitekey,
		daemon        => $daemon,
		recover       => 0,
		fastrecover   => 0,
		rsync_configs => $rsync,
		site_configs  => $sites,
		lastzip_dir   => $lastzip_dir,
		lockfile      => $lockfile,
		timefile      => $timefile,
		cycle         => $MONITOR_CYCLE,
		times         => $MONITOR_TIMES,
		@_,
	}, $class;
}

sub parse_command_option {
	my ($self, $args) = @_;

	my $usage = "Usage : " . $self->{script} . "\n" . 
		"rsync.pl, monitor.pl:\n" .
		"\t[--config=file] [--interval=i] [--times=i]\n" .
		"sync.pl:\n" .
		"\t[--sitekey=s] [--on|--off|--status|--lastzip|--ziplist] [--recover|--fastrecover]\n";

	my ($status_on, $status_off, $show_status, $lastzip, $ziplist);
	push @ARGV, grep length, split /\s+/, $args if ($args);
	GetOptions (
		'--sitekey=s'   => \$self->{sitekey},
		'--on'          => \$status_on,
		'--off'         => \$status_off,
		'--status'      => \$show_status,
		'--lastzip'     => \$lastzip,
		'--ziplist'     => \$ziplist,
		'--recover'     => \$self->{recover},
		'--fastrecover' => \$self->{fastrecover},
		'--daemon=i'    => \$self->{daemon},
		'--config=s'    => \$self->{config},
		'--interval=i'  => \$self->{cycle},
		'--times=i'     => \$self->{times},
	) || die $usage;

	if ($self->{script} eq 'sync.pl') {
		unless ($self->{sitekey}) {
			die "Site Home not found in current directory\n\n" . $usage;
		}
		if ($status_off || $status_on || $show_status || $lastzip || $ziplist) {
			if ($status_off) {
				$self->set_site_status(0);
			} elsif ($status_on) {
				$self->set_site_status(1);
			} elsif ($show_status) {
				$self->show_site_status();
			} elsif ($lastzip) {
				$self->show_lastzip_status();
			} elsif ($ziplist) {
				$self->show_ziplist();
			}
			exit;
		}
	}
	return 1;
}

sub show_site_status {
	my ($self) = @_;
	if (defined(my $sitekey = $self->{sitekey})) {
		my $json = Getperf::Config::read_site_config($sitekey);
		my $buf = Getperf::Config::dump_site_config_json($sitekey, $json);
		print $buf . "\n";		
	}
}

sub show_lastzip_status {
	my ($self) = @_;
	my %last_zips = $self->read_lastzips;
	for my $sitekey(sort keys %last_zips) {
		for my $category(sort keys %{$last_zips{$sitekey}}) {
			for my $host(sort keys %{$last_zips{$sitekey}{$category}}) {
				my $zipfile = $last_zips{$sitekey}{$category}{$host};
				print "$sitekey\t$category\t$host\t$zipfile\n";
			}
		}
	}
}

sub show_ziplist {
	my ($self) = @_;
	my %zips = $self->read_zips;
	for my $sitekey(sort keys %zips) {
		for my $host(sort keys %{$zips{$sitekey}}) {
			for my $category(sort keys %{$zips{$sitekey}{$host}}) {
				my @ziplist   = @{$zips{$sitekey}{$host}{$category}};
				my $zip_count = scalar(@ziplist);
				my $zip_label = 'NoData';
				if ($zip_count == 1) {
					$zip_label = shift(@ziplist);
				} elsif ($zip_count > 1) {
					$zip_label = shift(@ziplist) . "\t" . pop(@ziplist);
					$zip_label .= "\t[$zip_count]";
				}
				print "$sitekey\t$category\t$host\n$zip_label\n";
			}
		}
	}
}

sub set_site_status {
	my ($self, $auto_aggregate) = @_;
	if (defined(my $sitekey = $self->{sitekey})) {
		my $json = Getperf::Config::read_site_config($sitekey);
		$json->{auto_aggregate} = $auto_aggregate;
		return Getperf::Config::write_site_config($sitekey, $json);
	} else {
		die "Sitekey not found";
	}	
}

sub read_lastzips {
	my ($self) = @_;

    my @sitekeys = ();
    my %last_zips = ();
    if (defined(my $sitekey = $self->{sitekey})) {
    	@sitekeys = ($sitekey);
	} else {
		@sitekeys = Getperf::Config::read_sitekeys();
	}
	for my $sitekey(@sitekeys) {
		my $lastzip_json = file($self->{lastzip_dir}, "${sitekey}.json");
		if ($lastzip_json->stat) {
			my $lastzip_json_text = $lastzip_json->slurp || die $@;
	    	my $lastzip = decode_json($lastzip_json_text);
	    	$last_zips{$sitekey} = $lastzip;
		}
	}
	return %last_zips;
}

sub parse_lastzips {
	my ($self, $_zips) = @_;

	my %last_zips = ();
	my %zips = %{$_zips};
	for my $sitekey(sort keys %zips) {
		for my $host(keys %{$zips{$sitekey}}) {
			for my $category(keys %{$zips{$sitekey}{$host}}) {
				my $zip_list = $zips{$sitekey}{$host}{$category};
				my $zip_file = pop(@{$zip_list});
				$last_zips{$sitekey}{$category}{$host} = $zip_file;
			}
		}
	}

	return %last_zips;
}

sub save_lastzips {
	my ($self, $_sites_lastzips) = @_;

	my %sites_lastzips = %{$_sites_lastzips};
	for my $sitekey(keys %sites_lastzips) {
		my $lastzips = $sites_lastzips{$sitekey};
		my $lastzips_json = encode_json($lastzips);
		my $lastzips_file = file($self->{lastzip_dir}, "${sitekey}.json");

		my $writer = file($lastzips_file)->open('w') || die "$! : $lastzips_file";
		$writer->print($lastzips_json);
		$writer->close;
	}
	return 1;
}

sub read_zips {
	my ($self) = @_;

	my $base = config('base');
	my %zips = ();
	my $sitekey = $self->{sitekey};
	my $base_node = Getperf::Data::SiteInfo->instance($sitekey)->{node};
	return if (!$base_node);
	my $zip_lists_dir = dir($base->{staging_dir}, 'json');
	return if (!-d $zip_lists_dir);
	my @zip_lists = dir ($zip_lists_dir)->children;
	for my $zips_json(@zip_lists) {
		my $filename = $zips_json->basename;
		next if ($filename!~/^(.+?)__(.+?)__(.+?)\.json$/);
		my ($site, $host, $cat) = ($1, $2, $3);
		my $target_node = Getperf::Data::SiteInfo->instance($site)->{node};
		next if (!defined($target_node) && $base_node ne $target_node);
		if ($zips_json->stat) {
			my $config_json_text = $zips_json->slurp || die $@;
	    	my $host_stat_zips = decode_json($config_json_text);
	    	push(@{$zips{$site}{$host}{$cat}}, @{$host_stat_zips});
		}
	}
	return %zips;
}

sub rsync {
	my ($self) = @_;

	my $base = config('base');
	my @zips = ();
	for my $sitekey(keys %{$self->rsync_configs}) {
		my $c = $self->{rsync_configs}{$sitekey};
		my $source = 'rsync://' . $c->{GETPERF_RSYNC_HOST} . '/' . $c->{GETPERF_RSYNC_SOURCE};
		my $dest = $base->{staging_dir} . '/' . $sitekey;
		my $command = "rsync -av --delete $source $dest";
		LOG->notice($command);
		if (!File::Path::Tiny::mk($dest)) {
    	    LOG->crit("Could not make path '$dest': $!");
    	    return;
		}

		my @results = readpipe("$command 2>&1");
		for my $result(@results) {
			chomp($result);
			if ($result=~/(ERROR|error)/) {
				LOG->crit($result);
			}
			if ($result=~/^arc_.*\.zip$/) {
				if (defined(my $keyword = $c->{GETPERF_RSYNC_ZIP_KEYWORD})) {
					if ($result=~/$keyword/) {
						push (@{$self->{zips}{$sitekey}}, $result) ;
					}
				} else {
					push (@{$self->{zips}{$sitekey}}, $result) ;
				}
			}
		}
	}
	return 1;
}

sub sync {
	my ($self) = @_;

	my $rc = 0;
	my %lastzips = $self->read_lastzips();

	my %zips = $self->read_zips();
	for my $sitekey(keys %zips) {
		my $site_config = Getperf::Config::read_site_config($sitekey);
		# Daemon process to reflect the on / off setting of the site
		if (defined(my $auto_aggregate = $site_config->{auto_aggregate})) {
			if ($self->{daemon} == 1 && $auto_aggregate == 0) {
				next;
			}
		}
		for my $host(keys %{$zips{$sitekey}}) {
			for my $category(keys %{$zips{$sitekey}{$host}}) {
				my @host_category_zips = @{$zips{$sitekey}{$host}{$category}};

				my @zip_list = ();
				if ($self->{recover}) {
					@zip_list = @host_category_zips;
				} elsif ($self->{fastrecover}) {
					my $lastzip = $lastzips{$sitekey}{$category}{$host} || '';
 					@zip_list = grep { $lastzip eq $_; } @host_category_zips;				
				} else {
					my $lastzip = $lastzips{$sitekey}{$category}{$host} || '';
 					@zip_list = grep { $lastzip lt $_; } @host_category_zips;
				}

				my $zip_n = scalar(@zip_list);
				LOG->notice("[sync] $sitekey, $host, $category, zip = $zip_n");
				next unless ($zip_n > 0);
				my $extractor = Getperf::Extractor->new(sitekey=>$sitekey, zips=>\@zip_list);
				$extractor->run('unzip');
			}
		}
	}
	my %updated_zips = $self->parse_lastzips(\%zips);
	$rc = $self->save_lastzips(\%updated_zips);

	return $rc;
}

sub unzip {
	my ($self) = @_;

	my @targets = ();
	for my $sitekey(keys %{$self->{zips}}) {
		my $zips = $self->{zips}{$sitekey};
		my $extractor = Getperf::Extractor->new(sitekey=>$sitekey, zips=>$zips);
		$extractor->run('unzip');
	}
	return 1;
}

sub lock_process {
	my ($self) = @_;

	my $lockfile = $self->{lockfile};
	if ( my $pid = readlink($lockfile) ) {
		if ( -d "/proc/${pid}/" ) {
			LOG->error("$0 Another Process Running : PID = [$pid, $$]");
			die;
		} else {
			unlink($lockfile);
			symlink( $$, $lockfile );
		}
	} else {
		if ( !symlink( $$, $lockfile ) ) {
			LOG->error("$0 Still Running.");
			die;
		}
	}
}

sub run_admin {
	my $base = config('base');
	my $schedule = $base->{admin_schedule};
	print Dumper($schedule);
	exit;
}

sub run {
	my ($self) = @_;

	my $ntimes  = $self->{times};
	my $cycle   = $self->{cycle};

	if ($self->{recover} || $self->{fastrecover}) {
		$ntimes = 0;
	}
	if ($self->lock_process) {
		my $t0 = [gettimeofday];
		run_admin();

		my $elapsed = 0;
		my $think   = 0;
		for my $cnt(0..$ntimes) {
			if (0 < $cnt && $cnt < $ntimes) {
				$think = $cycle * $cnt - $elapsed;
				if ( 0 < $think ) {
					usleep($think * 1000000);
				} else {
					next;
				}
			}
			$self->sync;
			$self->rsync;
			$self->unzip;
			$elapsed = tv_interval ($t0);		
			LOG->notice("monitor [$cnt] elapsed : ${elapsed}, sleep : ${think}");
		}
		unlink $self->{lockfile};
	}

	return 1;
}

1;
