use FindBin;
use lib "$FindBin::Bin/../lib";
use strict;
use Test::More;
use Path::Class;
use lib "$FindBin::Bin/lib";
use Zabbix::API;
use Data::Dumper;

use strict;

my $zabber = Zabbix::API->new(server => 'http://localhost/zabbix/api_jsonrpc.php',
                                verbosity => 0);

eval { $zabber->login(user => 'admin', password => 'getperf') };

if ($@) { die 'could not authenticate' };

subtest 'host_group' => sub {
	{
		ok my $hostgroups = $zabber->fetch('HostGroup', params => { search => { name => 'Zabbix servers' } });
		ok my $zabhost = $hostgroups->[0];
		ok $zabhost->created;
	}
	{
		my $hostgroups = $zabber->fetch('HostGroup', params => { search => { name => 'hogehoge' } });
		is_deeply($hostgroups, [], 'host group not found');
	}
	{
		ok my $new_hostgroup = Zabbix::API::HostGroup->new(root => $zabber, data => { name => 'Another HostGroup' });
		eval { $new_hostgroup->push };
		if ($@) { diag "Caught exception: $@" };
		ok $new_hostgroup->created;
		print Dumper($new_hostgroup->{data}->{groupid});
 		ok ( 0 <= $new_hostgroup->{data}->{groupid} );
		eval { $new_hostgroup->delete };
	}
};

subtest 'templates' => sub {
	{
		ok my $templates = $zabber->query({method => 'template.get', params => 
			{ filter => { host => [ 'Template OS Linux' ] } } });
		ok my $template = $templates->[0];
		print Dumper($template);
	}
	{
		ok my $templates = $zabber->query({method => 'template.get', params => 
			{ filter => { host => [ 'Template Hoge' ] } } });
		is_deeply($templates, [], 'template not found');
	}
	{
		ok my $hostgroups = $zabber->fetch('HostGroup', params => { search => { name => 'Zabbix servers' } });
		ok my $hostgroup_id = $hostgroups->[0]->{data}->{groupid};
		ok my $templates = $zabber->query({method => 'template.create', params => { host => 'Template Hoge', groups => { groupid => $hostgroup_id } } });
		ok my $template_id = $templates->{templateids}->[0];
		ok my $templates = $zabber->query({method => 'template.delete', params => [$template_id] });
		# ok my $template = $templates->[0];
		print Dumper($templates);
	}
};

subtest 'hosts' => sub {
	{
		ok my $hosts = $zabber->fetch('Host', params => { host => 'Zabbix Server', search => { host => 'Zabbix Server' } });
		is(@{$hosts}, 1, '... and a host known to exist can be fetched');
		ok my $zabhost = $hosts->[0];
		isa_ok($zabhost, 'Zabbix::API::Host', '... and that host');
		# print Dumper($zabhost->{data});
	}
	{
		ok my $hosts = $zabber->fetch('Host', params => { host => 'Hoge Server', search => { host => 'Hoge Server' } });
		is_deeply($hosts, [], 'host not found');
	}
	{
		my $new_host = Zabbix::API::Host->new(root => $zabber,
      		data => { host => 'Another Server',
                interfaces => [
                	{
                		type => 1,
                		main => 1,
                		dns => "",
                		port => "10050",
                		ip => '255.255.255.255',
                        useip => 1,
                    }
                ],
                groups => [ { groupid => 4 } ],
                templates => [ { templateid => 10001 } ],
            });

		isa_ok($new_host, 'Zabbix::API::Host', '... and a host created manually');

		eval { $new_host->push };
		if ($@) { diag "Caught exception: $@" };
		# print Dumper($new_host->{data});
		eval { $new_host->delete };
		if ($@) { diag "Caught exception: $@" };
	}
};

};

done_testing;
