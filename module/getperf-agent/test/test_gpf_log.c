#include <CUnit/CUnit.h>
#include <CUnit/Console.h>
#include <CUnit/Basic.h>
/* #include <sys/sem.h> */

#include "gpf_config.h"
#include "gpf_common.h"
#include "gpf_log.h"
#include "gpf_param.h"
#include "mutexs.h"
#include "gpf_process.h"
#include "gpf_daemon.h"
#include "ght_hash_table.h"

#include "unit_test.h"
#include "cunit_test.h"

#if defined _WINDOWS
#include        <sys/types.h>
#include        <process.h>
#include        <windows.h>
#endif

static ZBX_MUTEX log_file_access = 0;
int semaphore;

/**
 * ログ出力（ログファイルなしの基本パターン）
 */
int _test_gpf_log_001a(void)
{
	return gpfError("log test[%d][%s]", 1, "test1");
}

int _test_gpf_log_001b(void)
{
	return gpfDebug("log test[%d][%s]", 1, "test1");
}

void test_gpf_log_001(void)
{
	int rc;
	printf("rc = %d\n", ( rc = _test_gpf_log_001a()));
	CU_ASSERT(rc == 0);
	printf("rc = %d\n", ( rc = _test_gpf_log_001b()));
	CU_ASSERT(rc == 1);
	rc = gpfDebug("log test[%d][%s]", 2, "test2");
	CU_ASSERT(rc == 1);
	rc = gpfDebug("log test[%d][%s]", 3, "test3");
	CU_ASSERT(rc == 1);
	/* エラー出力(gpfError())の戻り値は0になること */
	rc = gpfError("log test[%s][%s][%s][%s]", "val1", "val2", "val3", "val4");
	CU_ASSERT(rc == 0);
}

/**
 * ログ出力（ログファイルなし、システムエラーメッセージ出力）
 */
void test_gpf_log_002(void)
{
	char *str = NULL;
	str = gpfErrorFromSystem();
	printf("system=%s\n", str);
	CU_ASSERT(str != NULL);
	gpfSystemError("no system error");

	/* ファイルオープンエラー File not found */
	fopen("hogehoge", "r");
	str = gpfErrorFromSystem();
	printf("system=%s\n", str);
	CU_ASSERT(str != NULL);
	gpfSystemError("hogehoge");
}

/**
 * ログ出力（ログファイル初期化、ロック動作しないこと）
 */
void test_gpf_log_003(void)
{
	char cwd[MAXFILENAME];
	int result;
	double startTime;
	
	GPFConfig *config;
	GPFLogConfig *logConfig;

	getcwd(cwd, sizeof(cwd));

	startTime = gpfTime();

	/* ログの初期化 ({home}\test\_log\getperf.log) */
	config = gpfCreateConfig("hoge", cwd, "test", "testpath", cwd, "getperf.ini");
	result = gpfOpenLog( config, "getperf");
	CU_ASSERT(result == 0);
	printf( "Elapse1 = %-04.2f\n", gpfTime() - startTime );

	/* ログのオープン(ロック待ちが発生しないこと) */
	startTime = gpfTime();
	config->schedule = gpfCreateSchedule();
	config->schedule->debugConsole = 1;
	config->schedule->logLevel     = GPF_DBG;
	result = gpfOpenLog( config, "getperf");
	CU_ASSERT(result == 1);
	printf( "Elapse2 = %-04.2f\n", gpfTime() - startTime );

	startTime = gpfTime();
	GCON = config;
	printf("  logFile : %s\n", config->logConfig->logPath);

	/* エージェント開始メッセージ */
	gpfNotice("Getperf Agent Starting, version : %s(%s)", GPF_VERSION, GPF_OS_NAME);
	printf( "Elapse3 = %-04.2f\n", gpfTime() - startTime );

	gpfNotice("build : %s(%d)", GPF_BUILD_DATE, GPF_BUILD);
	gpfInfo("log test1");

	/* stat_HW.logにログスイッチ */
	result =gpfSwitchLog( config, "stat", "HW");
	CU_ASSERT(result == 1);

	gpfInfo("log test2");

	/* stat_JVM.logにログスイッチ */
	result =gpfSwitchLog( config, "stat", "JVM");
	CU_ASSERT(result == 1);

	gpfInfo("log test3");
	
/*	gpfShowConfig(config); */
	gpfCloseLog(config);

	gpfFreeConfig(&config);
}

