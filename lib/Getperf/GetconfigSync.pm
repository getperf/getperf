use strict;
use warnings;
package Getperf::GetconfigSync;
use Cwd;
use FindBin;
use Getopt::Long;
use Time::HiRes  qw( usleep gettimeofday tv_interval );
use Path::Class;
use File::Copy qw(copy move);
use File::Path::Tiny;
use JSON::XS;
use Getperf::Config 'config';
use Getperf::Extractor;
use Getperf::Purge;
use parent qw(Class::Accessor::Fast);
use Data::Dumper;
use Log::Handler app => "LOG";

__PACKAGE__->mk_accessors(qw/rsync_configs site_configs data_info elapse_command elapse_load/);

sub new {
	my ($class, $sitekey) = @_;
	config('base')->add_screen_log;

	my $MONITOR_CYCLE = 30;
	my $MONITOR_TIMES = 9;
	my $sites = config('sites');
	my $base  = config('base');

	# if  (!$sitekey) {
	# 	if (my $site_home_dir = dir($ENV{'SITEHOME'})) {
	# 		$sitekey = pop(@{$site_home_dir->{dirs}});
	# 	}
	# 	die "Invalid 'SITEHOME' env." if (!$sitekey);
	# }
	my $site_info     = Getperf::Data::SiteInfo->instance($sitekey);
	my $tmpfs         = $site_info->{tmpfs};
	my $site_home     = $site_info->{home};
	my $rsync_zip_dir = "$site_home/.grsync";

	mkdir($rsync_zip_dir) if (!-d $rsync_zip_dir);
	mkdir($tmpfs)         if (!-d $tmpfs);

	bless {
		sitekey       => $sitekey,
		site          => $site_info,
		lockfile      => "$site_home/.pid_monitor",
		rsync_zip_dir => $rsync_zip_dir,
		analysis      => $site_info->{analysis},
		datastore     => $site_home . "/src/test/resources/log",
		cycle         => $MONITOR_CYCLE,
		times         => $MONITOR_TIMES,
		purge         => 0,
		grep          => undef,
		zips          => undef,
		staging_files => undef,
	}, $class;
}

sub parse_command_option {
	my ($self, $args) = @_;

	my $usage = "Usage : sitesync: [--interval=i] [--times=i] [--purge] [--disable-delete] [--store=s] [--grep=s] rsync://xxx.xxx ...\n";

	my ($status_on, $status_off, $show_status, $lastzip, $ziplist);
	push @ARGV, grep length, split /\s+/, $args if ($args);
	GetOptions (
		'--interval=i'     => \$self->{cycle},
		'--times=i'        => \$self->{times},
		'--grep=s'         => \$self->{grep},
		'--store=s'        => \$self->{datastore},
		'--purge'          => \$self->{purge},
		'--disable-delete' => \$self->{disable_delete},
	) || die $usage;

	if (!@ARGV) {
		print "NO rsync://xxx.xxx\n";
		die $usage;
	}
	$self->{rsync_urls} = \@ARGV;

	return 1;
}

sub rsync {
	my ($self) = @_;

	my $base = config('base');
	my @rsync_urls = @{$self->{rsync_urls}};
	my $delete_opt = ($self->{disable_delete}) ? '' : '--delete';

	my $grep_opt = '';
	if( $self->{grep}) {
		my @keywords = split(/\s*,\s*/, $self->{grep});
		for my $keyword(@keywords) {
			$grep_opt .= " --include '*${keyword}*'"
		}
		$grep_opt .= " --exclude '*'"
	} else {
		$grep_opt = " --include '*Conf_*' --exclude '*'"
	}
	my $recievedZips;
	for my $rsync_url(@rsync_urls) {
		my $rsync_base = $rsync_url;
		$rsync_base=~s/\/$//g;		# trim tail '/'
		$rsync_base=~s/^.+\///g;	# trim rsync://{ip}/
		my $dest = $self->{rsync_zip_dir} . '/' . $rsync_base;
		my $command = "rsync -av $delete_opt $grep_opt $rsync_url $dest";
		LOG->notice($command);
		if (!File::Path::Tiny::mk($dest)) {
    	    LOG->crit("Could not make path '$dest': $!");
    	    return;
		}

		my @results = readpipe("$command 2>&1");
		# my @results = readpipe("cat rsync1.txt 2>&1");
		for my $result(@results) {
			chomp($result);
			if ($result=~/(ERROR|error)/) {
				LOG->crit($result);
			}
			if ($result=~/^arc_(.+)__(.+)_(\d+)_(\d+).zip$/) {
				my ($node, $job, $dt, $tm) = ($1, $2, $3, $4);
				my $zipPath = $rsync_base . '/' . $result;
				$recievedZips->{"${node}_${job}"}{"${dt}_${tm}"} = $zipPath;
			}
		}
	}
	for my $nodeKey(keys %{$recievedZips}) {
		my @dateKeys = reverse sort keys %{$recievedZips->{$nodeKey}};
		my $latestZip = $recievedZips->{$nodeKey}{$dateKeys[0]};
		LOG->info("extract $latestZip");
		push (@{$self->{zips}}, $latestZip) ;
	}
	return 1;
}

