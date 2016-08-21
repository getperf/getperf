use FindBin;
use lib "$FindBin::Bin/../lib";
use strict;
use Test::More;
use Path::Class;
use Hijk;
use lib "$FindBin::Bin/lib";
use Data::Dumper;

use strict;
    
# curl -G 'http://localhost:8086/query' --data-urlencode "q=CREATE DATABASE mydb"
# Retention policies can be created, modified, listed, and deleted

# CREATE RETENTION POLICY mypolicy ON mydb DURATION 1d REPLICATION 1 DEFAULT
# SHOW RETENTION POLICIES ON mydb
# CREATE USER scott WITH PASSWORD 'tiger' WITH ALL PRIVILEGES
# SHOW USERS

if ($@) { die 'could not authenticate' };

subtest 'influx_base' => sub {
	{

		my $line = "measurement,foo=bar,bat=hoge value=13,otherval=21 1434055562005000035";
		my $res = Hijk::request({
		    method       => 'POST',
		    host         => 'localhost',
		    port         => 8086,
		    path         => "/write",
		    query_string => "db=mydb",
		    body         => $line,
		});
		print Dumper($res);

	}

};

done_testing;
