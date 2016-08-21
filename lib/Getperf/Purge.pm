use strict;
use warnings;
package Getperf::Purge;
use FindBin;
use Path::Class;
use Getperf::Config 'config';
use Getperf::Data::SiteInfo;
use parent qw(Class::Accessor::Fast);
use Data::Dumper;
use Time::Moment;
use Log::Handler app => "LOG";

__PACKAGE__->mk_accessors(qw/sitekey site/);

sub new {
	my ($class, $aggrigator) = @_;
	if (!defined($aggrigator->{site})) {
		my $msg = "Purge initialize error. Invalid aggrigator.";
		LOG->crit($msg);
		die $msg;		
	}
	bless {
		timestamp => Time::Moment->now,
		%$aggrigator,
	}, $class;
}

sub limit_time_dir_conditions {
	my ($self, $save_hours) = @_;

	my $tm = $self->{timestamp}->minus_hours($save_hours);

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

1;
