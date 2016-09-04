package Getperf::SumUp;

use strict;
use warnings;
use Getopt::Long;
use Data::Dumper;
use FindBin;
use Path::Class;
use JSON::XS;
use Template;
use Time::Moment;
use Filesys::Notify::Simple;
use Log::Handler app => "LOG";
use Getperf::Config 'config';
use Getperf::Site;
use Getperf::Aggregator;
use Getperf::Extractor;
use Getperf::Data::DataInfo;
use parent qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors(qw/data_infos aggrigator args/);

sub new {
	my ($class, $sitekey) = @_;

	my $site_home = undef;
	if  (!$sitekey) {
		if (my $site_home_dir = dir($ENV{'SITEHOME'})) {
			$sitekey = pop(@{$site_home_dir->{dirs}});
			$site_home = "${site_home_dir}/${sitekey}";
		}
		die "Invalid 'SITEHOME' env." if (!$sitekey);
	}
	my $site_info = Getperf::Data::SiteInfo->instance($sitekey, $site_home);
	my $tmpfs     = $site_info->{tmpfs};

	my $lastzip_dir = config('base')->{staging_dir} . '/.lastzip';
	dir($lastzip_dir)->mkpath if (!-d $lastzip_dir);
	dir($tmpfs)->mkpath       if (!-d $tmpfs);

	bless {
		sitekey         => $sitekey,
		daemon          => 0,
		should_stop     => 0,
		recover         => 0,
		fastrecover     => 0,
		generate_script => 0,
		show_info       => 0,
		switch_on       => 0,
		switch_off      => 0,
		force           => 0,
		time_shift_file => undef,
		sumup_last_path => undef,
		input_paths     => undef,
		lastzip_dir     => $lastzip_dir,
		update_master   => undef,
		home            => $site_info->{home},
		lib             => $site_info->{lib},
    	staging_dir     => $site_info->{staging_dir},
    	staging_idx     => $site_info->{staging_idx},
    	tar_file        => undef,
    	export_domain   => undef,
    	import_domain   => undef,
	}, $class;
}

sub switch_screen_log {
	my $class = shift;

	my $base = config('base');
	$base->{stdout_log_level} = 'info';
	$base->add_screen_log;
}

sub parse_command_option {
	my ($self, $args) = @_;

	my $usage = 'Usage : sumup.pl ' . 
		"\n\t[[--init] {input file or directory}]" .
		"\n\t[--update-master,-u={domain}]" .
		"\n\t[--time-shift,-t={input file}]" .
		"\n\t[--last,-l={input dir}]" .
		"\n\t[[--export={domain}|--import={domain} [--force,-f]] [--archive={file.tar.gz}]]" .
		"\n\t[--daemon,-d] [--recover,-r|--fastrecover,-f]" .
		"\n\t[--info|--auto|--manual]" .
		"\n\t[start|stop|restart|status]\n\n" .
		"'--daemon' options run the zip directory monitoring in the foreground.\n" .
		"If you execute as daemon process, Run 'start' command.\n";

	push @ARGV, grep length, split /\s+/, $args if ($args);
	GetOptions (
		'--daemon'          => \$self->{daemon},
		'--recover'         => \$self->{recover},
		'--fastrecover'     => \$self->{fastrecover},
		'--init'            => \$self->{generate_script},
		'--info'            => \$self->{show_info},
		'--auto'            => \$self->{switch_on},
		'--manual'          => \$self->{switch_off},
		'--force'           => \$self->{force},
		'--time-shift=s'    => \$self->{time_shift_file},
		'--last=s'          => \$self->{sumup_last_path},
		'--update-master=s' => \$self->{update_master},
		'--export=s'        => \$self->{export_domain},
		'--import=s'        => \$self->{import_domain},
		'--archive=s'       => \$self->{tar_file},
	);

	for my $input_path(@ARGV) {
		$self->{input_paths}{$input_path} = 1;
	}

	if ($self->{daemon}) {
		return $self->run_as_daemon;

	} elsif ($self->{recover} || $self->{fastrecover}) {
		return $self->recover;
		
	} elsif ($self->{show_info}) {
		return $self->show_site_status;

	} elsif ($self->{update_master}) {
		return $self->update_master_script($self->{update_master});

	} elsif ($self->{switch_on} || $self->{switch_off}) {
		my $auto_aggregate = ($self->{switch_on}) ? 1 : 0;
		return $self->set_site_status($auto_aggregate);

	} elsif ($self->{export_domain} && $self->{tar_file}) {
		return $self->export_domain_plugin;

	} elsif ($self->{import_domain} && $self->{tar_file}) {
		return $self->import_domain_plugin;

	} elsif (my $input_path = $self->{time_shift_file}) {
		return $self->run_test($input_path);

	} elsif (my $sumup_last_path = $self->{sumup_last_path}) {
		return $self->run_last_data($sumup_last_path);

	} elsif ($self->{input_paths}) {
		return $self->run;

	} else {
		print "No input path\n" . $usage;
		return;
	}
}

