#include <CUnit/CUnit.h>
#include <CUnit/Console.h>
#include <CUnit/Basic.h>

#include "gpf_config.h"
#include "gpf_common.h"
#include "gpf_log.h"
#include "gpf_process.h"
#include "gpf_daemon.h"
#include "ght_hash_table.h"

#include "unit_test.h"
#include "cunit_test.h"

#if defined(_WINDOWS)
#define _CRTDBG_MAP_ALLOC
#include <crtdbg.h>
#endif

GPFConfig *gpfTestConfig(char *sslDir, int testType);
GPFSetupConfig *gpfTestSetup(int testType);

/**
 * Windowsスレッドのプロトタイプ
 */
#if defined(_WINDOWS)
#include <process.h>

typedef struct {
	GPFConfig *config;
	GPFCollector *collector;
} PARAM, *lpPARAM;

unsigned WINAPI thread1( void *lpx )
{
	lpPARAM lpParam = (lpPARAM)lpx;
	GPFTask *task = NULL;

	task = gpfCreateTask( lpParam->config, lpParam->collector);

	for ( ; ; ){
		printf( "スレッド実行中\n" );
		printf( "statName = %s\n", task->collector->statName );
		sleep( 1 );
	}

	gpfFreeTask( &task );
	return 0;
}

#endif

/**
 * コマンド実行テスト
 *   タイムアウト発生時は終了コードは1とし戻り値は1とする
 *   (採取コマンドによっては意図的にタイムアウトを発生させるため)
 */
void test_gpf_process_001(void)
{
	int result = 0;
	pid_t child;
	int rc;
	char cwd[MAXFILENAME];
	char *testDir , *outPath, *errPath;
	
	getcwd(cwd, sizeof(cwd));
	testDir = gpfCatFile(cwd, "_wk", NULL);
	
	outPath = gpfCatFile(testDir, "child.out", NULL);
	errPath = gpfCatFile(testDir, "child.err", NULL);
	gpfFree( testDir );
	
#if defined(_WINDOWS)
	
	printf ( "[sleep.pl]\n" );
	result = gpfExecCommand("perl sleep.pl", 5, outPath, errPath, &child, &rc);
	CU_ASSERT(result == 1);
	printf ( "  pid = %d\n  rc = %d\n  result=%d\n", child, rc, result);

	printf ( "[ping localhost -n 100]\n" );
	result = gpfExecCommand("ping -n 100 localhost", 5, outPath, errPath, &child, &rc);
	CU_ASSERT(result == 1);
	printf ( "  pid = %d\n  rc = %d\n  result=%d\n", child, rc, result);

	printf ( "[ping localhost -n 2]\n" );
	result = gpfExecCommand("ping -n 2 localhost", 5, outPath, errPath, &child, &rc);
	CU_ASSERT(result == 1);
	printf ( "  pid = %d\n  rc = %d\n  result=%d\n", child, rc, result);

	printf ( "[hoge]\n" );
	result = gpfExecCommand("hoge", 5, outPath, errPath, &child, &rc);
	CU_ASSERT(result == 0);
	printf ( "  pid = %d\n  rc = %d\n  result=%d\n", child, rc, result);

#else
	/* コマンド実行後、タイムアウト */
	/* Linuxの場合タイムアウトチェックを外部で実装したため、タイムアウトのテスト条件は有効とならない 
	printf ( "[vmstat 1 , timeout=5]\n" ); */
/*	result = gpfExecCommand("vmstat 1", 5, outPath, errPath, &child, &rc);
	printf ( "  pid = %d\n  rc = %d\n  result=%d\n", child, rc, result);
	CU_ASSERT(result == 0);
*/	
	/* 正常終了(パス指定なし) */
	printf ( "[ls -l, timeout=5]\n" );
	result = gpfExecCommand("ls -l", 5, outPath, errPath, &child, &rc);
	CU_ASSERT(result == 1);
	printf ( "  pid = %d\n  rc = %d\n  result=%d\n", child, rc, result);
	
	/* 正常終了(パス指定あり) */
	printf ( "[/usr/bin/iostat -x 1 2, timeout=5]\n" );
	result = gpfExecCommand("/usr/bin/iostat -x 1 2", 5, outPath, errPath, &child, &rc);
	CU_ASSERT(result == 1);
	printf ( "  pid = %d\n  rc = %d\n  result=%d\n", child, rc, result);
	
	/* 正常終了。標準出力はオフに設定 */
	printf ( "[ls -l, /dev/null, timeout=5 ]\n" );
	result = gpfExecCommand("ls -l", 5, NULL, NULL, &child, &rc);
	CU_ASSERT(result == 1);
	printf ( "  pid = %d\n  rc = %d\n  result=%d\n", child, rc, result);

	/* コマンドなし。エラー終了 */
	printf ( "[hoge, timeout=5]\n" );
	result = gpfExecCommand("hoge", 5, outPath, errPath, &child, &rc);
	CU_ASSERT(result == 0);
	printf ( "  pid = %d\n  rc = %d\n  result=%d\n", child, rc, result);

#endif

	gpfFree( outPath );
	gpfFree( errPath );
}

