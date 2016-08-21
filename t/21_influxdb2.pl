use InfluxDB;

# export PATH=/opt/influxdb/:$PATH
# influx

#  CREATE DATABASE test
#  CREATE RETENTION POLICY mypolicy ON mydb DURATION 1d REPLICATION 1 DEFAULT
#  SHOW RETENTION POLICIES ON mydb
#  CREATE USER scott WITH PASSWORD 'tiger' WITH ALL PRIVILEGES
#  SHOW USERS
 
my $ix = InfluxDB->new(
    host     => '127.0.0.1',
    port     => 8086,
    username => 'scott',
    password => 'tiger',
    database => 'test',
    # ssl => 1, # enable SSL/TLS access
    # timeout => 5, # set timeout to 5 seconds
);
 
$ix->write_points(
    data => {
        name    => "cpu",
        columns => [qw(sys user idle)],
        points  => [
            [20, 50, 30],
            [30, 60, 10],
        ],
    },
) or die "write_points: " . $ix->errstr;
 
my $rs = $ix->query(
    q => 'select * from cpu',
    time_precision => 's',
) or die "query: " . $ix->errstr;
