package Getperf::Data::DataInfo;

use strict;
use warnings;
use utf8;
use Log::Handler app => "LOG";
use Cwd;
use Encode qw( encode_utf8 );
use Path::Class;
use Data::Dumper;
use JSON::XS;
use YAML::Tiny;
use Time::Piece;
use Getperf::Data::SiteInfo;
use Getperf::Data::MetricInfo;
use Getperf::Data::ClassFinder;
use Getperf::Config 'config';
use Getperf::Container;
use String::CamelCase qw(camelize decamelize);
use parent qw(Class::Accessor::Fast);

__PACKAGE__->mk_accessors(qw/file_path site_info base_dir category debug host metric start_date start_time postfix file_name class_name file_suffix file_ext summary_dir storage_dir absolute_summary_dir absolute_storage_dir agent_dir metrics step is_remote infos in_file/);

our $VERSION = '0.01';
my %osnames = qw/Linux 1 Windows 2 Solaris 3 AIX 4 HP-UX 5/;

# cache of stat_XX.log and site_info
my %Stats; 
my $site_info_instance;

sub new {
	my $class = shift;

	my $self = bless {
		is_remote => 0,
		is_daemon => 1,
		debug     => 0,
		step      => 60,
		host      => '',
		@_,
	}, $class;
	if (my $file_path = $self->{file_path}) {
		unless ($self->parse_path($file_path)) {
			return;
		}
	}
	return $self;
}

sub file_info {
	my $self = shift;
	if ($self->file_name) {
		return join(",", ($self->host, $self->file_name, $self->file_ext || ''));
	}
}

