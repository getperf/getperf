#!/usr/local/bin/perl
use strict;

use POSIX;
use CGI::Carp qw(carpout);
use SOAP::Lite +trace => [qw(debug)]; 

# ����CA�ǂւ̃T�[�o�F��
$ENV{HTTPS_CA_FILE}   = 'cacert.pem';

# �N���C�A���g�F��
$ENV{HTTPS_CERT_FILE} = 'clcert.pem';
$ENV{HTTPS_KEY_FILE}  = 'client.key';

my $URL='https://getperf.moi:57443/axis2/services/GetperfPMService';
#my $URL='http://getperf.moi:57000/axis2/services/GetperfPMService';

my $lvl_str = SOAP::Data->type(string => "1");

my $res = SOAP::Lite 
	-> uri('http://perf.getperf.co.jp')
	-> proxy($URL)
	-> sendEventLog('IZA5971', 'moi', $lvl_str, "Test")
	-> result;

warn $res;
