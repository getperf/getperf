package Getperf::Command::Site::Oracle::Base::CactiDB;
use strict;
use warnings;
use Data::Dumper;
use Time::Piece;
use base qw(Getperf::Container);
use Getperf::Command::Master::Oracle;
use Exporter 'import';
our @EXPORT = qw/update_cacti_graph_item/;
our @EXPORT_OK = qw/update_cacti_graph_item/;

sub new {bless{},+shift}

sub update_cacti_graph_item {
	my ($data_info, $sql_hash, $graph_templates_item_id, $data_template_data_id, $rra ) = @_;

	my $update_item =
		"UPDATE graph_templates_item " .
		"SET text_format = '$sql_hash' " .
		"WHERE id = $graph_templates_item_id";
	$data_info->cacti_db_dml($update_item);

	my $update_rrd =
		"UPDATE data_template_data " .
		"SET data_source_path = '$rra' " .
		"WHERE id = $data_template_data_id";
	$data_info->cacti_db_dml($update_rrd);
}

1;