/**
 * デーモンプロセス化テスト。Windowsは対象外。
 * 実行後、sleepがデーモンプロセスとして10秒間起動する。
 * ps -ef | grep sleep でプロセスを確認。親プロセスは1であること。
 */
void test_gpf_process_002(void)
{
	int result = 0;
	char cwd[MAXFILENAME];
	char *arglist[3];
	char *exePath = "/bin/sleep";
	char *outPath;
	
	arglist[0] = "sleep";
	arglist[1] = "10";
	arglist[2] = 0;
	
	getcwd(cwd, sizeof(cwd));
	outPath = gpfCatFile(cwd, "_wk", "child.out", NULL);
	
#if defined(_WINDOWS)

#else

/*
 * CUnit自体もデーモンプロセスとなりその他のテストの確認ができないため、デーモン化の確認時以外はコメントアウトする
	result = gpfDaemonStart( exePath, arglist, outPath );
	CU_ASSERT(result == 1);
*/

#endif

	gpfFree( outPath );
}

/**
 * プロセス起動チェック動作確認。必ずいるプロセスID(0または1)と、
 * いないプロセス( 9999 )のチェックを行う。
 */
void test_gpf_process_003(void)
{
	int result = 0;
	
#if defined(_WINDOWS)
//	result = gpfCheckProcess( 0, NULL );
//	CU_ASSERT( result == 0 );

	result = gpfCheckProcess( 4, NULL );	/* システムプロセス */
	CU_ASSERT( result == 1 );

	result = gpfCheckProcess( 4, "getperf" );	/* システムプロセス */
	CU_ASSERT( result == 0 );

		result = gpfCheckProcess( 4, "System" );	/* システムプロセス */
	CU_ASSERT( result == 1 );

	result = gpfCheckProcess( 99999, NULL );
	CU_ASSERT( result == 0 );

	result = gpfKill( 99999 );
	CU_ASSERT( result == 0 );
#else

	result = gpfCheckProcess( 1, NULL );
	CU_ASSERT( result == 1 );

	result = gpfCheckProcess( 99999, NULL );
	CU_ASSERT( result == 0 );

#endif
}

/**
 * コマンド実行テスト。タイムアウトを0として実行後、即時応答する。
 * 取得したプロセスIDが一定期間起動していることを確認する。
 */
void test_gpf_process_004(void)
{
	int result = 0;
	pid_t child;
	int rc;
	char cwd[MAXFILENAME];
	char line[MAX_BUF_LEN];
	char *testDir , *outPath, *errPath;
	FILE *file;
	int status;

	getcwd(cwd, sizeof(cwd));
	testDir = gpfCatFile(cwd, "_wk", NULL);
	
	outPath = gpfCatFile(testDir, "child.out", NULL);
	errPath = gpfCatFile(testDir, "child.err", NULL);
	gpfFree( testDir );
	unlink( outPath );
#if defined(_WINDOWS)
	
	printf ( "[ping localhost -n 3]\n" );
	result = gpfExecCommand("ping -n 3 localhost", 0, outPath, errPath, &child, &rc);
	CU_ASSERT(result == 1);

#else

	printf ( "[ping -c 3 localhost]\n" );
	result = gpfExecCommand("ping -c 3 localhost", 0, outPath, errPath, &child, &rc);
	CU_ASSERT(result == 1);
	
#endif

	printf( "child=%d\n", child );
	CU_ASSERT(child != 0);

	result = gpfCheckProcess( child, NULL );
	CU_ASSERT( result == 1 );

	sleep( 4 );

#if !defined(_WINDOWS)
	/* waitpidしないとゾンビとなりgpfCheckProcess()が有効にならない */
	waitpid(child, &status, 0);
#endif

	result = gpfCheckProcess( child, NULL );
	CU_ASSERT( result == 0 );

	if( (file = fopen(outPath, "r")) != NULL)
	{
		while ( fgets(line, MAX_BUF_LEN, file) != NULL )
		{
			printf( line );
		}
		gpf_fclose( file );
	}

	gpfFree( outPath );
	gpfFree( errPath );
}

/**
 * Windowsスレッドプロトタイプ
 *   {home}\test\cfg\getperf.ini を読み込みダミーコレクターを並列起動する
 * 
 * WindowsのCrtDumpMemoryLeaksを使用としたが、コンソールからの実行だとレポートが出力されない
 *
 * http://www.f13g.com/blog/2007-08-07/
 * 最近のVisualStudioだと，「出力」ウィンドウにこの情報がでない．
 * _CrtDumpMemoryLeaksは，中でOutputDebusStringを使っていますが，これがそもそも動かない．
 * DebugViewを使えば見えますが，これも「デバッグ開始」じゃだめで「デバッグなしで開始」じゃないとうまく行かない．
 * VCはバージョンがあがるたびに，色々な知識をリセットされて憂鬱になります．
 */
