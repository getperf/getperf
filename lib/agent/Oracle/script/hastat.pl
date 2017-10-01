#!//usr/bin/perl

# In case of service network ip.
#        inet 10.152.16.67 netmask fffff800 broadcast 10.152.23.255

my @buf = `/sbin/ifconfig -a`;
my %services = (
	'192.168.10.2' => 'orcl',
);

for my $line(@buf) {
	if ($line=~/(inet.*?)(\d.*?)\s/) {
		my $ip = $2;
		if (defined(my $service = $services{$ip})) {
			print $service . "\n";
		}
	}
}

# In case of control file path check.
# 
# my %services = (
# 	'/u01/dat1/control01.ctl' => 'orcl',
# );
# for my $path(keys %services) {
# 	if (-f $path) {
# 		print $services{$path} . "\n";
# 	}
# }
