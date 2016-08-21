#include <CUnit/CUnit.h>
#include <CUnit/Console.h>
#include <CUnit/Basic.h>

#include "gpf_config.h"
#include "gpf_common.h"
#include "gpf_log.h"
#include "gpf_param.h"

#include "unit_test.h"
#include "cunit_test.h"

/**
 * 1行パラメータ解析（基本パターン、数値パラメータ）
 */
void test_gpf_param_001(void)
{
	char *line;
	int result;
	GPFSchedule *schedule;
	schedule = gpfCreateSchedule();

	line = strdup("DISK_CAPACITY = 10");
	result = gpfLoadConfig(schedule, GPF_CONFIG_TYPE_BUFFER, NULL, line);
	gpfFree(line);
	CU_ASSERT(schedule != NULL && schedule->diskCapacity == 10);
	CU_ASSERT(result == 1);
	gpfShowSchedule(schedule);  

	result = gpfLoadConfig(schedule, GPF_CONFIG_TYPE_BUFFER, NULL, NULL);
	CU_ASSERT(result == 0);

	gpfFreeSchedule(&schedule);
}

/**
 * test/cfg/getperf.ini ファイルパラメータ解析（基本パターン）
 */
void test_gpf_param_002(void)
{
	char cwd[MAXFILENAME];
	char *paramPath  = NULL;
	int result;
	GPFSchedule *schedule;

	schedule = gpfCreateSchedule();

	getcwd(cwd, sizeof(cwd));
	paramPath = gpfCatFile(cwd, "cfg", "getperf.ini", NULL);
	printf("%s\n", paramPath);
	result = gpfLoadConfig(schedule, GPF_CONFIG_TYPE_FILE, paramPath, NULL);
	gpfFree(paramPath);

	CU_ASSERT(schedule != NULL 
		&& schedule->saveHour     == 24 
		&& schedule->recoveryHour ==  3 
		&& schedule->maxErrorLog  ==  5 
		&& schedule->logLevel     ==  7 
		&& schedule->debugConsole ==  1 
		&& schedule->hanodeEnable ==  0 
		&& strcmp(schedule->hanodeCmd, "hastatus.sh") == 0
		&& schedule->postEnable   ==  0 
		&& strcmp(schedule->postCmd,   "ncftpput -u user -p pass host target_dir __zip__") == 0
		&& schedule->proxyEnable  ==  0 
		&& strcmp(schedule->proxyHost, "http.proxy.hoge.co.jp") == 0
		&& schedule->proxyPort    ==  8080 
		&& schedule->soapTimeout  ==  300 
		&& schedule->status       == GPF_PROCESS_INIT
		&& schedule->_last_update == 0
	);
	CU_ASSERT(result == 1);

	gpfShowSchedule(schedule);  
	gpfFreeSchedule(&schedule);
}

/**
 * 1行パラメータ解析（正常ケース、異常ケース混合）
 */
