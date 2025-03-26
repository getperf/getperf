package Getperf::Command::Site::Oracle::AwrreportHeaderRac;
use strict;
use warnings;
use Data::Dumper;

use Exporter 'import';
our @EXPORT = qw/get_headers get_months/;
our @EXPORT_OK = qw/get_headers get_months/;

sub get_headers0 {
  {
    # Time Model
    time_models => [
      'DBtime'         , 'DB time',
      'DBCPU'          , 'DB CPU',
      'DBEla'          , 'SQL Ela',
      'SQLParse'       , 'SQL Parse Ela',
      'HardParseEla'   , 'Hard Parse Ela',
      'HardParsePLSQL' , 'Hard Parse PL/SQL Ela',
      'HardParseJava'  , 'Hard Parse Java Ela',
      'bgtime'         , 'bg time',
      'bgCPU'          , 'bg CPU',
    ],
    # Foreground Wait Classes
    'foreground_waits' => [
      'UserIO'   , 'User I/O(s)',
      'SysIO'    , 'Sys I/O(s)',
      'Other'    , 'Other(s)',
      'Applic'   , 'Applic (s)',
      'Commit'   , 'Commit (s)',
      'Network'  , 'Network (s)',
      'Concurcy' , 'Concurcy (s)',
      'Config'   , 'Config (s)',
      'Cluster'  , 'Cluster (s)',
      'DBCPU'    , 'DB CPU (s)',
      'DBTime'   , 'DB time',
    ],
    # Top Timed Events
    events => [
      'GcCrBlockBusy'  , 'gc cr block busy',
      'GcCrBlock3way'  , 'gc cr block 3-way',
      'DirectRd'       , 'direct path read',
      'DBCpu'          , 'DB CPU',
      'LatchCache'     , 'latch: cache buffers chains',
      'GcBufferBusy'   , 'gc buffer busy acquire',
      'EnqPs'          , 'enq: PS - contention',
      'ReliableMsg'    , 'reliable message',
      'IPCSync'        , 'IPC send completion sync',
      'PXDeqSlaveSes'  , 'PX Deq: Slave Session Stats',
      'GcCrMultiBlock' , 'gc cr multi block request',
      'LatchFree'      , 'latch free',
    ],
    # Top Timed Background Events
    bg_events => [
      'CPUTime'          , 'background cpu time', 
      'GCGrant2way'      , 'gc current grant 2-way', 
      'LatchFree'        , 'latch free', 
      'GCMultBlkRd'      , 'gc current multi block request', 
      'ReliableMsg'      , 'reliable message', 
      'GCGrantCongested' , 'gc current grant congested', 
      'PXDeq'            , 'PX Deq: Slave Join Frag', 
      'EnqFB'            , 'enq: FB - contention', 
      'BuffBusyWait'     , 'buffer busy waits', 
      'EnqTx'            , 'enq: TX - contention', 
    ],
    # System Statistics - Per Second : SystemStatistics
    sys_statistics => [
      'LogicalReads'   , 'Logical Reads/s',
      'PhysicalReads'  , 'Physical Reads/s',
      'PhysicalWrites' , 'Physical Writes/s',
      'RedoSize'       , 'Redo Size (k)/s',
      'BlockChanges'   , 'BlockChanges/s',
      'Calls'          , 'Calls/s',
      'Execs'          , 'Execs/s',
      'Parses'         , 'Parses/s',
      'Logons'         , 'Logons/s',
      'Txns'           , 'Txns/s',
    ],
    # Global Cache Efficiency Percentages : CacheEfficiency
    cache_efficiencys => [
        'Local'  , 'Local %',
        'Remote' , 'Remote %',
        'Disk'   , 'Disk %',
    ],
    # Ping Statistics : PingStatistics
    ping_statistics => [
      '500bytes' , '500 bytes',
      '8Kbytes'  , '8 Kbytes',
    ],
    # Interconnect Client Statistics (per Second) : InterconnectTraffic
    interconnect_traffics => [
      'Sent'     , 'Sent (MB/s)',
      'Received' , 'Received (MB/s)',
    ],
  }
}

sub get_headers {
  my $headers = get_headers0();
  for my $header_key (keys %{$headers}) {
    # print "HEADER_KEY: $header_key\n";
    # print Dumper $headers->{$header_key};
    my $row = 0;
    my $keyword = '';
    my %headers_hash;
    my @header_names;
    foreach my $value(@{$headers->{$header_key}}) {
      $row ++;
      if ($row % 2 == 1) {
        $keyword = $value;
        push @header_names, $keyword;
      } else {
        $headers_hash{$keyword} = $value;
      }
    }
    $headers->{"${header_key}"}  = \%headers_hash;
    $headers->{"_${header_key}"} = \@header_names;
  }
  return $headers;
}

sub get_months {
	{
    '1月', 1, '2月', 2, '3月', 3, '4月', 4, '5月', 5, '6月', 6, '7月', 7,
    '8月', 8, '9月', 9, '10月', 10, '11月', 11, '12月', 12,
    'Jan', 1, 'Feb', 2, 'Mar', 3, 'Apr', 4, 'May', 5, 'Jun', 6, 'Jul', 7,
    'Aug', 8, 'Sep', 9, 'Oct', 10, 'Nov', 11, 'Dec', 12
    };
}

1;
