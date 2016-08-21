use FindBin;
use lib "$FindBin::Bin/../lib";
use strict;
use Test::More;
use bigint;
use Getperf;
use Getperf::RRD;
use Getperf::Config 'config';
use Path::Class;
use Data::Dumper;

use strict;

# replace with the actual test
use_ok("Getperf");

subtest 'rrd' => sub {
	{
		my $metric = {step=>300};
		my $rrd = Getperf::RRD->new(%{$metric});

        $rrd->{headers} = [
            'used',
            'system',
            'wait',
            'idle',
            'costop',
            'run',
            'ready',
            'usagemhz',
            'latency',
            'demand',
            'overlap',
            'usage',
            'swapwait',
            'maxlimited',
            'entitlement',
            'cpuentitlement'
        ];
        $rrd->{path} = file ($FindBin::Bin, '/rrd/storage/cpu.rrd');

        ok my $cmd = $rrd->get_create_command;
        print $cmd;


        my $start = [Time::HiRes::gettimeofday()];
        for (1..100) {
            unlink( $rrd->{path} );
            ok $rrd->create;
            ok $rrd->load_data($FindBin::Bin . '/rrd/summary/cpu.txt');
        }
        my $elapse = Time::HiRes::tv_interval($start);           
        print "Elapse = $elapse\n";

        my $cmd = "rrdtool fetch $FindBin::Bin/rrd/storage/cpu.rrd AVERAGE -r 300 -s 1410875700 -e 1410876000";
        print $cmd . "\n";
        my $buf = `$cmd`;
        print $buf;
        ok ($buf=~/1410876000: \d/);
	}
};

subtest 'config' => sub {
    my $config = config('rrd');
    ok my $rra_config = $config->{rra};
    is scalar(@$rra_config), 4, 'scalar rra config';
};

subtest 'bigint' => sub {
    {
        my $metric = {step=>300};
        my $rrd = Getperf::RRD->new(%{$metric});

        $rrd->{headers} = [
            'val1',
            'val2:COUNTER',
            'val3',
            'val4:COUNTER',
        ];
        $rrd->{path} = file ($FindBin::Bin, '/rrd/storage/bigint.rrd');

        ok my $cmd = $rrd->get_create_command;
        print $cmd;


        my $metric = {step=>300};
        # my $tms = Time::Piece->strptime('2014-09-16T22:55:00', 
        #     '%Y-%m-%dT%H:%M:%S');
        my $val32 = 2 ** 32 - 10 * 300;
        my $val64 = 2 ** 64 - 10 * 300;
        my $cnt = 0;
        my $buf = "timestamp val32 counter32 val64 counter64\n";
        for my $tms( qw/ 2014-09-16T22:55:00 
            2014-09-16T23:00:00 
            2014-09-16T23:05:00 
            2014-09-16T23:10:00 
            2014-09-16T23:15:00 /) {

            $buf .= sprintf("%s %u %u %u %u\n", $tms, $val32, $val32, 2 ** 64, $val64 );
            $val32 += 5 * 300;
            if ($val32 > 2 ** 32) {
                $val32 -= 2 ** 32;
            }
            $val64 += 5 * 300;
            if ($val64 > 2 ** 64) {
                $val64 -= 2 ** 64;
            }
            
        }
        print $buf;

        my $sumdata = file($FindBin::Bin, '/rrd/summary/bigint.txt');
        my $writer = $sumdata->open('w') or die $!;
        $writer->print($buf);
        $writer->close;

        my $start = [Time::HiRes::gettimeofday()];
        for (1..100) {
            unlink( $rrd->{path} );
            ok $rrd->create;
            ok $rrd->load_data($sumdata);
        }
        my $elapse = Time::HiRes::tv_interval($start);           
        print "Elapse = $elapse\n";

        my $cmd = "rrdtool fetch $FindBin::Bin/rrd/storage/bigint.rrd AVERAGE -r 300 -s 1410875700 -e 1410877500";
        print $cmd . "\n";
        my $buf = `$cmd`;
        print $buf;
        ok ($buf=~/1410876000: \d/);
    }
};

done_testing;