sub run {
	my $self = shift;

	$self->switch_screen_log;
	my @input_files = ();
	for my $input_path(sort keys %{$self->{input_paths}}) {
		if (-f $input_path) {
			push(@input_files, $input_path);
		} elsif (-d $input_path) {
			dir($input_path)->recurse(callback => sub {
				my $input_file = shift;
				push(@input_files, $input_file) if (-f $input_file);
			});
		}
	}
	@input_files = sort @input_files;
	if ($self->{generate_script}) {
		return $self->generate_sumup_script(\@input_files);
	}
	my $aggregator = Getperf::Aggregator->new();
	my $start = [Time::HiRes::gettimeofday()];
	my $site_info;
	for my $input_file(@input_files) {
		my $data_info = Getperf::Data::DataInfo->new(
							file_path => $input_file, is_daemon => $self->{daemon}
						);
		$aggregator->run($data_info);
	}
	$aggregator->flush();
	my $count = scalar(@input_files);
	my $elapse_command = Time::HiRes::tv_interval($start);
	LOG->info("sumup : files = $count, elapse = $elapse_command");
	return 1;
}

sub prepare_time_shift_test_file {
	my ($self, $input_file) = @_;

	if ($input_file !~/^(.*\/t\/)(.+?)\/(.+?)\/(.+)$/ || ! -f $input_file) {
		return;
	}
	my ($host, $domain, $in_path) = ($2, $3, $4);
	my $source_dir  = dir($self->{home}, 't', $host, $domain);
	my $source_file = file($source_dir, $in_path);

	# Create ./analysis/{host}/{domain}/{YYYYMMDD}/{HHMISS}/{metric}.txt
	my $time_shift     = Time::Moment->now->minus_hours(1);
	my $time_shift_str = $time_shift->strftime("%Y%m%d/%H%M%S");
	my $target_dir     = dir($self->{home}, 'analysis', $host, $domain, $time_shift_str);
	my $target_file    = file($target_dir, $in_path);
	if (!-d $target_dir) {
		$target_dir->mkpath || die "Can't create $target_dir : $!";
	}

	my $copy_sumup_command = "cp -rp ${source_dir}/* ${target_dir}/";
	Getperf::Site::exec_command(undef, $copy_sumup_command) || return;
	return $target_file->stringify;
}

sub run_test {
	my ($self, $input_file) = @_;

	$self->switch_screen_log;

	my $aggregator = Getperf::Aggregator->new();
	my $start = [Time::HiRes::gettimeofday()];
	my $test_file = $self->prepare_time_shift_test_file($input_file);
	if ($test_file) {
		$self->generate_sumup_script([$test_file]);
		my $data_info = Getperf::Data::DataInfo->new(
			file_path => $test_file, time_shift_test => 1);
		$aggregator->run($data_info);
		$aggregator->flush();
	} else {
		print "Error : Test path must be './t/{host}/{domain}/...'\n";
	}
	my $elapse_command = Time::HiRes::tv_interval($start);
	LOG->info("sumup test : elapse = $elapse_command");
	return 1;
}