void test_gpf_process_005(void)
{
#if defined(_WINDOWS)

	int result;
	GPFConfig *config       = NULL;
	GPFSchedule *schedule   = NULL;
	GPFCollector *collector = NULL;
	char *configFile        = NULL;
	char cwd[MAXFILENAME];
	char *buf;

	HANDLE hThread;
	DWORD thID;
	PARAM param, *testParam;
	INIT_CHECK_MEMORY();

	getcwd(cwd, sizeof(cwd));
	configFile = gpfCatFile(cwd, "cfg", "getperf.ini", NULL);
	result = gpfInitAgent( &config, "gpf_test", configFile, GPF_PROCESS_RUN );
	
	_CrtMemCheckpoint( &s1 );
	for ( collector = config->schedule->collectorStart; 
		collector;
		collector = collector->next )
	{
		printf( "collector=%s\n", collector->statName );
		param.config    = config;
		param.collector = collector;
		testParam = malloc(sizeof(PARAM));
		// マルチスレッドの開始
		hThread = _beginthreadex( NULL, 0, thread1, &param, 0, (unsigned int*)&thID );
		printf( "threadid=%d\n", thID );
	}
	CloseHandle( hThread );
	sleep(5);
//	_CrtMemDumpAllObjectsSince( &s1 );
//	_CrtMemDumpStatistics( &s1 );

//	_CrtDumpMemoryLeaks();	// この時点で開放されていないメモリの情報の表示
//	REINIT_CHECK_MEMORY();
//	CHECK_MEMORY("test_gpf_process_005", "end");

#endif
}

/**
 * コマンド実行動作確認（基本動作）
 */
void test_gpf_process_006(void)
{
	int result = 0;
	pid_t child;
	int rc;
	char cwd[MAXFILENAME];
	char *testDir = NULL, *outPath = NULL, *errPath = NULL, *exe = NULL, *cmd = NULL;
	
	getcwd(cwd, sizeof(cwd));
	testDir = gpfCatFile(cwd, "_wk", NULL);
	
	printf("test6\n");
	outPath = gpfCatFile(testDir, "child.out", NULL);
	errPath = gpfCatFile(testDir, "child.err", NULL);
	gpfFree( testDir );
	
#if defined(_WINDOWS)
	
	exe = gpfCatFile(cwd, "testcmd.exe", NULL);
	cmd = NULL;
	cmd = gpfDsprintf(cmd, "%s -t 5", exe );
printf ( "cmd=%s\n", cmd );
	printf ( "[%s]\n" ,cmd );
	result = gpfExecCommand( cmd , 10, outPath, errPath, &child, &rc);
	CU_ASSERT(result == 1);
	printf ( "pid = %d\n", child );
	gpfFree( cmd );

#else

/* Linuxの場合タイムアウトチェックを外部で実装したため、タイムアウトのテスト条件は有効とならない */
	printf ( "[vmstat 1]\nout=%s\nerr=%s\n", outPath, errPath );
	result = gpfExecCommand("vmstat 1 3", 5, outPath, errPath, &child, &rc);
	CU_ASSERT(result == 1);

#endif

	gpfFree( exe );
	gpfFree( outPath );
	gpfFree( errPath );
}

/**
 * Windowsサービス動作確認（基本動作）
 * 途中で失敗すると残骸が残る場合がある。その場合はsc.exeコマンドで
 * 確認／削除をする。
 */
void test_gpf_process_007(void)
{
	int result = 0;
	char cwd[MAXFILENAME];
	char *path = NULL;
	
#if defined(_WINDOWS)

	getcwd(cwd, sizeof(cwd));
	path = gpfCatFile(cwd, "testcmd.exe", NULL);
	
	/* path 名のサービスの作成 */
	result = gpfCreateService( path );
	CU_ASSERT(result == 1);

	/* サービスの実行 */
	result = gpfStartService( );
	CU_ASSERT(result == 1);

	sleep(1);

	/* サービスの停止 */
	result = gpfStopService( );
	CU_ASSERT(result == 1);

	/* サービスの削除 */
	result = gpfRemoveService( );
	CU_ASSERT(result == 1);

#endif

}

void test_gpf_process_008(void)
{
}

void test_gpf_process_009(void)
{
}

void test_gpf_process_010(void)
{
}

void test_gpf_process_011(void)
{
}

void test_gpf_process_012(void)
{
}

void test_gpf_process_013(void)
{
}

void test_gpf_process_014(void)
{
}

void test_gpf_process_015(void)
{
}

void test_gpf_process_016(void)
{
}

void test_gpf_process_017(void)
{
}

void test_gpf_process_018(void)
{
}

void test_gpf_process_019(void)
{
}

void test_gpf_process_020(void)
{
}

