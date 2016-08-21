package Getperf::Command::Site::SystemInfo::UnameA;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use base qw(Getperf::Container);

sub new {bless{},+shift}

sub parse {
    my ($self, $data_info) = @_;

	my $host = $data_info->host;

	open( IN, $data_info->input_file ) || die "@!";
	my $line = <IN>;
	$line=~s/(\r|\n)*//g;	# trim return code
	#Linux ostrich 3.13.0-39-generic #66-Ubuntu SMP Tue Oct 28 13:30:27 UTC 2014 x86_64 x86_64 x86_64 GNU/Linux
	#Linux localhost.localdomain 2.6.32-504.el6.x86_64 #1 SMP Wed Oct 15 04:27:16 UTC 2014 x86_64 x86_64 x86_64 GNU/Linux
	if ($line=~/^(.+?) (.+?) (.+?) #(.*?)$/) {
		my $arch = 'unkown';
		my ($os, $hostname, $kernel, $body) = ($1, $2, $3, $4);
		if ($body=~/x86_64/) {
			$arch = 'x86_64';
		} elsif ($body=~/i386/) {
			$arch = 'i386';	
		} elsif ($body=~/sparc/) {
			$arch = 'sparc';	
		}
		my %stat = (
			kernel => $kernel,
			arch   => $arch,
		);
		$data_info->regist_node($host, 'Linux', 'info/arch', \%stat);

	#SunOS y5ibkup01b 5.10 Generic_142909-17 sun4v sparc SUNW,SPARC-Enterprise-T5120
	#SunOS sol        5.10 Generic_147148-26 i86pc i386  i86pc
	} elsif ($line=~/^(.+?) (.+?) (.+?) (.+?) (.+?) (.+?) (.+?)$/) {
		my ($os, $hostname, $ver, $generic, $arch) = ($1, $2, $3, $4, $7);
		my %stat = (
			kernel => "${os} ${ver} ${generic}",
			arch   => $arch,
		);
		$data_info->regist_node($host, 'Solaris', 'info/arch', \%stat);
	}
	close(IN);


	return 1;
}
1;
