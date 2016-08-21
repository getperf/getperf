use FindBin;
use lib "$FindBin::Bin/../lib";
use strict;
use Test::More;
use Path::Class;
use Data::Dumper;
use File::Basename qw(dirname);
use Getperf;
use Getperf::Data::DataInfo;
use lib "$FindBin::Bin/lib";
use Getperf::Test::Initializer;

use strict;
my $COMPONENT_ROOT = Path::Class::file(dirname(__FILE__) . '/..')->absolute->resolve->stringify;

subtest 'basic' => sub {
	my $input_path = $FindBin::Bin . '/cacti_cli/analysis/ostrich/Linux/20150509/051000/vmstat.txt';
	my $data_info = Getperf::Data::DataInfo->new(file_path => $input_path);
	is ($data_info->site_info->summary, "$COMPONENT_ROOT/t/cacti_cli/summary",  'get summary 1');
	is ($data_info->summary_dir,        "/ostrich/Linux/20150509/051000", 'get summary 2');
};

subtest 'virtual path' => sub {
	&Getperf::Test::Initializer::create_getperf_site_json("$COMPONENT_ROOT/t");
	my $input_path = $FindBin::Bin . '/cacti_cli/analysis/ostrich/Linux/20150509/051000/hoge.out';

	my $data_info = undef;
	eval {
		$data_info = Getperf::Data::DataInfo->new(file_path => $input_path);
	};
	ok !$data_info, 'not found';
};

done_testing;
