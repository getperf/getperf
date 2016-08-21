package Getperf::MasterData;

use strict;
use warnings;
use utf8;
use Cwd;
use Path::Class;
use Data::Dumper;
use Template;
use File::Copy;
use Getperf::Data::SiteInfo;
use Getperf::Config 'config';
use parent qw(Class::Accessor::Fast);
use Log::Handler app => "LOG";

__PACKAGE__->mk_accessors(qw/site_info/);

our $VERSION = '0.01';

sub new {
	my ($class, $site_info, $metric) = @_;

	my $site_lib = $site_info->{lib};
	bless {
		site_lib => $site_lib,
		metric   => $metric,
		master   => file($site_lib , "/Getperf/Command/Master/${metric}.pm"),
		template => file($site_lib , "/Getperf/Command/Site/${metric}/tt_Master.pm"),
	}, $class;
}

sub regist {
	my ($self) = @_;

	my $template = $self->{template};
	if (!-f $template) {
		LOG->crit("sumup command template file not found : $template");
		return;
	}

	my $master = $self->{master};
	my $master_dir = $master->parent;
	$master_dir->mkpath if (!-d $master_dir);
	if (!-f $master) {
		LOG->notice("Create : $master");
		return copy($template, $master) or die "error: $! : $master";
	}

	return 1;
}

sub backup {
	my ($self) = @_;

	my $master = $self->{master};
	if (-f $master) {
		my $target = "${master}_bak";
		LOG->notice("Backup : $target");
		if (copy($master, $target)) {
			return unlink $master;
		} else {
			die "error: $! : $target";
		}
	}
}

sub dump_global_db {
	my ($self, $db) = @_;

	local $Data::Dumper::Indent = 1;
	local $Data::Dumper::Purity = 0;
	local $Data::Dumper::Sortkeys = 1;
	local $Data::Dumper::Deepcopy = 1;

	my $content = Data::Dumper->Dump([$db],['db']);
	$content    = 'our ' . $content;

	return $content;
}

sub update {
	my ($self, $db, $from) = @_;

	my $master = $from || $self->{master};
	LOG->notice("Update : $master");
	eval {
     	my @lines = $master->slurp or die $!;
     	my @out;
     	my $parse_phase = 0;

 		for my $line(@lines) {
 			# template script parser
 			$parse_phase ++ if ($parse_phase == 2);
 			if ($line=~/^our \$db/) {
 				$parse_phase ++;
 			}
 			if ($parse_phase == 1 && $line=~/^};/) {
 				$parse_phase ++;
 			}
 			# header part
 			if ($parse_phase == 0) {
 				push @out, $line;
 			# body part of global valiable; our $db = ...
 			} elsif ($parse_phase == 1 || $parse_phase == 2) {
 				if ($db) {
 					if ($parse_phase == 2) {
 						my $content = $self->dump_global_db($db);
		 				push @out, $content;
 					}
 				} else {
 					push @out, $line;
 				}
 			# body part of function; sub ...
 			} else {
				push @out, $line;
 			}
 		}

 		my $writer = $master->open('w') or die $!;
 		$writer->print(join("", @out));
 		$writer->close;
 	};
 	if ($@) {
 		LOG->error($@);
 		return;
 	}
 	return 1;
}
