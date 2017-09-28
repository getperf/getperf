package Getperf::Command::Site::Oracle::SpreportHeader;
use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw/get_headers get_months/;
our @EXPORT_OK = qw/get_headers get_months/;

sub get_headers {
	{
		load_profiles => {
			'Redo'         => 'Redo size',
			'LogicalRd'    => 'Logical reads',
			'BlockChg'     => 'Block changes',
			'PhysicalRd'   => 'Physical reads',
			'PhysicalWr'   => 'Physical writes',
			'Parses'       => 'Parses',
			'HardParses'   => 'Hard parses',
			'Sorts'        => 'Sorts',
			'Logons'       => 'Logons',
			'Executes'     => 'Executes',
			'Transactions' => 'Transactions',
		},

		hits => {
			'BufferNW'    => 'Buffer Nowait %',
			'RedoNW'      => 'Redo NoWait %',
			'BufHit'      => 'Buffer  Hit   %',
			# 'MemSort'     => 'In-memory Sort %',
			'MemSort'     => 'Optimal W/A Exec %',
			'LibHit'      => 'Library Hit   %',
			'SoftParse'   => 'Soft Parse %',
			'ExecParse'   => 'Execute to Parse %',
			'LatchHit'    => 'Latch Hit %',
			'ParseCPU'    => 'Parse CPU to Parse Elapsd %',
			'NonParseCPU' => '% Non-Parse CPU',
		},

		events => {
			'CPUTime'       => 'CPU time',
			'DBScattRd'     => 'db file scattered read',
			'DBSeqRd'       => 'db file sequential read',
			'SQLNetMsg'     => 'SQL\*Net message from dblink',
			'SQLNetMoreDat' => 'SQL\*Net more data from dblink',
			'LogSync'       => 'log file sync',
			'LogParaWr'     => 'log file parallel write',
			'BufferWait'    => 'buffer busy waits',
			'Enqueue'       => 'enq: \D*?',
			'DBParaWr'      => 'db file parallel write',
			'SQLNetClient'  => 'SQL\*Net more data to client',
			'LatchFree'     => 'latch: \D*?',
			'GlobalCacheCr' => 'global cache cr request',
			'FreeBufWait'   => 'free buffer',
		    'ReadByOther'   => 'read by other session',
	    },
	};
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
