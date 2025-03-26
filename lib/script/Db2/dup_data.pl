my $src = $ARGV[0];
my $dest = $ARGV[1];

my $usage = "dup_data.pl storage/Db2/CAPA_D1-MMDB-0/db2_session.rrd storage/Db2/CAPA_D1-MMDB-0/db2_session.rrd";

if ($src !~ m|storage/Db2/(.+?)\.rrd|) {
    die $usage;
}
my ($src_file) = ($1);

if ($dest !~ m|storage/Db2/(.+?)\.rrd|) {
    die $usage;
}
my ($dest_file) = ($1);

print "($src, $dest_file, $src_file)\n";
print "rrd-cli --create storage/Db2/${dest_file}.rrd --from storage//Db2/${src_file}.rrd\n";

my $src_node = "node/Db2/${src_file}.json";
my $dest_node = "node/Db2/${dest_file}.json";

open (IN, $src_node) || die "$usage:$!";
open (OUT, $dest_node) || die "$usage:$!";
$src  =~s/storage\///g;
$dest =~s/storage\///g;
print "${src}|${dest}\n";
while (<IN>) {

    $_=~sm|${src}|${dest}|g;
    print $_;
}
print "${src_node} ${dest_node}\n";
#cp node/Db2/CAPA_D1-MMDB-1/db2_session.json node/Db2/CAPA_D1-MMDB-0/db2_session.json