sub read_stat_file {
	my $self = shift;

	my $stat_file = 'stat_' . $self->metric . '.log';
	my $stat_path = file($self->base_dir, $self->category, $self->host,
		$self->metric, $self->start_date, $self->start_time, $stat_file);
	if (!-f $stat_path) {
		return;
	}

	my %jobs = ();
	eval {
		# Cut the error message line after CR for YAML parser.
		# In the case of Mac using the CR, it will malfunction. 
		my $stat_yaml_text_original = $stat_path->slurp || die $@;
		$stat_yaml_text_original=~s/\x0D.+\n?/\n/g;
		# Avoid errormsg for multibyte encode error.
		#   errormsg: |
 		#     Sqlcmd: <83>t<83>@<83>C<83><8b><96>?<82>a<96>3<8c>o<82>A<82>・<81>B
		my @stat_yaml_text_filterd = split(/\n/, $stat_yaml_text_original);
		my @stat_yaml_texts = map { ($_=~/^(\s+errormsg|\s{6})/)?'':$_; } @stat_yaml_text_filterd;
		my $stat_yaml_text = join("\n", @stat_yaml_texts);
		my $stat_yaml = YAML::Tiny->read_string($stat_yaml_text);
		my $stat_data = $stat_yaml->[0];
		my @jobs = @{$stat_data->{jobs}};
		for my $job(@jobs) {
			my $out = 'unkown';
			if (defined($job->{out})) {
				$out = $job->{out};
			} else {
				# Extract output file from command string. "_odir_\ProcessorMemory.csv"
				if ($job->{cmd} =~/_odir_(.*)/) {
					$out  = $1;
					$out =~s/^.*?[\\|\/]//g;	#ltrim
					$out =~s/["|'].*$//g;		#rtrim1
					$out =~s/\s.*$//g;			#rtrim2
				}
			}
			$jobs{$out} = $job;
		}
		$jobs{_servicename} = (defined($stat_data->{schedule}{servicename})) ?
						      $stat_data->{schedule}{servicename} : undef;
	};
	if ($@) {
		LOG->error("YAML parse error $stat_path : $@");
  		return;
	}
	return \%jobs;
}

sub parse_path {
	my ($self, $path) = @_;

	if (!defined($site_info_instance)) {
		$site_info_instance = Getperf::Data::SiteInfo->get_instance_from_path($path);
	}
	my $site_info = $site_info_instance;
	$self->{site_info}  = $site_info;

	$path=~s/^(.+\/|)analysis\///g;	# trim '.../analysis/'
	$path = $site_info->{analysis} . '/' . $path;
# print "PATH:$path\n";
	return if (!-f $path);
	# ex) t/analysis/server1/HW/20140910/035500/iostat__dev1.txt
	if ($path=~m|^(.*)/(.*?)/(.*?)/(.*?)/(\d{8})[/_](\d{4,6})(.*)/(.+?)$|) {
		$self->{base_dir}   ||= $1;
		$self->{category}   ||= $2;
		$self->{host}       ||= $3;
		$self->{metric}     ||= $4;
		$self->{start_date} ||= $5;
		$self->{start_time} ||= $6;
		$self->{postfix}    ||= $7;

		my $fname = $8;
		if ($fname=~/^(.+)\.(.+?)$/) {
			$self->{file_name}  ||= $1;
			$self->{file_ext}   ||= $2;
		} else {
			$self->{file_name} ||= $fname;
		}
		my $stat_log = 'stat_' . $self->{metric};
		if ($self->{file_name} eq $stat_log && $self->{file_ext} eq 'log') {
			return;
		}
		$self->{start_time} .= '00' if ($self->{start_time}=~/^\d{4}$/);
		if ($self->{file_name} =~/^(.+?)__(.+?)$/) {
			$self->{file_name}   = $1;
			$self->{file_suffix} = $2;
		}
		$self->{file_path} = $path;
		$self->{postfix}   =~ s/^\/*(.*?)\/*$/$1/;
		$self->{class_name} = $self->{file_name};
		$self->{class_name} =~ s/(?:^|_)(.)/\U$1/g;

		my $host_metric    = $self->{host} . '/' . $self->{metric};
		$self->{agent_dir} = $host_metric;

		# .stat_XX.log読み込み。last_updateと日時が異なる場合はYAMLから読み込み、更新
		my $stat_data = $Stats{$host_metric};
		my $timestamp = $self->{start_date} . $self->{start_time};
		if (!defined($stat_data) || $stat_data->{last_update} ne $timestamp) {
			if (my $stat_yaml = $self->read_stat_file) {
				$stat_data = {
					'result'      => $stat_yaml, 
					'last_update' => $timestamp,
				};
				$Stats{$host_metric} = $stat_data;			
			}
		}
		$self->{stat_data}  = $stat_data->{result};

		if (defined(my $new_host = $self->{stat_data}{_servicename})) {
			$self->{host} = $new_host;
		}
		{
			my $path = '';
			for my $member ( qw/host metric start_date start_time/ ) {
				$path .= '/' . $self->{$member};
			}
			$self->{summary_dir} = $path;	
			$self->{absolute_summary_dir} = $site_info->summary . $path;	
		}

		{
			$self->{storage_dir} = '';
			$self->{absolute_storage_dir} = $site_info->storage;
		}

		{
			my $postfix = $self->{postfix};
			my $in_file = ($postfix eq '') ? '' : $postfix . '/';
			$in_file   .= $self->{file_name};
			$in_file .= '.' . $self->{file_ext} if (exists($self->{file_ext}));
			$self->{in_file} = $in_file;
		}

		return 1;
	}
}

sub input_file {
	my $self = shift;
	return $self->file_path;
}

sub input_dir {
	my $self = shift;
	my $file_path = file($self->file_path);
	return $file_path->parent->absolute->resolve->stringify;
}

sub start_timestamp {
	my $self = shift;

	my $timestamp = undef;
	my $in_file = $self->in_file;
	if (defined(my $status = $self->{stat_data}->{$in_file})) {
		# transfer 2015/03/16 13:45:52 to 2015-03-16T13:45:52
		$timestamp = $status->{start};
		$timestamp=~s/\//-/g;
		$timestamp=~s/ /T/g;
	} else {
		my ($start_date, $start_time);
		my $tm = $self->{start_date} . 'T' . $self->{start_time};
		if ($tm=~/^(\d{4})(\d{2})(\d{2})T(\d{2})(\d{2})(\d{2})$/) {
			$timestamp = "$1-$2-$3T$4:$5:$6";
		} else {
			LOG->crit("Invalid timestamp info : $self->input_file");
		}
	}

	return $timestamp;
}

sub start_time_sec {
	my $self = shift;

	my $start_timestamp = $self->start_timestamp;
	return if (!$start_timestamp);
	return localtime(Time::Piece->strptime($start_timestamp, '%Y-%m-%dT%H:%M:%S'));
}

sub pivot_report {
	my ($self, $output_file, $results, $headers) = @_;

	my $site_summary = $self->site_info->summary;
	my $output_path = $self->absolute_summary_dir . '/' . $output_file;
	LOG->debug('output: %s', $output_file);
	my $output_dir = file($output_path)->dir;
	if (!File::Path::Tiny::mk($output_dir)) {
        LOG->crit("Could not make path '$output_dir': $!");
        return;
	}
	# extract input headers eg) consumed.vms|consumedVms => consumed.vms
	my @_headers = ();
	for my $header(@$headers) {
		my $postfix = $header;
		$postfix=~s/(:|\|).*$//g;
		push(@_headers, $postfix);
	}
	my $header_title = join(' ', ('timestamp', @_headers, "\n"));

	my $writer = undef;
	$writer = file($output_path)->open('w');
	unless ($writer) {
        LOG->crit("Could not write '$output_dir': $!");
        return;
	}
	$writer->print($header_title);
	for my $time(sort keys %$results) {
		my $line = $time;

		for my $item(@_headers) {
			if (defined($results->{$time}{$item})) {
				$line .= ' ' . $results->{$time}{$item};
			} else {
				$line .= ' NaN';
			}
		}
		$writer->print("$line\n");
		print "$output_file:$line\n" if ($self->debug);
	}
	$writer->close;

	return 1;
}

sub simple_report {
	my ($self, $output_file, $results, $headers) = @_;

	my $output_path = $self->absolute_summary_dir . '/' . $output_file;
	LOG->debug('output: %s', $output_file);
	my $output_dir = file($output_path)->dir;
	if (!File::Path::Tiny::mk($output_dir)) {
        LOG->crit("Could not make path '$output_dir': $!");
        return;
	}
	my $header_title = join(' ', ('timestamp', @$headers, "\n"));

	my $writer = undef;
	$writer = file($output_path)->open('w');
	unless ($writer) {
        LOG->crit("Could not write '$output_dir': $!");
        return;
	}
	$writer->print($header_title);
	for my $time(sort keys %$results) {
		my $line = $time;
		$line .= ' ' . $results->{$time} . "\n";
		$writer->print($line);
	}
	$writer->close;

	return 1;
}

sub standard_report {
	my ($self, $output_file, $buffers) = @_;

	my $output_path = $self->absolute_summary_dir . '/' . $output_file;
	LOG->debug('output: %s', $output_file);
	my $output_dir = file($output_path)->dir;
	if (!File::Path::Tiny::mk($output_dir)) {
        LOG->crit("Could not make path '$output_dir': $!");
        return;
	}
	my $writer = undef;
	$writer = file($output_path)->open('w');
	unless ($writer) {
        LOG->crit("Could not write '$output_dir': $!");
        return;
	}
	$writer->print($buffers);
	$writer->close;

	return 1;
}

sub skip_header {
	my ($self, $in) = @_;
	my $row = 0;
	my $offset = 0;
	while (my $line = <$in>) {
		$row ++;
		$line=~s/(\r|\n)*//g;	# trim return code
		if ( $row <= 2 && ($line =~/^\s*[a-zA-Z-].*[a-zA-Z-]\s*$/ || $line =~/^[- ]*$/) ) {
			$offset = tell($in);
			next;
		} else {
			last;
		}
	}
	seek($in, $offset, 0);
	return 1;
}

sub regist_metric {
	my ($self, $nodepath, $domain, $metric, $headers) = @_;

	my $node = $nodepath;
	$node=~s/^(.*)\///g;
	if (!$node) {
		LOG->warn("[regist_metric] not found node");
		return;
	}
	my $node_metric = "${node}/${metric}";
	my $metric_info = undef;
	if (!defined($metric_info = $self->{node_keys}{$node_metric})) {
		# In case of agent/host put $node to host, $nodepath to agent/host
		$metric_info = Getperf::Data::MetricInfo->new(node => $node, 
			nodepath => $nodepath, domain => $domain, metric => $metric, 
			headers => $headers);
		$metric_info->agent_dir($self->{agent_dir});
		$metric_info->site_info($self->{site_info});
		push(@{$self->{metrics}}, $metric_info);
		$self->{node_keys}{$node_metric} = $metric_info;
	}
	return $metric_info;
}

sub regist_node {
	my ($self, $nodepath, $domain, $metric, $infos) = @_;

	my $metric_info = $self->regist_metric($nodepath, $domain, $metric, undef);
	$metric_info->infos($infos);
	return $metric_info;
}

sub regist_device {
	my ($self, $nodepath, $domain, $metric, $device, $text, $headers) = @_;
	my $node = $nodepath;
	$node=~s/^.*\///g;
	my $metric_info = $self->regist_metric($node, $domain, "device/$metric", $headers);
	my $device_key = "${node}/${metric}__${device}";
	if (!defined($self->{device_keys}{$device_key})) {
		push(@{$metric_info->{devices}}, $device);
		if (defined($text)) {
			push(@{$metric_info->{device_texts}}, $text);
		}
		$self->{device_keys}{$device_key} = 1;
	}
}

sub regist_devices_alias {
	my ($self, $nodepath, $domain, $metric, $alias, $devices, $texts) = @_;
	my $node = $nodepath;
	$node=~s/^.*\///g;

	# Create node config path e.g) node/HW/{Agent}/device/{alias}.json
	my $node_dir = $self->site_info->node;
	my $metric_path = file($node_dir, $domain, $node, 'device', "${alias}.json");
	my $metric_dir = $metric_path->dir;
	if (!-d $metric_dir) {
		if (!File::Path::Tiny::mk($metric_dir)) {
	        LOG->crit("Could not make path '$metric_dir': $!");
	        return;
		}
	}

	my %metric_config = (devices => $devices);
	if ($texts) {
		$metric_config{device_texts} = $texts;
	}
	$metric_config{rrd} = "${domain}/${node}/device/${metric}__*.rrd";
	my $metric_config_json = JSON::XS->new->pretty(1)->canonical(1)->encode (\%metric_config);
	my $writer = $metric_path->open('w');
	unless ($writer) {
        LOG->crit("Could not write '$metric_path': $!");
        return;
	}
	$writer->print($metric_config_json);
	$writer->close;
}


sub update_node_config {
	my $self = shift;

	if (!defined($self->metrics)) {
		LOG->warning("Sumup result does not have metric." . $self->class_name);
		return;
	}
	for my $metric(@{$self->metrics}) {
	 	$metric->save_config();
	 	$self->{view}{$metric->domain}{$metric->node} = 1;
	}

	$self->update_node_view();
}

sub report_zabbix_send_data {
	my ($self, $node, $zabbix_send_data) = @_;

	my $output_path = $self->absolute_summary_dir . '/zabbix_send_data.txt';
	my $output_dir = file($output_path)->dir;
	if (!File::Path::Tiny::mk($output_dir)) {
		LOG->crit("Could not make path '$output_dir': $!");
		return;
	}
	my $writer = undef;
	$writer = file($output_path)->open('w');
	unless ($writer) {
		LOG->crit("Could not write '$output_dir': $!");
		return;
	}
	# Report zabbix_sender : "{node} {item} {tms} {value}"
	for my $sec(keys %$zabbix_send_data) {
		for my $item(keys %{$zabbix_send_data->{$sec}}) {
			my $value = $zabbix_send_data->{$sec}{$item};
			my $line = "${node} ${item} ${sec} ${value}\n";
			$writer->print($line);
		}
	}
	$writer->close;
}

sub cacti_db_query {
	my ($self, @params) = @_;

	container('cacti_db')->selectall_arrayref(@params);
}

sub cacti_db_dml {
	my ($self, @params) = @_;

	container('cacti_db')->do(@params);
}

sub update_node_view {
	my $self = shift;
	my $view_dir = $self->site_info->view;
	for my $domain(keys %{$self->{view}}) {
		for my $node(sort keys %{$self->{view}{$domain}}) {
			my $node_path = file($view_dir, '_default', $domain, "${node}.json");
			my (@nodes, %node_keys);
			next if ($node_path->stat);
			my $node_path_dir = $node_path->dir;
			if (!File::Path::Tiny::mk($node_path_dir)) {
		        LOG->crit("Could not make path '$node_path_dir': $!");
		        return;
			}
			my %infos = ();
			my $node_config_json = JSON::XS->new->pretty(1)->encode (\%infos);
			my $writer = file($node_path)->open('w');
			unless ($writer) {
		        LOG->crit("Could not write '$node_path': $!");
		        return;
			}
			$writer->print($node_config_json);
			$writer->close;
		}
	}
}

sub find_class {
	my $self = shift;
	my $site_info  = $self->site_info;
	my $metric     = $self->metric;
	my $class_name = $self->class_name;

	return Getperf::Data::ClassFinder->instance($site_info, $metric, $class_name);
}

sub get_line {
	my ($self, $msg, $buf) = @_;

	my $line = $msg;
	$line .= ($$buf eq '')?' ':' [' . $$buf . '] ';
	print $line;
	my $res = '';
	$res = <STDIN>;
	$res =~ s/[\r\n]+//g;
	if ($res ne '') {
		$$buf = $res;
	}
}

sub regist_node_dir {
	my ($self, $host, $db) = @_;

	return 1;
	return if ($self->{is_daemon});

	my $msg   = undef;
	my $yesno = 'y';
	$msg = "'$host' is not registered to the master db.\n" .
		   "After registration, you must run 'sumup restart'.\n" .
		   "Would you like to register?";

	$self->get_line($msg, \$yesno);
	return if ($yesno ne 'y');

	my $node_dir = '';
	$msg = "Enter the node path directory.\n" .
		   "(In the case of blank will be common category)";

	$self->get_line($msg, \$node_dir);

	$db->{_node_dir}{$host} = $node_dir;
   	my $mastar_data = Getperf::MasterData->new($self->{site_info}, $self->{metric});
   	if (!$mastar_data->update($db)) {
   		LOG->crit("Can't update : " . $mastar_data->{master});
   		return;
   	}
	$self->regist_node($host, $self->{metric}, 'info/sys', {node_path=>"$node_dir/$host"});

	return 1;
}

sub get_domain_osname {
	my ($self) = @_;

	my @domains = dir($self->{base_dir}, 'analysis', $self->{host})->children;
	my $osname = 'Unkown';
	for my $domain_dir(@domains) {
		my $domain = $domain_dir->basename;
		if ($domain=~/(Linux|Windows|Solaris|AIX|HP-UX)/) {
			$osname = $domain;
			last;
		}
	}
	return $osname;
}

1;