void test_gpf_param_003(void)
{
	char *line;
	int result;
	GPFSchedule *schedule;
	GPFJob      *job;
	schedule = gpfCreateSchedule();

	/* 真偽値の解析 */
	line = strdup("STAT_ENABLE.HW = true");
	result = gpfLoadConfig(schedule, GPF_CONFIG_TYPE_BUFFER, NULL, line);
	gpfFree(line);
	CU_ASSERT(schedule->collectorStart != NULL && 
		schedule->collectorStart->statEnable == 1);
	CU_ASSERT(result == 1);

	/* コレクターパラメータの解析 */
	line = strdup("STAT_MODE.HW = concurrent");
	result = gpfLoadConfig(schedule, GPF_CONFIG_TYPE_BUFFER, NULL, line);
	gpfFree(line);
	CU_ASSERT(schedule->collectorStart != NULL && 
		schedule->collectorStart->statMode != NULL);
	CU_ASSERT(result == 1);

	/* コレクターコマンドの解析 */
	line = strdup("STAT_CMD.HW = 'vmstat 3 3 > _odir_/vmstat.txt'");
	result = gpfLoadConfig(schedule, GPF_CONFIG_TYPE_BUFFER, NULL, line);
	gpfFree(line);
	job = schedule->collectorStart->jobStart;
	CU_ASSERT(job != NULL && strcmp(job->cmd, "vmstat 3 3 > _odir_/vmstat.txt") == 0);
	CU_ASSERT(result == 1);

	/* コレクターコマンドの解析エラー。括り文字("と') */
	line = strdup("STAT_CMD.HW = 'vmstat 3 3 > _odir_/vmstat.txt\"");
	result = gpfLoadConfig(schedule, GPF_CONFIG_TYPE_BUFFER, NULL, line);
	gpfFree(line);
	CU_ASSERT(result == 0);

	/* コメントの解析 */
	line = strdup("; hogehoge");
	result = gpfLoadConfig(schedule, GPF_CONFIG_TYPE_BUFFER, NULL, line);
	gpfFree(line);
	CU_ASSERT(result == 1);

	line = strdup("   ; hogehoge");
	result = gpfLoadConfig(schedule, GPF_CONFIG_TYPE_BUFFER, NULL, line);
	gpfFree(line);
	CU_ASSERT(result == 1);

	/* 文字列の解析(前後の空白文字は取り除かれていること) */
	line = strdup("	 SITE_KEY                =    hoge hoge\t\t");
	result = gpfLoadConfig(schedule, GPF_CONFIG_TYPE_BUFFER, NULL, line);
	gpfFree(line);
	CU_ASSERT(schedule != NULL && strcmp(schedule->siteKey, "hoge hoge") == 0);
	CU_ASSERT(result == 1);
	
	/* コレクターコマンドの解析エラー。種別なし */
	line = strdup("STAT_ENABLE. = true");
	result = gpfLoadConfig(schedule, GPF_CONFIG_TYPE_BUFFER, NULL, line);
	gpfFree(line);
	CU_ASSERT(result == 0);

	/* 未登録項目の解析エラー */
	line = strdup("HOGE = true");
	result = gpfLoadConfig(schedule, GPF_CONFIG_TYPE_BUFFER, NULL, line);
	gpfFree(line);
	CU_ASSERT(result == 0);

	/* 数値の解析エラー */
	line = strdup("DISK_CAPACITY = hoge");
	result = gpfLoadConfig(schedule, GPF_CONFIG_TYPE_BUFFER, NULL, line);
	gpfFree(line);
	CU_ASSERT(result == 0);

	/* 未登録項目の解析エラー(数値) */
	line = strdup("LOG_SIZE = 10");
	result = gpfLoadConfig(schedule, GPF_CONFIG_TYPE_BUFFER, NULL, line);
	gpfFree(line);
	CU_ASSERT(result == 0);

	/* 真偽項目の解析エラー */
	line = strdup("REMHOST_ENABLE = 10");
	result = gpfLoadConfig(schedule, GPF_CONFIG_TYPE_BUFFER, NULL, line);
	gpfFree(line);
	CU_ASSERT(result == 0);

	gpfFreeSchedule(&schedule);
}

/**
 * 1行パラメータ解析エラー（バッファオーバーフロー）
 */
void test_gpf_param_004(void)
{
	char *line = NULL;
	int result;
	char *huge  = NULL;
	GPFSchedule *schedule;
	schedule = gpfCreateSchedule();
	
	/* 異常ケース NULL 文字 */
	result = gpfLoadConfig(schedule, GPF_CONFIG_TYPE_BUFFER, NULL, NULL);
	gpfFree(line);
	CU_ASSERT(result == 0);
	
	/* 異常ケース バッファオーバフロー */
	huge = (char *)gpfMalloc(huge, sizeof(char) * (MAX_STRING_LEN + 1));
	memset(huge, '0', MAX_STRING_LEN);
	huge[MAX_STRING_LEN] = '\0';

	result = gpfLoadConfig(schedule, GPF_CONFIG_TYPE_BUFFER, NULL, huge);
	gpfFree(huge);
	CU_ASSERT(result == 0);
	
	gpfFreeSchedule(&schedule);
}

/**
 * test/cfg/ssl/License.txt SSLライセンスファイルの解析
 */
