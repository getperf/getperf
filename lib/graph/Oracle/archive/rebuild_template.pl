#!/bin/perl
use strict;
use Data::Dumper;
print Dumepr \%ARGV;

open(IN, $ARGV[0]);
while(<IN>) {
    if ($_=~/\"priority\": /) {
        print "  \"priority\": ${ARGV[1]},\n";
    # } elsif ($_=~/\"graph_tree\": /) {
    #     print "      \"graph_tree\": \"${ARGV[2]}\",\n";
    } else{ 
        print;

    }
    # $_=~s/SystemIO/${ARGV[1]}/g;
    # $_=~s/: 9,/: ${ARGV[2]},/g;
}
close(IN);
