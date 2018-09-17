# define GPF_OSNAME        "CentOS6"
# define GPF_OSTAG         "UNIX"
# define GPF_OSTYPE        "Linux"
# define GPF_ARCH          "x86_64"
# define GPF_MODULE_TAG    "CentOS6-x86_64"

my ($osname, $os, $osver, $arch, $module_tag);

my $uname = `uname -a`;
# Solaris,FreeBSD Distributor
if ($uname=~/^(\S+)\s+(\S+)\s+(\S+).+(x86_64|i386|i686|amd64)/) {
	($os, $osver, $arch) = ($1, $3, $4);
	$osver = $1 if ($osver=~/^(\d+\.\d+)/);
	if ($os eq 'Linux') {
		my @lines = readpipe("lsb_release -a");
		for my $line(@lines) {
			chomp($line);
			# Distributor ID: CentOS
			# Release:        6.6
			$os    = $1 if ($line=~/^Distributor ID:\s+(.+?)$/);
			$osver = $1 if ($line=~/^Release:\s+(\d+)/);
		}
	}
	$osname = "${os}${osver}";
	$module_tag = "${os}${osver}-${arch}";
}

my @buf = (
	'#define GPF_OSNAME        "' . $osname . '"',
	'#define GPF_OSTAG         "UNIX"',
	'#define GPF_OSTYPE        "' . $os . '"',
	'#define GPF_ARCH          "' . $arch . '"',
	'#define GPF_MODULE_TAG    "' . $module_tag . '"',
	);

open (OUT, "> include/gpf_common_linux.h");
print OUT join("\n", @buf) . "\n";
close(OUT);

print join("\n", @buf) . "\n";
