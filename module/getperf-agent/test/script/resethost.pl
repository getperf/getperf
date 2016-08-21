#!/usr/local/bin/perl
use strict;

use POSIX;
use CGI::Carp qw(carpout);
use SOAP::Lite; # +trace => [qw(debug)]; 
use DBI;

my $host = 'host2b';
$host = $ARGV[0] if ($ARGV[0] ne "");

&main();
exit;

sub reset_host
{
	my ($hostname) = @_;

	print "Delete from hosts : $hostname\n";
	my $user = 'cmuser';
	my $passwd = 'cmpass';
	my $db = DBI->connect('DBI:mysql:cm:localhost', $user, $passwd);
	my $sth = $db->prepare("DELETE FROM hosts WHERE hostname='$hostname'");
	$sth->execute;
	$sth->finish;
	$sth = $db->prepare("DELETE FROM hosts_stats WHERE host_id in (SELECT id FROM hosts WHERE hostname='$hostname')");
	$sth->execute;
	$sth->finish;
	$sth = $db->prepare("update metric_templates set test_cmd_opt = '-hoge' where cmd = 'netstat'");
	$sth->execute;
	$sth->finish;
	$db->disconnect;
}

sub main
{
	reset_host($host);
}

