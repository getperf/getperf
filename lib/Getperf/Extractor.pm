use strict;
use warnings;
package Getperf::Extractor;
use FindBin;
use Path::Class;
use JSON::XS;
use Getperf::Config 'config';
use Getperf::Aggregator;
use Getperf::Data::SiteInfo;
use parent qw(Class::Accessor::Fast);
use Data::Dumper;
use Time::Moment;
use Log::Handler app => "LOG";

__PACKAGE__->mk_accessors(qw/sitekey zips site staging_files data_infos/);

sub new {
	my $class = shift;

	my $self = bless {
		timestamp     => Time::Moment->now,
		staging_files => undef,
		@_,
	}, $class;
	if (defined(my $sitekey = $self->{sitekey})) {
		$self->{site} = Getperf::Data::SiteInfo->instance($sitekey);
	} else {
		return;
	}
	if (!defined($self->{zips})) {
		return;
	}
	return $self;
}

sub unzip {
	my $self = shift;

	for my $zip (@{$self->zips}) {
		# arc_t00051900cap04__VSPP_20141003_1350.zip
		next if ($zip!~/arc_(.+?)__(.+?)_(\d+?)_(\d+?)\.zip/);
		my ($agent, $cat, $start_date, $start_time) = ($1, $2, $3, $4);

		my $target = file($self->site->analysis, $agent);
		if (!File::Path::Tiny::mk($target)) {
	        LOG->crit("Could not make path '$target': $!");
	        return;
		}
		my $staging_dir = $self->site->staging_dir;
		LOG->debug("Extract : ${zip}");
		# my $command = "cd ${target}; unzip -o ${staging_dir}/${zip}";
		my $command = "cd ${target}; LANG=c jar xvf ${staging_dir}/${zip}";
		my @results = readpipe("$command 2>&1");
		for my $result(@results) {
			chomp($result);
			#   inflating: ELA/20141009/1400/cluster_all_stat.out
			if ($result=~/(inflated|inflating|extracting): (.*?)\s*$/) {
			# if ($result=~/(inflating|extracting): (.*?)\s*$/) {
				next if ($2=~/^\./);	# skip .dot file
print "EXTRACT:$2\n";
				push(@{$self->{staging_files}}, $agent . '/' . $2);
			} elsif ($result=~/unzip: (.*?)\s*$/) {
				LOG->error("unzip: $1 [SKIP]");
			}
		}
	}
	return 1;
}

sub aggrigate {
	my $self = shift;

	my $aggregator = Getperf::Aggregator->new();

	if (!$self->{staging_files}) {
		return 0;
	}
	for my $staging_file (@{$self->staging_files}) {
 		my $file = $self->site->analysis . '/' . $staging_file;
 		my $data_info = Getperf::Data::DataInfo->new(file_path => $file, site_info => $self->site);
 		$aggregator->run($data_info);
 		push(@{$self->{data_infos}}, $data_info);
 	}
 	$aggregator->flush();
 	
 	return 1;
}

sub limit_time_dir_conditions {
	my ($self, $save_hours) = @_;

	my $tm    = $self->{timestamp}->minus_hours($save_hours);

	my $result = {
		date => $tm->strftime("%Y%m%d"),
		time => $tm->strftime("%H%M%S"),
	};

	return $result;
}

sub purge_dir {
	my ($self, $sub_dir, $limit) = @_;

	if (!-d $sub_dir) {
		LOG->error("[purge_dir] not found : $sub_dir");
		return;
	}
	my $limit_time_dir_conditions = $self->limit_time_dir_conditions($limit);
	my $limit_date = $limit_time_dir_conditions->{date};
	my $limit_time = $limit_time_dir_conditions->{time};

	# analysis/server1/VMWARE/20140930/000000		
	my $delete_count = 0;
	for my $agent_dir(sort grep {$_->is_dir} dir($sub_dir)->children) {
		for my $category_dir(sort grep {$_->is_dir} dir($agent_dir)->children) {
			for my $date_dir(sort grep {$_->is_dir} dir($category_dir)->children) {
				if ($date_dir lt "$category_dir/$limit_date") {
					$date_dir->rmtree or return LOG->crit($!);
					$delete_count ++;
				} elsif ($date_dir eq "$category_dir/$limit_date") {
					for my $time_dir(sort grep {$_->is_dir} dir($date_dir)->children) {
						if ($time_dir lt "$date_dir/$limit_time") {
							$time_dir->rmtree or return LOG->crit($!);
							$delete_count ++;
						} else {
							last;
						}
					}
				} else {
					last;
				}
			}
		}
	}
	LOG->info("purge $sub_dir [< $limit_date/$limit_time], count=$delete_count");
	return 1;
}

sub purge {
	my $self = shift;

	my $purge_data_hour = $self->site->{purge_data_hour};
	$self->purge_dir($self->site->analysis, $purge_data_hour->{analysis} || 1);
	$self->purge_dir($self->site->summary, $purge_data_hour->{summary} || 1);
}

sub run {
	my $self = shift;

	$self->unzip;
	$self->aggrigate;
	$self->purge;
}

1;
