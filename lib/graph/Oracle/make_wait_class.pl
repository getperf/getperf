open(IN, $ARGV[0]);
while(<IN>) {
	$_=~s/SystemIO/${ARGV[1]}/g;
    $_=~s/: 9,/: ${ARGV[2]},/g;
	print;
}
close(IN);