sub run_last_data {
	my ($self, $input_dir) = @_;

	$self->switch_screen_log;

	my $aggregator = Getperf::Aggregator->new();
	my $start = [Time::HiRes::gettimeofday()];
	if ($input_dir !~ m#analysis/(\w+)/(\w+)(/|)$#) {
		print "Error : Input path must be 'analysys/{host}/{domain}/'\n";
		return;
	}
	my %input_files;
	my $last_date_path = '';
	dir($input_dir)->recurse(callback => sub {
		my $input_file = shift;
		if (-f $input_file && $input_file =~ m#analysis/(\w+/\w+/\d+/\d+)/#) {
			my $date_path = $1;
			$last_date_path = $date_path if ($last_date_path lt $date_path);
			push (@{$input_files{$date_path}}, $input_file);
		}
	});
	print "IN:$last_date_path\n";
	for my $input_file(@{$input_files{$last_date_path}}) {
		my $data_info = Getperf::Data::DataInfo->new(
							file_path => $input_file, is_daemon => $self->{daemon}
						);
		$aggregator->run($data_info);
	}
	$aggregator->flush();
	my $count = scalar(@{$input_files{$last_date_path}});
	my $elapse_command = Time::HiRes::tv_interval($start);
	LOG->info("sumup : files = $count, elapse = $elapse_command");
	return 1;
}

sub cacti_cli_command {
	my ($self, $command) = @_;

	my $home = config('base')->{home};
	my $cacti_cli = "$home/script/cacti-cli";
	my $result = readpipe("$cacti_cli $command 2>&1");
	LOG->notice("$cacti_cli $command");
	if ($result=~/(ERROR|usage|failed)/) {
		LOG->crit($result);
		LOG->crit($command);
		return;
	}
	return 1;	
}

sub export_domain_plugin {
	my $self = shift;

	$self->switch_screen_log;
	my $domain = $self->{export_domain};
	if (!$self->cacti_cli_command("--export ${domain}")) {
		return;
	}
	chdir($self->{home});
	my @paths = ();
	my @base_paths = ("lib/Getperf/Command/Site/", "lib/graph/", "lib/agent/");
	for my $base_path(@base_paths) {
		my $target_path = $base_path . $domain;
		next if (!-d $target_path);
		push(@paths, $target_path);
		my $package_links = file($self->{home}, $target_path, 'package_links.json');
		if (-f $package_links) {
			my $package_links_text = $package_links->slurp;
			my $packages = decode_json($package_links_text);
			if ($packages) {
				for my $package(@$packages) {
					push(@paths, $base_path . $package);
				}
			} else {
				LOG->crit("Can't read JSON : ${package_links}");
				return;
			}
		}
	}

	# my $tar_file = file($self->{home}, '..', "config-${domain}.tar.gz");
	my $tar_file = $self->{tar_file};
	if (!$tar_file) {
		LOG->crit("file not found");
		return;
	}

	my $tar_command = 'tar cvf -';
	for my $path(@paths) {
		if (! -d $path) {
	        LOG->fatal("'$domain' directory not found: $path");
	        return;
		}
		$tar_command .= ' ' . $path;
	}

	# Add cacti template 'lib/cacti/template/0.8.8e/cacti-*.xml'
	my $template_base_path = "lib/cacti/template/template_links__${domain}.json";
	my $template_links = file($self->{home}, $template_base_path);
	if (-f  $template_links) {
		$tar_command .= ' ' . $template_base_path;
		my $template_links_text = $template_links->slurp;
		my $packages = decode_json($template_links_text);
		if ($packages) {
			for my $package(@$packages) {
				$tar_command .= ' ' . "lib/cacti/template/*/cacti-*-template-${package}.xml";
			}
		} else {
			LOG->crit("Can't read JSON : ${template_links}");
			return;
		}
	} else {
		$tar_command .= " lib/cacti/template/*/cacti-*-template-${domain}.xml";
	}

	$tar_command .= " | gzip > ${tar_file}";
	LOG->notice($tar_command);

	my $result = `$tar_command`;
	if ($result=~/(ERROR|usage|failed)/) {
		LOG->crit($result);
		LOG->crit($tar_command);
		return;
	}
	LOG->notice("save '$tar_file'.");

	return 1;
}

