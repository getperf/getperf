package Getperf::Data::ClassFinder;

use strict;
use warnings;
use utf8;
use Log::Handler app => "LOG";
use Cwd;
use Encode qw( encode_utf8 );
use Path::Class;
use Data::Dumper;
use Time::Piece;
use Template;
use File::Copy;
use Getperf::MasterData;
use Getperf::Data::SiteInfo;
use Getperf::Data::DataInfo;
use Getperf::Config 'config';
use parent qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors(qw/site_info class_name/);

our $VERSION = '0.01';

my %instances = ();

sub instance {
    my ($class, $site_info, $metric, $class_name) = @_;

	my $sitekey   = $site_info->sitekey;
	my $class_key = join("|", $sitekey, $metric, $class_name);
    if (!defined($instances{$class_key})) {
    	Getperf::MasterData->new($site_info, $metric)->regist();
    	my $sumup = $class->find_class($site_info, $metric, $class_name) || '';
	    $instances{$class_key} = $sumup;
	}
    return $instances{$class_key};
}

sub find_class_by_keyword {
	my ($self, $keyword, $script) = @_;
	return if (!-d $script);
	my @script_lists = dir($script)->children;
	for my $script_list(sort @script_lists) {
		next if ($script_list!~/^(.*)\/(.*?)\.pm/);
		my $script_name = $2;
		if ($keyword=~/^$script_name/) {
			return $script_name;
		}
	}
}

sub find_class {
	my ($self, $site_info, $metric, $class_name) = @_;
	my $site_lib   = $site_info->lib;
	my $base_lib   = config('base')->{lib_dir};
	my $sitekey    = $site_info->sitekey;

	my @search_rules = (
		{
			script => "$site_lib/Getperf/Command/Site/$metric/",
			class  => "Site::${metric}::",
		},
		{
			script => "$base_lib/Getperf/Command/Base/$metric/",
			class  => "Base::${metric}::",
		},
	);
	for my $search_rule(@search_rules) {
		my $script = $search_rule->{script} . $class_name . '.pm';
		if (-e $script) {
			my $class = $search_rule->{class} . $class_name;
			LOG->debug("command : $class");
			return $class;
		}
	}

	for my $search_rule(@search_rules) {
		my $keyword_class = $self->find_class_by_keyword($class_name, $search_rule->{script});
		if ($keyword_class) {
			my $class = $search_rule->{class} . $keyword_class;
			LOG->debug("command : $class");
			return $class;
		}
	}

	return;
}

1;