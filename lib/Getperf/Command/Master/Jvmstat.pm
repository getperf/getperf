package Getperf::Command::Master::Jvmstat;
use strict;
use warnings;
use Exporter 'import';

our @EXPORT = qw/alias_instance/;

our $db = {
	_node_dir => undef,
	instances => undef,
};

sub new {bless{},+shift}

sub alias_instance {
	my ($java_info) = @_;

	my $pid     = $java_info->{pid};
    my $command = $java_info->{'sun.rt.javaCommand'};
    my $args    = $java_info->{'java.rt.vmArgs'};

    my ($device, $device_text);
    #  -Dwrapper.tra.file=/opt/tibco/tra/domain/y2wfm/application/RTD_TimeRestrict_151003/RTD_TimeRestrict_151003-Process_Archive-1.tra
    if ($command=~m|^org.apache.catalina.|) {
    	# -Dcatalina.base=/usr/local/tomcat-data
    	if ($args=~m|-Dcatalina.base=(.*?)\s|) {
    		my $catalina_base = $1;
    		$device_text = "Apache Tomcat - ${catalina_base}";
    		$catalina_base =~ s/(?:_|\/|-)(.)/\U$1/g;
    		$device = "tomcat.${catalina_base}";
    	}
    } elsif ($args=~m|-Dwrapper.tra.file=(.*)$|) {
    	my $trafile = $1;
    	$trafile=~s|.*/||g;
    	# RTD_PreOperation_151003-Process_Archive-1.tra
    	if ($trafile=~/^(.+)_\d+-Process_Archive/) {
    		my $tra = $1;
    		$device_text = "Tibco BW - $tra";
    		$device = $tra;
    	}
	# NRS -Dconfig.path=.../dbr/config/MESIF14_Y2/G1/ApplicationConfig.json
    } elsif ($args=~m|-Dconfig\.path=.+/config/(.+)/ApplicationConfig\.json|) {
    	my $nrs_config = $1;
    	$nrs_config=~s|\/|-|g;
		$device_text = "NRS - $nrs_config";
		$device = $nrs_config;

    } elsif ($args=~m|-Dcom.starview.toshiba.rtd.conf.file=(.*)$|) {
		my $rtdconf = $1;
    	$rtdconf=~s|.*/||g;
    	if ($rtdconf=~/^(.+)\.properties/) {
    		my $que = $1;
    		$device_text = "Starivew - $que";
    		$device = "Starview.RTD-DM_$que";
    	}
    }

	return ($device) ? {device => $device, device_text => $device_text} : undef;
}

1;
