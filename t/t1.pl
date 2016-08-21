use FindBin;
use lib "$FindBin::Bin/../lib";
use strict;
use Getperf;
use bigint;
use Time::Piece;
use Time::Seconds;
use Getperf::RRD;
use Getperf::Config 'config';
use Path::Class;
use Data::Dumper;

use strict;


        my $metric = {step=>300};
        # my $tms = Time::Piece->strptime('2014-09-16T22:55:00', 
        #     '%Y-%m-%dT%H:%M:%S');
        my $val32 = 2 ** 32 - 10;
        my $val64 = 2 ** 64 - 10;
        my $cnt = 0;
        my $buf = "timestamp val32 counter32 val64 counter64\n";
        for my $tms( qw/ 2014-09-16T22:55:00 
            2014-09-16T23:00:00 
            2014-09-16T23:05:00 
            2014-09-16T23:10:00 
            2014-09-16T23:15:00 /) {

            $buf .= sprintf("%s %u %u %u %u\n", $tms, $val32, $val32, 2 ** 64, $val64 ++ );
            $val32 += 5;
            if ($val32 > 2 ** 32) {
                $val32 -= 2 ** 32;
            }
            $val64 += 5;
            if ($val64 > 2 ** 64) {
                $val64 -= 2 ** 64;
            }
            
        }

print Dumper(\$buf);
