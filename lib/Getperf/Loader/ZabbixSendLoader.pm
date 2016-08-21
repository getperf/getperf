use strict;
use warnings;
package Getperf::Loader::ZabbixSendLoader;
use Path::Class;
use Time::Piece;
use Object::Container '-base';
use Log::Handler app => "LOG";
use parent qw(Class::Accessor::Fast);
use Data::Dumper;
use base qw(Getperf::Container);
use Getperf::Config 'config';
use Getperf::Loader::ZabbixSend;
__PACKAGE__->mk_accessors(qw/type/);

our $VERSION = '0.01';

sub new {
	my $class = shift;

	bless {
		type => 'ZabbixSender',
		@_,
	}, $class;
}

sub run {
	my ($self, $data_info) = @_;

	$self->{row} = 0;
	my $output_path = $data_info->absolute_summary_dir . '/zabbix_send_data.txt';
	if (-f $output_path) {
		$self->write_data($data_info, $output_path);
		LOG->info('[ZabbixCache] load ' . $self->{row});
	}
}

sub write_data {
	my ($self, $data_info, $load_path) = @_;
	my $zabbixSend = Getperf::Loader::ZabbixSend->new($data_info);
	$zabbixSend->load_data($load_path);
	$self->{row} += $zabbixSend->{row};
}

1;