/**
 * ログオープンテスト
 */
void test_gpf_log_004(void)
{
	char cwd[MAXFILENAME];
	int result;

	GPFConfig *config;
	GPFLogConfig *logConfig;

	getcwd(cwd, sizeof(cwd));

	/* ログの初期化 ({home}\test\_log\getperf.log) */
	config = gpfCreateConfig("hoge", cwd, "test", "testpath", cwd, "getperf.ini");
	config->schedule = gpfCreateSchedule();

	/* コンソール出力あり、DBGログレベルでオープン */
	config->schedule->debugConsole = 1;
	config->schedule->logLevel     = GPF_DBG;
	result = gpfOpenLog( config, "getperf");
	CU_ASSERT(result == 1);
	GCON = config;
	gpfCloseLog(config);
	gpfFreeConfig(&config);
}

/**
 * ロックテスト(zbx_mutex_lockロックの基本動作確認)
 */
#if defined(_WINDOWS)

unsigned __stdcall counter(void *arg)
{
	int i;
	int	lockFlag;
	int	pid;
	char* filename = "test.txt";
	FILE* fh;
	char rbuf[16], wbuf[16];	

	pid = _getpid();

	lockFlag = (int)arg;

	for(i = 0; i < 3; i++) {
		_sleep(1000);
		printf("[lock=%d]%d\n", lockFlag, i);

		if (lockFlag)
			printf("lock : %d\n", zbx_mutex_lock(&log_file_access));

		if (fh = fopen(filename, "r+")) 
		{
			int loop;
			int rc = 0;
			fread(rbuf, sizeof(char), sizeof(rbuf), fh);
			fseek(fh, 0L, SEEK_SET);
			sleep(1);
			sprintf(wbuf, "%d", rc);
			sprintf(wbuf, "%d", atoi(rbuf)+1);
			fwrite(wbuf, sizeof(char), strlen(wbuf), fh);
			fclose(fh);
			printf("[%d] buf=%s\n", i, wbuf);
		}

		if (lockFlag)
			printf("unlock : %d\n", zbx_mutex_unlock(&log_file_access));
	}

	return(0);
}

int lock_test(int lockFlag)
{
	char* filename = "test.txt";
	FILE* fh;
	char rbuf[16], wbuf[16];	
 	pid_t p_pid, child_pid;
	HANDLE thread_id[10];
	int child;
	int status;
	int result = 0;
	int check = 0;
	unsigned	dummy;

	p_pid=_getpid();

	// ファイルの初期化
	if (fh = fopen(filename, "w")) 
	{
		fclose(fh);
	}
	if (lockFlag)
	{
		printf("create : %d\n",
			zbx_mutex_create_force(&log_file_access, ZBX_MUTEX_LOG));
 	}

	// 親プロセスと子プロセスで同時に以下のコードを走らせる
	for ( child = 0; child < 3; child ++ )
	{
		thread_id[child] = _beginthreadex( NULL, 0, counter, (void *)lockFlag, 0, &dummy);
		if( thread_id[child] == 0 )
		{
			fprintf( stderr,"pthread_create : %s", strerror(thread_id[child]) );
		}
		else
		{
			printf( "[%d][%d] thread_id=%d\n", p_pid, child, thread_id[child] );
		}
	}

	for ( child = 0; child < 3; child ++ )
	{
		WaitForSingleObject( (HANDLE)thread_id[child], INFINITE );
		printf("[%d][%d]thread_id = %d end\n", p_pid, child, thread_id[child] );
	}

	if (fh = fopen(filename, "r+")) 
	{
		fread(rbuf, sizeof(char), sizeof(rbuf), fh);
		fseek(fh, 0L, SEEK_SET);
		result = atoi(rbuf);
		printf("result : %d\n", result);
		fclose(fh);
	}

	if (lockFlag)
		printf("destroy : %d\n", zbx_mutex_destroy(&log_file_access));
	
	return result;
}

#else

