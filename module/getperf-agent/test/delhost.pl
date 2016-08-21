use strict;
use DBI;

my ($dbh, $sth);
my $dbh = DBI->connect('DBI:mysql:cm:localhost', 'root', '');
$sth = $dbh->prepare("delete from hosts where hostname='hoge'");
$sth->execute;
$sth->finish;
$dbh->disconnect; 