void test_gpf_param_005(void)
{
	char cwd[MAXFILENAME];
	char *paramPath  = NULL;
	int result;
	GPFConfig *config;
	GPFSSLConfig *sslConfig;

	getcwd(cwd, sizeof(cwd));
	config = gpfCreateConfig("hoge", cwd, "test", "testpath", cwd, "getperf.ini");

	paramPath = gpfCatFile(cwd, "cfg", "ssl", "License.txt", NULL);
	printf("%s\n", paramPath);

	sslConfig = gpfCreateSSLConfig();
	result = gpfLoadSSLLicense(sslConfig, paramPath);
	gpfFree(paramPath);
	CU_ASSERT(result == 1);

	config->sslConfig = sslConfig;
	gpfShowConfig(config);
	gpfFreeConfig(&config);
}

/**
 * 採取コマンドの解析
 */
void test_gpf_param_006(void)
{
	char *line;
	int result;
	GPFSchedule *schedule;
	GPFJob      *job;
	schedule = gpfCreateSchedule();

	/* 標準パターン 「項目.種別 = 'コマンド'」 */
	line = strdup("STAT_CMD.HW = 'vmstat 3 3 > _odir_/vmstat.txt'");
	result = gpfLoadConfig(schedule, GPF_CONFIG_TYPE_BUFFER, NULL, line);
	gpfFree(line);
	job = schedule->collectorStart->jobStart;
	gpfShowJobs(job);
	CU_ASSERT(job != NULL && strcmp(job->cmd, "vmstat 3 3 > _odir_/vmstat.txt") == 0);
	CU_ASSERT(result == 1);

	/* 標準パターン 「項目.種別 = 'コマンド',出力ファイル」 */
	line = strdup("STAT_CMD.HW = 'vmstat 3 3',vmstat.txt");
	result = gpfLoadConfig(schedule, GPF_CONFIG_TYPE_BUFFER, NULL, line);
	gpfFree(line);
	job = job->next;
	gpfShowJobs(job);
	CU_ASSERT(job != NULL && strcmp(job->cmd,   "vmstat 3 3") == 0);
	CU_ASSERT(job != NULL && strcmp(job->ofile, "vmstat.txt") == 0);
	CU_ASSERT(result == 1);

	/* 標準パターン 「項目.種別 = 'コマンド',出力ファイル,実行間隔,回数」 */
	line = strdup("STAT_CMD.HW = 'netstat -s',netstats.txt,30,10");
	result = gpfLoadConfig(schedule, GPF_CONFIG_TYPE_BUFFER, NULL, line);
	gpfFree(line);
	job = job->next;
	gpfShowJobs(job);
	CU_ASSERT(job != NULL && strcmp(job->cmd,   "netstat -s") == 0);
	CU_ASSERT(job != NULL && strcmp(job->ofile, "netstats.txt") == 0);
	CU_ASSERT(job->cycle == 30);
	CU_ASSERT(job->step == 10);
	CU_ASSERT(result == 1);

	/* 標準パターン 「項目.種別 = 'コマンド',出力ファイル,実行間隔,回数(間に空白文字あり」 */
	line = strdup("STAT_CMD.HW = 'netstat -s'\t ,\tnetstats.txt\t ,\t20\t ,\t11\t ");
	result = gpfLoadConfig(schedule, GPF_CONFIG_TYPE_BUFFER, NULL, line);
	gpfFree(line);
	job = job->next;
	gpfShowJobs(job);
	CU_ASSERT(job != NULL && strcmp(job->cmd,   "netstat -s") == 0);
	CU_ASSERT(job != NULL && strcmp(job->ofile, "netstats.txt") == 0);
	printf("OFILE[%s]\n", job->ofile);
	CU_ASSERT(job->cycle == 20);
	CU_ASSERT(job->step == 11);
	CU_ASSERT(result == 1);

	/* 標準パターン 「項目.種別 = 'コマンド',出力ファイル,実行間隔」 */
	line = strdup("STAT_CMD.HW = 'netstat -s',netstats.txt,30");
	result = gpfLoadConfig(schedule, GPF_CONFIG_TYPE_BUFFER, NULL, line);
	gpfFree(line);
	job = job->next;
	gpfShowJobs(job);
	CU_ASSERT(job != NULL && strcmp(job->cmd,   "netstat -s") == 0);
	CU_ASSERT(job != NULL && strcmp(job->ofile, "netstats.txt") == 0);
	CU_ASSERT(job->cycle == 30);
	CU_ASSERT(job->step == 0);
	CU_ASSERT(result == 1);

	/* 標準パターン 「項目.種別 = 'コマンド',出力ファイル,実行間隔,回数(間に空白文字あり」 */
	line = strdup("STAT_CMD.HW = 'netstat -s'\t ,\tnetstats.txt\t ,\t31\t ");
	result = gpfLoadConfig(schedule, GPF_CONFIG_TYPE_BUFFER, NULL, line);
	gpfFree(line);
	job = job->next;
	gpfShowJobs(job);
	CU_ASSERT(job != NULL && strcmp(job->cmd,   "netstat -s") == 0);
	CU_ASSERT(job != NULL && strcmp(job->ofile, "netstats.txt") == 0);
	CU_ASSERT(job->cycle == 31);
	CU_ASSERT(job->step == 0);
	CU_ASSERT(result == 1);

	/* 標準パターン 「項目.種別 = 'コマンド',出力ファイル」(間に空白文字あり) */
	line = strdup("STAT_CMD.HW = 'vmstat 3 3'\t ,\tvmstat.txt");
	result = gpfLoadConfig(schedule, GPF_CONFIG_TYPE_BUFFER, NULL, line);
	gpfFree(line);
	job = job->next;
	gpfShowJobs(job);
	CU_ASSERT(job != NULL && strcmp(job->cmd,   "vmstat 3 3") == 0);
	CU_ASSERT(job != NULL && strcmp(job->ofile, "vmstat.txt") == 0);
	CU_ASSERT(result == 1);

	/* 標準パターン 「項目.種別 = 'コマンド',出力ファイル」(間に空白文字あり) */
	line = strdup("STAT_CMD.HW = \"iostat -xn 3 3\" \t ,\t  iostat.txt   ");
	result = gpfLoadConfig(schedule, GPF_CONFIG_TYPE_BUFFER, NULL, line);
	gpfFree(line);
	job = job->next;
	gpfShowJobs(job);
	CU_ASSERT(job != NULL && strcmp(job->cmd,   "iostat -xn 3 3") == 0);
	CU_ASSERT(job != NULL && strcmp(job->ofile, "iostat.txt") == 0);
	CU_ASSERT(result == 1);

	/* エラーパターン 「項目.種別 = 'コマンド',」ファイル名なし */
	line = strdup("STAT_CMD.HW = 'vmstat 3 3',");
	result = gpfLoadConfig(schedule, GPF_CONFIG_TYPE_BUFFER, NULL, line);
printf("RES=%d\n", result);
	gpfFree(line);
	CU_ASSERT(result == 0);

	/* エラーパターン 「項目.種別 = 'コマンド',出力ファイル,」実行周期空白 */
	line = strdup("STAT_CMD.HW = 'netstat -s'\t ,\tnetstats.txt\t ,\t\t ,\t\t ");
	result = gpfLoadConfig(schedule, GPF_CONFIG_TYPE_BUFFER, NULL, line);
	gpfFree(line);
	CU_ASSERT(result == 0);

	/* エラーパターン 「項目.種別 = 'コマンド',出力ファイル」(出力ファイルがパス指定) */
#if defined _WINDOWS
	line = strdup("STAT_CMD.HW = 'vmstat 3 3',c:\\test.txt");
#else
	line = strdup("STAT_CMD.HW = 'vmstat 3 3',/etc/test.txt");
#endif
	result = gpfLoadConfig(schedule, GPF_CONFIG_TYPE_BUFFER, NULL, line);
	job = job->next;
	gpfShowJobs(job);
	gpfFree(line);
	CU_ASSERT(result == 0);

	gpfFreeSchedule(&schedule);
}

