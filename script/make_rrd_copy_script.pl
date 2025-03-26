#!/bin/env perl
my $SOURCE_SERVER = '192.168.41.161';
my ($nodes, $platforms);

while(my $line = <>) {
    $line=~s/(\r|\n)*//g;
    $platform = $line;
    $platform=~s/\/.+//;
    $platforms->{$platform} = 1;
    $nodes->{$line} = $platform;
    print "$line $platform\n";
}

# mkdir -p storage/Linux/
for my $platform(sort keys %{$platforms}) {
    print "mkdir -p storage/$platform\n";
}

# rsync -av rsync://192.168.41.161/site_kit1/storage/Linux/kc-test03 storage/Linux/

for my $node(sort keys %{$nodes}) {
    my $platform = $nodes->{$node};
    print "rsync -av rsync://${SOURCE_SERVER}/site_kit1/storage/${node} storage/${platform}\n";
}
