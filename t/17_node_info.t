use FindBin;
use lib "$FindBin::Bin/../lib";
use strict;
use Test::More;
use Test::Exception;

use Path::Class;
use Data::Dumper;
use File::Basename qw(dirname);
use Getperf;
use Getperf::Data::NodeInfo;
use lib "$FindBin::Bin/lib";
use Getperf::Test::Initializer;

use strict;
my $COMPONENT_ROOT = Path::Class::file(dirname(__FILE__) . '/..')->absolute->resolve->stringify;

subtest 'basic' => sub {
	my $summary = "$COMPONENT_ROOT/t/cacti_cli/summary";
	{
		my $input_path = $FindBin::Bin . '/cacti_cli/node/Linux/ostrich/';
		my $node_info = Getperf::Data::NodeInfo->new(file_path => $input_path);
#print Dumper($node_info->{site_info});
		is ($node_info->site_info->summary, $summary,  'get summary 1');
	}
	{
		my $input_path = $FindBin::Bin . '/cacti_cli/node/Linux/ostrich';
		my $node_info = Getperf::Data::NodeInfo->new(file_path => $input_path);
		is ($node_info->site_info->summary, $summary,  'get summary 2');
	}
	{
		my $input_path = $FindBin::Bin . '/cacti_cli/node/Linux/hogehoge';
		 dies_ok { Getperf::Data::NodeInfo->new(file_path => $input_path) } 'not found';
	}
};

subtest 'domain' => sub {
	my $summary = "$COMPONENT_ROOT/t/cacti_cli/summary";
	{
		my $input_path = $FindBin::Bin . '/cacti_cli/node/Linux/';
		my $node_info = Getperf::Data::NodeInfo->new(file_path => $input_path);
		is ($node_info->site_info->summary, $summary,  'get summary 1');
	}
	{
		my $input_path = $FindBin::Bin . '/cacti_cli/node/Linux';
		my $node_info = Getperf::Data::NodeInfo->new(file_path => $input_path);
		is ($node_info->node_infos->{Linux}{ostrich}{kernel}, '3.13.0-39-generic', 'get kernel');
		is ($node_info->site_info->summary, $summary,  'get summary 2');
	}
};

subtest 'ip' => sub {
	{
		my $input_path = $FindBin::Bin . '/cacti_cli/node/';
		my $node_info = Getperf::Data::NodeInfo->new();
		$node_info->add_node('Linux', 'localhost');
		$node_info->generate_node_list;
		is ($node_info->node_infos->{Linux}{localhost}{ip}, '127.0.0.1', 'localhost');
	}
};

subtest 'node_list_tsv' => sub {
	{
		my $input_path = $FindBin::Bin . '/node_list.tsv';
		my $node_info = Getperf::Data::NodeInfo->new();
		$node_info->parse_path($FindBin::Bin . '/cacti_cli/node/');
		$node_info->load_node_ip_lists($input_path);
		$node_info->add_node('Linux', 'localhost');
		$node_info->generate_node_list;
		is ($node_info->node_infos->{Linux}{localhost}{ip}, '127.0.0.1', 'localhost');
	}
};

subtest 'add_node' => sub {
	{
		my $input_path = $FindBin::Bin . '/cacti_cli/node/';
		my $node_info = Getperf::Data::NodeInfo->new();
		$node_info->add_node('Linux', 'localhost');
		$node_info->generate_node_list;
		is ($node_info->node_infos->{Linux}{localhost}{ip}, '127.0.0.1', 'localhost');
	}
	{
		my $input_path = $FindBin::Bin . '/cacti_cli/node/';
		my $node_info = Getperf::Data::NodeInfo->new();
		$node_info->add_node('Linux', 'hoge', {ip => '127.0.0.1'});
		is ($node_info->node_infos->{Linux}{hoge}{ip}, '127.0.0.1', 'host hoge');
	}
};

subtest 'fetch_node' => sub {
	{
		my $input_path = $FindBin::Bin . '/cacti_cli/node/';
		my $node_info = Getperf::Data::NodeInfo->new(file_path => $input_path);
		$node_info->generate_node_list;

		{
			my $node = $node_info->fetch_first_node;
			is ($node->{domain},        'Linux',     'fetch first 1');
			is ($node->{node},          'ostrich',   'fetch first 2');
			is ($node->{node_info}{ip}, '127.0.0.1', 'fetch first 3');
		}
		{
			my $node = $node_info->fetch_next_node;
			is ($node->{domain},        'Windows',   'fetch second 1');
			is ($node->{node},          'living1',   'fetch second 2');
		}
		{
			my $node = $node_info->fetch_next_node;
			is($node, undef, 'fetch eol');
		}
	}
	{
		my $input_path = $FindBin::Bin . '/cacti_cli/node/';
		my $node_info = Getperf::Data::NodeInfo->new();
		$node_info->generate_node_list;

		{
			my $node = $node_info->fetch_first_node;
			is($node, undef, 'no data');
		}
	}
	{
		my $input_path = $FindBin::Bin . '/cacti_cli/node/';
		my $node_info = Getperf::Data::NodeInfo->new(file_path => $input_path);
		$node_info->generate_node_list;

		my $node_count = 0;
		my $node = $node_info->fetch_first_node;
		do {
			isnt($node->{domain},    undef, 'domain');
			isnt($node->{node_info}, undef, 'node_info');
			$node_count ++;
		} while ($node = $node_info->fetch_next_node);
		is($node_count, 2, 'node count');
	}

};

done_testing;
1;