void test_gpf_param_007(void)
{
	char cwd[MAXFILENAME];
	char *paramPath  = NULL;
	int result;
	GPFSchedule *schedule;

	schedule = gpfCreateSchedule();

	getcwd(cwd, sizeof(cwd));
	paramPath = gpfCatFile(cwd, "cfg", "error01", "getperf.ini", NULL);
	printf("%s\n", paramPath);
	result = gpfLoadConfig(schedule, GPF_CONFIG_TYPE_FILE, paramPath, NULL);
	CU_ASSERT(result == 0);
	gpfFree(paramPath);
	gpfFreeSchedule(&schedule);

	schedule = gpfCreateSchedule();
	paramPath = gpfCatFile(cwd, "cfg", "error01", "error02.ini", NULL);
	printf("%s\n", paramPath);
	result = gpfLoadConfig(schedule, GPF_CONFIG_TYPE_FILE, paramPath, NULL);
	CU_ASSERT(result == 0);
	gpfFree(paramPath);
	gpfFreeSchedule(&schedule);

	schedule = gpfCreateSchedule();
	paramPath = gpfCatFile(cwd, "cfg", "error01", "ok03.ini", NULL);
	printf("%s\n", paramPath);
	result = gpfLoadConfig(schedule, GPF_CONFIG_TYPE_FILE, paramPath, NULL);
	CU_ASSERT(result == 1);
	gpfFree(paramPath);
	gpfFreeSchedule(&schedule);

	schedule = gpfCreateSchedule();
	paramPath = gpfCatFile(cwd, "cfg", "error01", "ng04.ini", NULL);
	printf("%s\n", paramPath);
	result = gpfLoadConfig(schedule, GPF_CONFIG_TYPE_FILE, paramPath, NULL);
	CU_ASSERT(result == 0);
	gpfFree(paramPath);
	gpfFreeSchedule(&schedule);

	schedule = gpfCreateSchedule();
	paramPath = gpfCatFile(cwd, "cfg", "error01", "ng05.ini", NULL);
	printf("%s\n", paramPath);
	result = gpfLoadConfig(schedule, GPF_CONFIG_TYPE_FILE, paramPath, NULL);
	CU_ASSERT(result == 0);
	gpfFree(paramPath);
	gpfFreeSchedule(&schedule);
}

