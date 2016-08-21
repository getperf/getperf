#!/usr/bin/perl
use Data::Dumper;
use Path::Class;

if (!$ARGV[0]) {
	die "Usage: make_color_list.pl {color}.txt\n";
}
my $color_file = file($ARGV[0]);
my @color_list = $color_file->slurp(chomp => 1);
my $color_list_name = $color_file->basename;
$color_list_name=~s/\..*//g;
make_color_list_json($color_list_name, \@color_list);
make_color_list_html($color_list_name, \@color_list);
exit;

sub make_color_list_html {
	my ($color_list_name, $color_list_buffers) = @_;
	my @buf = ();
	push @buf, "<body><table>";
	for my $line(@$color_list_buffers) {
		next if ($line!~/\s*(\d+)\s+(\w+)/);
		my ($id, $color) = ($1, $2);
	  	push @buf, "<tr><td>$id</td>";
	  	push @buf, "<td><span style=\"background:#$color\">$color</span></td></tr>";
	}
	push @buf, "</table></body>";

	my $writer = file("${color_list_name}.html")->open('w') or die $!;
	$writer->print(join("\n", @buf));
	$writer->close;
}

sub make_color_list_json {
	my ($color_list_name, $colors) = @_;
	my $row_n = scalar(@$colors);
	my $row = 1;
	my @buf = ();
	push @buf, "[";
	for my $line(@$colors) {
		next if ($line!~/\s*(\d+)\s+(\w+)/);
		my ($id, $color) = ($1, $2);
		push @buf, "   {";
		push @buf, "      \"id\":  \"$id\",";
		push @buf, "      \"hex\": \"$color\"";
		push @buf, ($row != $row_n) ? "   }," : "   }";
		$row ++;
	}
	push @buf, "]";
	my $writer = file("${color_list_name}.json")->open('w') or die $!;
	$writer->print(join("\n", @buf));
	$writer->close;
}