sub rebuild_analysis_dir {
	my ($self, $_rebuild_dirs) = @_;

	my $analysis = $self->{analysis};
	my %rebuild_dirs = %{$_rebuild_dirs};
	if (%rebuild_dirs) {
		for my $rebuild_dir (sort keys %rebuild_dirs) {
			# 時刻ディレクトリが 4桁の場合のディレクトリ補正
			# yia3vm2/MSSQL/20150619/1416
			if ($rebuild_dir=~m|^(.+?)/(.+?)/(\d{8})/(\d{4})|) {
				my $dest_dir = $rebuild_dir . '00';
				my $rc = rename("$analysis/$rebuild_dir", "$analysis/$dest_dir");
				if ($rc != 1) {
					LOG->crit("rename $rebuild_dir $dest_dir : $! [$rc]");
				}
			# 日付と時刻ディレクトリが 連結している場合のディレクトリ補正
			# y3icactie01a/HW/20150619_1457
			} elsif ($rebuild_dir=~m|^(.+?)/(.+?)/(\d{8})_(\d{4})|) {
				my $dest_dir_date = "$analysis/$1/$2/$3";
				my $dest_dir_time = $4 . '00';
				my $dest_dir = $dest_dir_date . '/' . $dest_dir_time;
				mkdir ($dest_dir_date) if (!-d $dest_dir_date);
				my $rc = rename("$analysis/$rebuild_dir", $dest_dir);
				if ($rc != 1) {
					LOG->crit("rename $rebuild_dir $dest_dir : $! [$rc]");
				}
			}
		}
	}
}

sub unzip {
	my $self = shift;

	my %rebuild_file_dirs = ();
	for my $zip (@{$self->{zips}}) {
		# arc_t00051900cap04__VSPP_20141003_1350.zip
		next if ($zip!~/arc_(.+?)__(.+?)_(\d+?)_(\d+?)\.zip/);
		my ($agent, $cat, $start_date, $start_time) = ($1, $2, $3, $4);

		my $target = file($self->{analysis}, $agent);
		if (!File::Path::Tiny::mk($target)) {
	        LOG->crit("Could not make path '$target': $!");
	        return;
		}
		my $rsync_zip_dir = $self->{rsync_zip_dir};
		LOG->notice("SyncExtract : ${zip}");
		my $command = "cd ${target}; unzip -o ${rsync_zip_dir}/${zip}";
		my @results = readpipe("$command 2>&1");
		for my $result(@results) {
			chomp($result);
			#   inflating: ELA/20141009/1400/cluster_all_stat.out
			if ($result=~/(inflating|extracting): (.*?)\s*$/) {
				next if ($2=~/^\./);	# skip .dot file
				my $staging_file = $agent . '/' . $2;
				# 時刻ディレクトリが 4桁の場合のパス補正、yia3vm2/MSSQL/20150619/1416
				if ($staging_file =~m|^(.+/.+/\d{4})/(.+?)$|) {
					my ($target_dir, $target_file) = ($1, $2);
					$rebuild_file_dirs{$target_dir} = 1;
					$staging_file = $target_dir . '00/' . $target_file;
				# 日付と時刻ディレクトリが 連結している場合のパス補正、yia3vm2/MSSQL/20150619_1416
				} elsif ($staging_file =~m|^(.+/.+\/\d{8})_(\d{4})/(.+?)$|) {
					my ($postfix_dir, $suffix_dir, $target_file) = ($1, $2, $3);
					my $target_dir = "${postfix_dir}_${suffix_dir}";
					$rebuild_file_dirs{$target_dir} = 1;
					$staging_file = "${postfix_dir}/${suffix_dir}00/${target_file}";
				}
				push(@{$self->{staging_files}}, $staging_file);
			} elsif ($result=~/unzip: (.*?)\s*$/) {
				LOG->error("unzip: $1 [SKIP]");
			}
		}
	}
	$self->rebuild_analysis_dir(\%rebuild_file_dirs);
	# print Dumper $self->{staging_files}; 
	return 1;
}