sub import_domain_plugin {
	my $self = shift;

	my $cacti_config = config('cacti');
	# template/0.8.8e
	my $cacti_template_dir = $cacti_config->{GETPERF_CACTI_TEMPLATE_DIR};
	$self->switch_screen_log;
	my $import_file = file($self->{tar_file});

	my $domain = $self->{import_domain};
	if ($import_file!~/\.tar\.gz$/) {
		LOG->crit("Invarid tar.gz file name '$import_file'.");
		return;
	}
	chdir($self->{home});
	my $isok = 1;
	my $buf = '';
	for my $path("lib/Getperf/Command/Site/${domain}", "lib/graph/${domain}", "lib/agent/${domain}") {
		if (-d $path) {
	        $buf .= "already exist directory '$path'.\n";
	        $isok = 0;
		}
	}
	my $template_alive = `ls lib/cacti/${cacti_template_dir}/cacti-*-template-${domain}.xml 2> /dev/null`;
	if ($template_alive) {
        $buf .= "already exist cacti template file. $template_alive\n";
        $isok = 0;
	}
	if (!$isok && !$self->{force}) {
		LOG->fatal("Please remove these files.\n$buf");
		return;
	}
	my $tar_command = "tar xvf ${import_file}";
	my $result = readpipe("$tar_command 2>&1");
	if ($result=~/(ERROR|usage|failed)/) {
		LOG->crit($result);
		LOG->crit($tar_command);
		return;
	}
	LOG->notice("load '$import_file'.");
	if (!$self->cacti_cli_command("--import ${domain}")) {
		return;
	}
	print "OK\n";
	
	return 1;
}

sub generate_script {
	my ($self, $template_path, $script_path, $infos) = @_;

	LOG->notice("create $script_path");
 	if (!-f $script_path) {
	 	eval {
	 		my $writer = $script_path->open('w');
			unless ($writer) {
		        LOG->crit("Could not write $script_path: $!");
		        return;
			}
			chdir(config('base')->{home});
			my $config_template = "script/template/" . $template_path;
			my $tt = Template->new;
			my $vars = { 
	        	domain     => $infos->{domain},
	        	class_name => $infos->{class_name},
	        	metric     => $infos->{metric},
			};
			$tt->process($config_template, $vars, \my $output) or die $tt->error;
			$writer->print($output);
			$writer->close;
	 	};
	 	if ($@) {
	 		LOG->error($@);
	 		return;
	 	}
	}
	return 1;
}

sub generate_sumup_script_from_template {
	my ($self, $script_path, $infos) = @_;

	LOG->notice("create $script_path");
	$self->generate_script('sumup_script.tpl', $script_path, $infos) || return;
 	my $master_path = file($script_path->parent, 'tt_Master.pm');
	$self->generate_script('sumup_master_script.tpl', $master_path, $infos) || return;
	return 1;
}

sub generate_sumup_script {
	my ($self, $_input_files) = @_;

	my %scripts = ();
	my @input_files = @{$_input_files};
	for my $input_file(@input_files) {
		my $data_info = Getperf::Data::DataInfo->new(file_path => $input_file);
		my $class_name = $data_info->{class_name};
		my $metric     = $data_info->{metric};
		if ($class_name && $metric) {
			$scripts{$metric}{$class_name} = $data_info->{file_name};
		}
	}
	for my $domain(keys %scripts) {
		my $script_dir = dir($self->{lib}, '/Getperf/Command/Site', $domain);
		if (!-d $script_dir) {
			eval {
				$script_dir->mkpath;
			};
			if ($@) {
				die "Mkdir error '$script_dir' : $@";
			}
		}

		for my $class_name(keys %{$scripts{$domain}}) {
			my $file_name   = $scripts{$domain}{$class_name};
			my $script_name = $class_name . ".pm";
			my $script_path = file($script_dir, $script_name);
			if (-f $script_path) {
				print "'$script_name' already exists.\n";
				print "If you want to create force, please remove '$script_path'.\n";
				next;
			}
			print "Generate $domain/$script_name\n";
			my $infos = {
	        	domain     => $domain,
	        	class_name => $class_name,
	        	metric     => $file_name,
			};
			$self->generate_sumup_script_from_template($script_path, $infos);
		}
	}
}

