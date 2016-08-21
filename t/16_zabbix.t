use FindBin;
use lib "$FindBin::Bin/../lib";
use strict;
use Test::More;
use Path::Class;
use Getperf;
use Getperf::Config 'config';
use Getperf::Data::NodeInfo;
use Getperf::Zabbix;
use Getperf::Container qw/command/;
use lib "$FindBin::Bin/lib";
use Getperf::Test::Initializer;
use Data::Dumper;

use strict;

# replace with the actual test
use_ok("Getperf");

subtest 'deploy' => sub {
	{
		ok my $zabbix = Getperf::Zabbix->new();
		# ok $zabbix->test;
	}
};

subtest 'basic' => sub {
	my $zabbix = Getperf::Zabbix->new();
	ok $zabbix->login;
	{
		$zabbix->parse_node_info( $FindBin::Bin . '/cacti_cli/node/Linux/ostrich/' );
		ok $zabbix->regist_node;
	}
	ok $zabbix->logout;
};

subtest 'node_path' => sub {
	my $zabbix = Getperf::Zabbix->new();
	ok $zabbix->login;
	{
		my $node_info = Getperf::Data::NodeInfo->new();
		$node_info->add_node('Linux', 'localhost');
		$node_info->generate_node_list;
		$zabbix->{node_info} = $node_info;
		ok $zabbix->regist_node;
	}
	{
		my $node_info = Getperf::Data::NodeInfo->new();
		$node_info->add_node('Linux', 'localhost', {node_path=>'/abc/def/localhost'});
		$node_info->generate_node_list;
		$zabbix->{node_info} = $node_info;
		ok $zabbix->regist_node;
	}
	ok $zabbix->logout;
};

subtest 'login' => sub {
	my $zabbix = Getperf::Zabbix->new();
	ok $zabbix->login;
	ok $zabbix->logout;
};

subtest 'host_group' => sub {
	my $zabbix = Getperf::Zabbix->new();
	$zabbix->login;
	{
		my $host_group_id = $zabbix->check_or_generate_hostgroup('Linux servers');
		print "host_group_id : $host_group_id\n";
		ok ($host_group_id > 0);
	}
	{
		my $host_group_id = $zabbix->check_or_generate_hostgroup('Hoge Hoge');
		print "host_group_id : $host_group_id\n";
		ok ($host_group_id > 0);
		ok  $zabbix->remove_hostgroup('Hoge Hoge');
	}
	$zabbix->logout;
};

subtest 'template' => sub {
	my $zabbix = Getperf::Zabbix->new();
	$zabbix->login;
	my $group_id = $zabbix->check_or_generate_hostgroup('Linux servers');
	{
		my $template_id = $zabbix->check_or_generate_template('Template OS Linux', $group_id);
		print "template_id : $template_id\n";
		ok ($template_id > 0);
	}
	{
		my $template_id = $zabbix->check_or_generate_template('Hoge Hoge', $group_id);
		print "template_id : $template_id\n";
		ok ($template_id > 0);
		ok  $zabbix->remove_template('Hoge Hoge');
	}
	{
		my $parent_templateid = $zabbix->check_or_generate_template('Template OS Linux');
		my $template_id = $zabbix->check_or_generate_template('Hoge Hoge', $group_id, $parent_templateid);
		print "template_id : $template_id\n";
		ok ($template_id > 0);
		ok  $zabbix->remove_template('Hoge Hoge');
	}
	$zabbix->logout;
};

subtest 'host' => sub {
	my $zabbix = Getperf::Zabbix->new();
	$zabbix->login;
	{
		my $node_info = {ip => '255.255.255.255'};
		ok my $host = $zabbix->check_or_generate_host('Linux', 'ostrich', $node_info);
		ok $zabbix->remove_host('ostrich');
	}
	{
		my $node_info = {ip => '254.254.254.254', node_path => '/koto/suna/kirin'};
		ok my $host = $zabbix->check_or_generate_host('Linux', 'kirin', $node_info);
		ok  $zabbix->remove_host('kirin');
	}
	{
		my $node_info = {node_path => '/koto/suna/panda'};
		not ok my $host = $zabbix->check_or_generate_host('Linux', 'panda', $node_info);
	}
	{
		my $node_info = {ip => '254.254.254.254', node_path => '/koto/suna/kirin', multi_site => 'site1'};
		ok my $host = $zabbix->check_or_generate_host('Linux', 'kirin', $node_info);
		ok  $zabbix->remove_host('kirin');
	}
	$zabbix->logout;
};

done_testing;
