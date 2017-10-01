#!//usr/bin/perl
#        inet 10.152.16.67 netmask fffff800 broadcast 10.152.23.255

my %services = (
	'/aldb/dat1/control01.ctl' => 'ALDB',
);

for my $path(keys %services) {
	if (-f $path) {
		print $services{$path} . "\n";
	}
}
