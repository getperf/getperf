#!/usr/bin/perl
#
# Sumup source convert script of $GETPERF_HOME/lib/Getperf/Command.
#

use strict;
use warnings;
use Path::Class;
use Data::Dumper;
use File::Basename qw(dirname);
use Sys::Hostname; 
use Template;
use Socket;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Log::Handler app => "LOG";
use Getperf;
use Getperf::Config 'config';

my $config = config('base');
$config->add_screen_log;

my $FROM = 'Site';
my $TO   = 'Base';

dir($config->{lib_dir}, '/Getperf/Command/', $FROM)->recurse(callback => sub {
    my $src_path = shift;
	my $dest_path = $src_path;
	$dest_path =~s /\/lib\/Getperf\/Command\/${FROM}/\/site\/Getperf\/Command\/${TO}/g;
    if (ref($src_path) eq 'Path::Class::Dir') {
    	if (!-d $dest_path) {
    		print "mkdir: $dest_path\n";
    		eval {
			    dir($dest_path)->mkpath;
			};
			if ($@) {
			    die $@;
			};
    	}

    } else {
    		print "generate: $dest_path\n";
    	my @lines = $src_path->slurp;
    	my @outputs = map { $_ =~ s/::Command::${FROM}::/::Command::${TO}::/g; $_; } @lines;

    	my $writer;
    	eval {
    		$writer = file($dest_path)->openw;
    	};
		if ($@) {
		    die $@;
		};

		$writer->print(@outputs);
    }
});