int lock_test(int lockFlag)
{
	char* filename = "test.txt";
	FILE* fh;
	char rbuf[16], wbuf[16];	
 	pid_t id, child_pid;
	int status;
	int result = 0;
	int check = 0;

	// ファイルの初期化
	if (fh = fopen(filename, "w")) {
		fclose(fh);
	}
	if (lockFlag)
		printf("create : %d\n",
			zbx_mutex_create_force(&log_file_access, ZBX_MUTEX_LOG));
 
	// 親プロセスと子プロセスで同時に以下のコードを走らせる
	for (int child = 0; child < 3; child ++)
	{
		if ( (id = fork()) == 0)
		{
			for (int i = 0; i < 3; i++) 
			{
				pid_t cur = getpid();

				if (lockFlag)
					printf("lock : %d\n", zbx_mutex_lock(&log_file_access));

				if (fh = fopen(filename, "r+")) 
				{
					int loop;
					int rc = 0;
					fread(rbuf, sizeof(char), sizeof(rbuf), fh);
					fseek(fh, 0L, SEEK_SET);
					sleep(1);
					sprintf(wbuf, "%d", rc);
					sprintf(wbuf, "%d", atoi(rbuf)+1);
					fwrite(wbuf, sizeof(char), strlen(wbuf), fh);
					fclose(fh);
					printf("[%d] %s\n", cur, wbuf);
				}

				if (lockFlag)
					printf("unlock : %d\n", zbx_mutex_unlock(&log_file_access));
			
			}
			exit(0);
		}
	}

	while( (child_pid = waitpid(-1, &status, WNOHANG)) >= 0)
	{
		if (child_pid > 0)
			fprintf(stdout,"PID %d done\n",child_pid);
		else
			sleep(1);
	}
	if (fh = fopen(filename, "r+")) 
	{
		fread(rbuf, sizeof(char), sizeof(rbuf), fh);
		fseek(fh, 0L, SEEK_SET);
		result = atoi(rbuf);
		printf("result : %d\n", result);
		fclose(fh);
	}

	if (lockFlag)
		printf("destroy : %d\n", zbx_mutex_destroy(&log_file_access));
	
	return result;
}

#endif

/**
 * 排他ロックテスト
 */
void test_gpf_log_005(void)
{
	int result;

/* lock_test内でforkをしている。その影響でWindowsだとアプリケーションエラーが発生するため、Windows環境での実行は除外する */
#if !defined(_WINDOWS)	
	/* 排他なし(3並列 x 3カウント) */
	result = lock_test(0);
	CU_ASSERT(result != 9);

	/* 排他あり(3並列 x 3カウント) */
	result = lock_test(1);
	printf("result=%d\n", result);
	CU_ASSERT(9 <= result);
#endif
}

/**
 * セマフォの確保基本動作テスト
 */
void test_gpf_log_006(void)
{
	int result;
	int i;
	
	for (i = 0; i < 3; i++)
	{
		result = zbx_mutex_create_force(&log_file_access, ZBX_MUTEX_LOG);
		CU_ASSERT(result == 1);
		result = zbx_mutex_destroy(&log_file_access);
		CU_ASSERT(result == 1);
	}
}

/**
 * セマフォプロトタイプ(現在未使用)
 */
void test_gpf_log_007(void)
{
/*
	int i;
	
	union semun
	{
		int val;
		struct semid_ds *buf;
		unsigned short int *array;
		struct seminfo *__buf;
	};

	key_t	sem_key;
	union semun semunion;
	struct semid_ds seminfo;

	for (i = 0; i < 3; i++)
	{
		semaphore = zbx_mutex_create_force(&log_file_access, ZBX_MUTEX_LOG);
		printf("semaphore=%d\n", semaphore);
		if((sem_key = ftok(".", (int)'z') ) == -1)
			return perror("Can not create IPC key for path '.'");
	
		semaphore = semget(sem_key, 1, IPC_CREAT | IPC_EXCL | 0666);
		printf("semaphore : %d\n", semaphore);
		if (semaphore == -1)
			return perror("semget failure");
	
		semunion.val = 1;
		if (semctl(semaphore, 0, SETVAL, semunion) == -1)
			return perror("semctl(init) failure");

		if (semctl(semaphore, 0, IPC_RMID, semunion) == -1)
			return perror("semctl(delete) failure");
		printf("destroy : %d\n", zbx_mutex_destroy(&log_file_access));
	}
*/
}

/**
 * ログスイッチテスト(test_gpf_log_003()とほぼ同じ内容)
 */