void test_gpf_param_008(void)
{
	char *line = NULL, *line2 = NULL;
	int result;
	GPFSchedule *schedule = NULL;
	GPFJob      *job = NULL;


	/* http_proxy設定 1 */
	line = strdup("STAT_ENABLE.HW = true");
	schedule = gpfCreateSchedule();
	line2 = strdup("http_proxy=http://hogehoge2.com");
	putenv(line2);

	result = gpfLoadConfig(schedule, GPF_CONFIG_TYPE_BUFFER, NULL, line);
	CU_ASSERT(result == 1);
	gpfFree(line2);
/*	printf ("proxy=%s\n", schedule->proxyHost );  
	printf ("port=%d\n",  schedule->proxyPort );  
*/
	gpfFreeSchedule(&schedule);
	gpfFree(line);
	
	/* http_proxy設定 2 */
	line = strdup("STAT_ENABLE.HW = true");
	schedule = gpfCreateSchedule();
	line2 = strdup("http_proxy=http://hogehoge.com/");
	putenv(line2);

	result = gpfLoadConfig(schedule, GPF_CONFIG_TYPE_BUFFER, NULL, line);
	CU_ASSERT(result == 1);
	gpfFree(line2);
/*
	printf ("proxy=%s,port=%d\n", schedule->proxyHost, schedule->proxyPort );  
*/
	gpfFreeSchedule(&schedule);
	gpfFree(line);

	/* http_proxy設定 3 */
	line = strdup("STAT_ENABLE.HW = true");
	schedule = gpfCreateSchedule();
	line2 = strdup("http_proxy=http://hogehoge.com:1234/");
	putenv(line2);

	result = gpfLoadConfig(schedule, GPF_CONFIG_TYPE_BUFFER, NULL, line);
	CU_ASSERT(result == 1);
	gpfFree(line2);
/*
	printf ("proxy=%s,port=%d\n", schedule->proxyHost, schedule->proxyPort );  
*/
	gpfFreeSchedule(&schedule);
	gpfFree(line);
}

void test_gpf_param_009(void)
{
}

void test_gpf_param_010(void)
{
}

void test_gpf_param_011(void)
{
}

void test_gpf_param_012(void)
{
}

void test_gpf_param_013(void)
{
}

void test_gpf_param_014(void)
{
}

void test_gpf_param_015(void)
{
}

void test_gpf_param_016(void)
{
}

void test_gpf_param_017(void)
{
}

void test_gpf_param_018(void)
{
}

void test_gpf_param_019(void)
{
}

void test_gpf_param_020(void)
{
}