sub parseNodeDir {
	my ($file) = @_;

	# パターン１：リモート採取
	# win-jkssmti1tm6/VMHostConf/20200602/110000/esxi.ostrich/{all.json|...}
	# ⇒esxi.ostrich/VMHostConf
	# if ($file=~m|^(.+?)/(.+?)/(\d+)/(\d+)/(.+?)/(.+)$|) {
	if ($file=~m|^(.+?)/(.+?)/(\d+)/(\d+)/(.+?)/(.+)$|) {
		# print ("$1,$2,$3,$4,$5,$6\n");exit;
		my ($nodeName, $jobName) = ($5, $2);
		return $nodeName . '/' . $jobName;
	}

	# パターン２：ローカル採取
	# win-jkssmti1tm6/WindowsConf/20200602/110000/{cpu|...}
	# ⇒win-jkssmti1tm6/WindowsConf
	if ($file=~m|^(.+?)/(.+?)/(\d+)/(\d+)/(.+?)$|) {
		my ($nodeName, $jobName) = ($1, $2);
		return $nodeName . '/' . $jobName;
	}
	return "";
}

sub aggrigate {
	my $self = shift;

	if (!$self->{staging_files}) {
		return 0;
	}
	for my $staging_file (@{$self->{staging_files}}) {
 		my $sourcePath = $self->{analysis} . '/' . $staging_file;
 		my $targetDir = parseNodeDir($staging_file);
 		LOG->info("parse : $staging_file $targetDir");
 		next if ($targetDir eq "");
 		my $targetPath = $self->{datastore} . '/' . $targetDir;
 		LOG->info("store : $targetPath");
		dir($targetPath)->mkpath if (!-d $targetPath);
 		copy($sourcePath, $targetPath) or die "Copy failed: $!";
 	}
 	return 1;
}

sub purge {
	my $self = shift;

	my $purger = Getperf::Purge->new($self);
	if (!$purger) {
		my $msg = "Purge initialize error.";
		LOG->error($msg);
		die $msg;
	}
	return $purger->purge();
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
			LOG->error("$0 Still Running. Can't symlink $lockfile.");
			die;
		}
	}

	return 1;
}

sub run {
	my ($self) = @_;

	my $ntimes  = $self->{times};
	my $cycle   = $self->{cycle};
	my $sitekey = $self->{sitekey};
	my $start   = [gettimeofday];
	if ($self->lock_process) {
		my $think   = 0;
		LOG->notice("[sync] $sitekey");
		for my $cnt(1..$ntimes) {
			LOG->notice("monitor [$cnt/$ntimes]");
			if (1 < $cnt) {
				my $next    = ($cnt -1) * $cycle;
				my $elapsed = tv_interval($start);
				$think      = $next - $elapsed;
				if ($think > 0 && $cnt <= $ntimes) {
					usleep($think * 1000000);
				}
			}
			my $t1 = [gettimeofday];
			if ( 0 <= $think ) {
				$self->rsync;
				$self->unzip;
				$self->aggrigate;
				# $self->purge if ($self->{purge});
				$self->{zips} = undef;
			} else {
				LOG->notice("Skip for the previous execution time has exceeded the cycle");
			}
			my $elapsed_prcess = tv_interval ($t1);		
			LOG->notice("monitor [$cnt] elapsed : ${elapsed_prcess}, sleep : ${think}");
		}
		unlink $self->{lockfile};
	}

	return 1;
}

1;