void test_gpf_log_008(void)
{
	char cwd[MAXFILENAME];
	int result;

	GPFConfig *config;
	GPFLogConfig *logConfig;

	/* ログの初期化 ({home}\test\_log\getperf.log) */
	getcwd(cwd, sizeof(cwd));
	config = gpfCreateConfig("hoge", cwd, "test", "testpath", cwd, "getperf.ini");

	/* コンソール出力あり、DBGログレベルでオープン */
	config->schedule = gpfCreateSchedule();
	config->schedule->debugConsole = 1;
	config->schedule->logLevel     = GPF_DBG;
	result = gpfOpenLog( config, "getperf");
	CU_ASSERT(result == 1);
	GCON = config;
	printf("  logFile : %s\n", config->logConfig->logPath);

	result = gpfDebug("debug");
	CU_ASSERT(result == 1);
	result = gpfDebug("info");
	CU_ASSERT(result == 1);
	result = gpfNotice("notice");
	CU_ASSERT(result == 1);
	result = gpfWarn("warn");
	CU_ASSERT(result == 1);
	result = gpfError("error");
	CU_ASSERT(result == 0);
	result = gpfSystemError("system error");
	CU_ASSERT(result == 0);
	result = gpfCrit("critical");
	
	result = gpfSwitchLog( config, "stat", "HW");

	result = gpfDebug("debug");
	CU_ASSERT(result == 1);
	result = gpfDebug("info");
	CU_ASSERT(result == 1);
	result = gpfNotice("notice");
	CU_ASSERT(result == 1);
	result = gpfWarn("warn");
	CU_ASSERT(result == 1);
	result = gpfError("error");
	CU_ASSERT(result == 0);
	result = gpfSystemError("system error");
	CU_ASSERT(result == 0);
	result = gpfCrit("critical");

	gpfCloseLog(config);
	gpfFreeConfig(&config);
}

/**
 * ログローテーションテスト
 */
void test_gpf_log_009(void)
{
	char cwd[MAXFILENAME];
	int i;
	char *logPath = NULL;
	int result    = 0;
	FILE *file    = NULL;

	getcwd(cwd, sizeof(cwd));
	logPath = gpfCatFile(cwd, "_log", "test.log", NULL);
	printf("log: %s\n", logPath);

	/* ログサイズ下限値を0、世代数を3にして5回ログローテーション実行 */
	for (i = 0; i < 5; i++)
	{
		file = fopen(logPath, "a+");
		fprintf(file, "0123456789\n");
		fclose(file);
	
		result = gpfLogRotate( logPath, 0, 3);
		CU_ASSERT(result == 1);
	}
	gpfFree(logPath);
}

/**
 * メッセージテスト
 */
void test_gpf_log_010(void)
{
	char cwd[MAXFILENAME];
	int result;

	GPFConfig *config;
	GPFLogConfig *logConfig;

	/* ログの初期化前でも使用可能 */
	result = gpfMessage(GPF_MSG001E, GPF_MSG001);
	CU_ASSERT(result == 1);
	result = gpfMessageCROff(GPF_MSG001E, GPF_MSG001);
	CU_ASSERT(result == 1);
	fputs("|\n", stdout);
	
	/* ログの初期化 ({home}\test\_log\getperf.log) */
	getcwd(cwd, sizeof(cwd));
	config = gpfCreateConfig("hoge", cwd, "test", "testpath", cwd, "getperf.ini");
	config->localeFlag = 0;
	GCON = config;

	result = gpfMessage(GPF_MSG001E, GPF_MSG001);
	CU_ASSERT(result == 1);
	result = gpfMessageCROff(GPF_MSG001E, GPF_MSG001);
	CU_ASSERT(result == 1);
	fputs("|\n", stdout);
}

void test_gpf_log_011(void)
{
	char cwd[MAXFILENAME];
	int result;

	GPFConfig *config;
	GPFLogConfig *logConfig;

	/* ログの初期化前でも使用可能 */
	getcwd(cwd, sizeof(cwd));
	config = gpfCreateConfig("hoge", cwd, "test", "testpath", cwd, "getperf.ini");
	config->localeFlag = 0;
	GCON = config;
	printf( "TEST1" ); sleep(1);
	result = gpfMessageOKNG(1);
	CU_ASSERT(result == 1);
	printf( "TEST2" ); sleep(1);
	result = gpfMessageOKNG(0);
	CU_ASSERT(result == 1);
}

void test_gpf_log_012(void)
{
}

void test_gpf_log_013(void)
{
}

void test_gpf_log_014(void)
{
}

void test_gpf_log_015(void)
{
}

void test_gpf_log_016(void)
{
}

void test_gpf_log_017(void)
{
}

void test_gpf_log_018(void)
{
}

void test_gpf_log_019(void)
{
}

void test_gpf_log_020(void)
{
}

