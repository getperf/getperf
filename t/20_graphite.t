use FindBin;
use lib "$FindBin::Bin/../lib";
use strict;
use Test::More;
use Path::Class;
use lib "$FindBin::Bin/lib";
use Net::Graphite;
use Data::Dumper;

use strict;

my $graphite = Net::Graphite->new(
     # except for host, these hopefully have reasonable defaults, so are optional
     host                  => '127.0.0.1',
     port                  => 2003,
     trace                 => 0,                # if true, copy what's sent to STDERR
     proto                 => 'tcp',            # can be 'udp'
     timeout               => 5,                # timeout of socket connect in seconds
     fire_and_forget       => 0,                # if true, ignore sending errors
     return_connect_error  => 0,                # if true, forward connect error to caller
 );


eval { $graphite->connect };

if ($@) { die 'could not authenticate' };

subtest 'graphite_base' => sub {
	{
		ok  $graphite->send(
			path => 'foo.bar.baz',
			value => 6,
			time => time(),        # time defaults to "now"
		);
		ok -f '/var/lib/carbon/whisper/foo/bar/baz.wsp';
	}

	{
		my $data = {
			1234567890 => {
			     bar => {
			         db1 => 3,
			         db2 => 7,
			         db3 => 2,
			     },
			     baz => 42,
 			},
 		};
 		ok  $graphite->send(path => 'foo', data => $data);
	}
};


done_testing;