sub update_master_script {
	my ($self, $domain) = @_;

	$self->switch_screen_log;
	my $site_info   = Getperf::Data::SiteInfo->instance($self->{sitekey});
	my $master_data = Getperf::MasterData->new($site_info, $domain);

	if (-f (my $master = $master_data->{master})) {
		my $res = 'n';
		print "[WARNING] Master script exists : '$master'.";
		print "This script delete the script and copy from template.\n";
		print "Are you sure ? [${res}]";
		$res = <STDIN>;
		$res =~ s/[\r\n]+//g;
		if ($res eq 'y') {
			$master_data->backup;
		} else {
			return;
		}
	}

	return $master_data->regist;
}

sub run_as_daemon {
	my $self = shift;

	my $target = $self->{staging_idx};
    my $watcher = Filesys::Notify::Simple->new([ $target ]);

    $SIG{TERM} = sub {
        $self->{should_stop} = 1;
		LOG->notice("catch signal");
        kill 9, $$;
        exit 0;
    };

	LOG->notice("watch $target");
    until ($self->{should_stop}) {
		my @watch_files = ();
	    $watcher->wait(sub {
	    	for my $event (@_) {
	    		push( @watch_files, $event->{path} );
	    	}
		});
		LOG->notice("catch $target");
		my %zips = $self->read_zips(\@watch_files);
		$self->sync(\%zips);
		sleep 60;    	
    }
}

sub recover {
	my $self = shift;

	$self->switch_screen_log;
	my $target = $self->{staging_idx};
	my @watch_files = map { $_->absolute; } dir($target)->children;
	my %zips = $self->read_zips(\@watch_files);
	$self->sync(\%zips);
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

sub read_zips {
	my ($self, $zip_files) = @_;

	my $base = config('base');
	my %zips = ();
	my $sitekey = $self->{sitekey};
	for my $zips_json(@{$zip_files}) {
		$zips_json = file($zips_json) if (ref($zips_json) ne 'Path::Class::File');

		my $filename = $zips_json->basename;
		next if ($filename!~/^(.+?)__(.+?)__(.+?)\.json$/);
		my ($site, $host, $cat) = ($1, $2, $3);
		if ($zips_json->stat) {
			my $config_json_text = $zips_json->slurp || die $@;
	    	my $host_stat_zips = decode_json($config_json_text);
	    	push(@{$zips{$site}{$host}{$cat}}, @{$host_stat_zips});
		}
	}
	return %zips;
}

sub sync {
	my ($self, $_zips) = @_;

	my $rc = 0;
	my %lastzips = $self->read_lastzips();
	my %zips = %{$_zips};

	for my $sitekey(keys %zips) {
		for my $host(keys %{$zips{$sitekey}}) {
			for my $category(keys %{$zips{$sitekey}{$host}}) {
				my @host_category_zips = @{$zips{$sitekey}{$host}{$category}};

				my @zip_list = ();
				my $lastzip = $lastzips{$sitekey}{$category}{$host} || '';
				if ($self->{recover} || !$lastzip ) {
					@zip_list = @host_category_zips;
				} elsif ($self->{fastrecover}) {
 					if ($lastzip) {
	 					@zip_list = grep { $lastzip eq $_; } @host_category_zips;				
 					} else {
 						@zip_list = shift(@host_category_zips);
 					}
				} else {
 					@zip_list = grep { $lastzip lt $_; } @host_category_zips;
				}

				my $zip_n = scalar(@zip_list);
				LOG->notice("[sync][$lastzip] $sitekey, $host, $category, zip = $zip_n");
				next unless ($zip_n > 0);
				my $extractor = Getperf::Extractor->new(sitekey=>$sitekey, zips=>\@zip_list);
				$extractor->run('unzip');
				$lastzips{$sitekey}{$category}{$host} = pop(@zip_list);
			}
		}
	}
	$rc = $self->save_lastzips(\%lastzips);

	return $rc;
}

sub read_lastzips {
	my ($self) = @_;

    my @sitekeys = ();
    my %last_zips = ();
    if (defined(my $sitekey = $self->{sitekey})) {
		my $lastzip_json = file($self->{lastzip_dir}, "${sitekey}.json");
		if ($lastzip_json->stat) {
			my $lastzip_json_text = $lastzip_json->slurp || die $@;
	    	my $lastzip = decode_json($lastzip_json_text);
	    	$last_zips{$sitekey} = $lastzip;
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

1;
