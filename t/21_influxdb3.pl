#!/usr/bin/perl

use strict;
use LWP::UserAgent;
use Data::Dumper;

my $ua = LWP::UserAgent->new;
my $url = "http://localhost:8086/write?db=mydb";
my $line = "measurement,foo=bar2,bat=hoge value=13,otherval=21";

my $req= HTTP::Request->new(POST => $url);

$req->content($line);

print $ua->request($req)->as_string;
