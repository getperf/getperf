#include <CUnit/CUnit.h>
#include <CUnit/Console.h>
#include <CUnit/Basic.h>

#include "gpf_config.h"
#include "gpf_common.h"
#include "gpf_log.h"
#include "gpf_agent.h"
#include "ght_hash_table.h"

#include "unit_test.h"
#include "cunit_test.h"

GPFConfig *gpfTestConfig(char *sslDir, int testType);
GPFSetupConfig *gpfTestSetup(int testType);

/**
 * gpfCheckExitFile()動作確認
 * {home}/test/cfg/_wk の下の _exitFlag ファイルを確認する
 * gpfCheckHostname()動作確認
 */
 
void test_gpf_agent_001(void)
{
	int result;
	GPFConfig *config     = NULL;
	GPFSchedule *schedule = NULL;
	char *configFile      = NULL;
	char cwd[MAXFILENAME];
	char *badName = NULL;
	char *buf;

	getcwd(cwd, sizeof(cwd));
	configFile = gpfCatFile(cwd, "cfg", "getperf.ini", NULL);
	result = gpfInitAgent( &config, "gpf_test", configFile, GPF_PROCESS_RUN );

	CU_ASSERT(result == 1);

	/* {home}/test/cfg/_wk/_exitFlag のファイルの有無を確認 */
	printf("exit_file:%s\n", config->exitFlag);
	unlink( config->exitFlag );
	buf = gpfCheckExitFile( config );
	CU_ASSERT(buf == NULL);

	/* _exitFlag ファイルを更新 */
	result = gpfWriteWorkFile( config, "_exitFlag", "STOP" );

	buf = gpfCheckExitFile( config );
	CU_ASSERT(buf != NULL);
	printf("buf=%s\n", buf);
	gpfFree( buf );
	
	unlink( config->exitFlag );
	buf = gpfCheckExitFile( config );
	CU_ASSERT(buf == NULL);

	/* ホスト名のチェック(正常系) */
	result = gpfCheckHostname( "hoge01" );
	CU_ASSERT(result == 1);

	/* 先頭文字が英数字でない場合はエラー */
	result = gpfCheckHostname( "$hoge01" );
	CU_ASSERT(result == 0);

	/* 途中に'/'が含まれる場合もエラー */
	badName = gpfCatFile( "aaa", "bbb", NULL );
	result = gpfCheckHostname( badName );
	CU_ASSERT(result == 0);

	gpfFree(configFile);
	gpfRemoveWorkDir( config );
	gpfFreeConfig(&config);
}

/**
 * gpfCheckHAStatus() の動作確認
 */
void test_gpf_agent_002(void)
{
	int result;
	GPFConfig *config     = NULL;
	GPFSchedule *schedule = NULL;
	char *configFile      = NULL;
	char cwd[MAXFILENAME];
	char *buf;

#if defined(_WINDOWS)

	getcwd(cwd, sizeof(cwd));
	
	/* {home}/cfg/getperf.ini でエージェント初期化 */
	configFile = gpfCatFile(cwd, "cfg", "getperf.ini", NULL);
	result = gpfInitAgent( &config, "gpf_test", configFile, GPF_PROCESS_RUN );

	config->schedule->hanodeEnable = 1;
	gpfFree(config->schedule->hanodeCmd);

	/* {home}/cfg/scriptの下のhastat.bat実行 */
	config->schedule->hanodeCmd = strdup("hastat.bat");

	result = gpfCheckHAStatus( config );

	CU_ASSERT(result == 1);

	gpfFree(config->schedule->hanodeCmd);
	config->schedule->hanodeCmd = strdup("hoge.bat");

	result = gpfCheckHAStatus( config );

	CU_ASSERT(result == 0);

	gpfFree(config->schedule->hanodeCmd);
	config->schedule->hanodeCmd = strdup("hastat_error.bat");

	result = gpfCheckHAStatus( config );

	CU_ASSERT(result == 0);

	gpfFree(config->schedule->hanodeCmd);
	config->schedule->hanodeCmd = strdup("hastat_error2.bat");

	result = gpfCheckHAStatus( config );

	CU_ASSERT(result == 0);

#else

	/* {home}/cfg/getperf.ini でエージェント初期化 */
	getcwd(cwd, sizeof(cwd));
	configFile = gpfCatFile(cwd, "cfg", "getperf.ini", NULL);
	result = gpfInitAgent( &config, "gpf_test", configFile, GPF_PROCESS_RUN );
	/* 正常動作 */
	/* {home}/cfg/scriptの下のhastat.sh実行 */
	config->schedule->hanodeEnable = 1;
	gpfFree(config->schedule->hanodeCmd);
	config->schedule->hanodeCmd = strdup("hastat.sh");

	result = gpfCheckHAStatus( config );
	CU_ASSERT(result == 1);
	CU_ASSERT(strcmp(config->serviceName, "hoge") == 0);

	/* スクリプトパスなしエラー。サービス名はホスト名を代入 */
	gpfFree(config->schedule->hanodeCmd);
	config->schedule->hanodeCmd = strdup( "hoge.sh" );
	result = gpfCheckHAStatus( config );
	CU_ASSERT(strcmp(config->serviceName, config->host ) == 0);

	printf( "serviceName=%s\n", config->serviceName );
	
	CU_ASSERT(result == 0);

	/* {home}/cfg/scriptの下のhastat_error.sh実行 */
	/* スクリプトの出力結果が _wrongname となりホスト名のチェックでエラーとなる */
	gpfFree(config->schedule->hanodeCmd);
	config->schedule->hanodeCmd = strdup("hastat_error.sh");

	result = gpfCheckHAStatus( config );

	CU_ASSERT(result == 0);

	/* {home}/cfg/scriptの下のhastat_error2.sh実行 */
	/* スクリプトの終了コードが正常終了0ではないためエラーとなる */
	gpfFree(config->schedule->hanodeCmd);
	config->schedule->hanodeCmd = strdup("hastat_error2.sh");

	/* {home}/cfg/scriptの下のhastat_error3.sh実行 */
	/* タイムアウトエラーとなる */
	gpfFree(config->schedule->hanodeCmd);
	config->schedule->hanodeCmd = strdup("hastat_error3.sh");
	result = gpfCheckHAStatus( config );
	CU_ASSERT(result == 0);

#endif

	gpfFree(configFile);
	gpfRemoveWorkDir( config );
	gpfFreeConfig(&config);
}

/**
 * gpfAuthLicense() の動作確認
 */

void test_gpf_agent_003(void)
{
	int result;
	GPFConfig *config       = NULL;
	GPFSchedule *schedule   = NULL;
	GPFSSLConfig *sslConfig = NULL;
	char *configFile        = NULL;
	char cwd[MAXFILENAME];
	char *buf;

	getcwd(cwd, sizeof(cwd));

	configFile = gpfCatFile(cwd, "cfg", "getperf.ini", NULL);

	/* 正常動作 {home}/test/cfg/network/License.txt を読み込みホスト名チェック */
	/* hostname=moi */
	/* expired=20121231 */
	/* siteKey=IZA5971 */

	result = gpfInitAgent( &config, "gpf_test", configFile, GPF_PROCESS_RUN );
	CU_ASSERT(result == 1);

	gpfFree(config->host);
	config->host = strdup( "moi" );
	printf("hostname=%s\nexpired=%s\nsiteKey=%s\n",
		config->sslConfig->hostname, config->sslConfig->expired, config->schedule->siteKey);
	printf("host=%s\n",config->host);

	result = gpfAuthLicense( config, 30*24*3600 );
	CU_ASSERT(result == 1);

	/* ホスト名不一致エラー */
	gpfFree(config->host);
	config->host = strdup( "win7" );
	result = gpfAuthLicense( config, 30*24*3600 );
	CU_ASSERT(result == 0);
	gpfFreeConfig(&config);
	
	/* 有効期限エラー(2011/12/28)
	HOSTNAME=moi
	EXPIRE=20111228
	CODE=80255bf09d797b4566061da35b96e5b3
	*/
	result = gpfInitAgent( &config, "gpf_test", configFile, GPF_PROCESS_RUN );
	gpfFree(config->host);
	config->host       = strdup( "moi" );
	config->sslConfig->expired = strdup( "20111228" );
	config->sslConfig->code    = strdup( "80255bf09d797b4566061da35b96e5b3" );
	result = gpfAuthLicense( config, 30*24*3600 );
	CU_ASSERT(result == 0);

	gpfFree(configFile);
	gpfRemoveWorkDir( config );
	gpfFreeConfig(&config);
}

/**
 * gpfUnzipSSLConf() 動作確認テスト
 * 事前に https://getperf.cm:57443/axis2/services/GetperfCMService にアクセスできる事
 */
void test_gpf_agent_004(void)
{
	int result;
	GPFConfig *config     = NULL;
	char *configFile      = NULL;
	char cwd[MAXFILENAME];
	char *zipPath;

	getcwd(cwd, sizeof(cwd));

#if defined(_WINDOWS)
	configFile = gpfCatFile(cwd, "win", "getperf.ini", NULL);
#else
	configFile = gpfCatFile(cwd, "cfg", "getperf.ini", NULL);
#endif

	result = gpfInitAgent( &config, "gpf_test", configFile, GPF_PROCESS_RUN );
	CU_ASSERT(result == 1);
	printf("home=%s\n", config->home);
	gpfFree( config->host );
	config->host = strdup( "ostrich" );

	/* zipファイルなしエラー */
	zipPath = gpfCatFile( config->workCommonDir, "sslconf.zip", NULL );
	unlink( zipPath );

	result = gpfUnzipSSLConf( config );
	CU_ASSERT(result == 0);

	/* 正常動作 zipファイルのダウンロード、解凍、ライセンスチェック */
	result = gpfDownloadCertificate( config, 0 ) ;
	CU_ASSERT(result == 1);

	result = gpfUnzipSSLConf( config );
	CU_ASSERT(result == 1);

	result = gpfCheckLicense( config, 30*24*3600 );
	CU_ASSERT(result == 1);

	gpfFree(zipPath);
	gpfFree(configFile);
	gpfRemoveWorkDir( config );
	gpfFreeConfig( &config );
}
/**
 * gpfCheckTimer() 動作確認テスト
 * {home}/test/cfg/conf 下のHW.ini,JVM.ini カテゴリ設定を読み込みタイマーを設定
 */
void test_gpf_agent_005(void)
{
	int result;
	time_t currTime;
	GPFConfig *config     = NULL;
	char *configFile      = NULL;
	char cwd[MAXFILENAME];

	getcwd(cwd, sizeof(cwd));

#if defined(_WINDOWS)
	configFile = gpfCatFile(cwd, "win", "getperf.ini", NULL);
#else
	configFile = gpfCatFile(cwd, "cfg", "getperf.ini", NULL);
#endif

	result = gpfInitAgent( &config, "gpf_test", configFile, GPF_PROCESS_RUN );
	CU_ASSERT(result == 1);
	printf("home=%s\n", config->home);

	currTime = time(NULL);
	result = gpfCheckTimer( config, currTime );
	CU_ASSERT(result == 2);

	gpfShowSchedule( config->schedule );
	gpfFree(configFile);
	gpfRemoveWorkDir( config );
	gpfFreeConfig( &config );
}

/**
 * gpfPrepareCollector() 動作確認テスト
 * ホスト名moiでコレクター実行の事前チェックを行う。
 */
void test_gpf_agent_006(void)
{
	int result;
	int diskCapacityTemp;
	time_t currTime;
	GPFConfig *config     = NULL;
	char *configFile      = NULL;
	char *host,*hostTemp;
	char cwd[MAXFILENAME];

	getcwd(cwd, sizeof(cwd));
	configFile = gpfCatFile(cwd, "cfg", "getperf.ini", NULL);

	result = gpfInitAgent( &config, "gpf_test", configFile, GPF_PROCESS_RUN );
	CU_ASSERT(result == 1);
	config->logConfig->logLevel=8;

	/* 正常動作 */
//	gpfFree(config->host);
//	config->host = strdup("moi");
	printf("home=%s,host=%s\n", config->home, config->host);
	result = gpfPrepareCollector( config );
	CU_ASSERT(result == 1);

	/* ディスク空き使用量チェックエラーエラー(閾値を100%未満に設定) */
	diskCapacityTemp = config->schedule->diskCapacity;
	config->schedule->diskCapacity = 100;
	result = gpfPrepareCollector( config );
	CU_ASSERT(result == 0);

	/* ホスト名不一致の場合のライセンスチェックエラー */
	config->schedule->diskCapacity = diskCapacityTemp;
	gpfFree(config->host);
	config->host = strdup("hoge");
	result = gpfPrepareCollector( config );
	CU_ASSERT(result == 0);

	gpfFree(configFile);
	gpfRemoveWorkDir( config );
	gpfFreeConfig( &config );
}

/**
 * GNU Hashテーブルのプロトタイプ
 * http://www.bth.se/people/ska/sim_home/libghthash.html
 */
void test_gpf_agent_007(void)
{
	int rc = 0;
	int i, hsize, hnum;
	ght_hash_table_t *p_table = NULL;
	int *val = NULL;
	int *p_he = NULL;
	int key[1];
	int *pk, *pv;
	ght_iterator_t iterator;

	p_table = ght_create(128);
	CU_ASSERT(p_table != NULL);

	/* Insert 123 into the hash table */
	val = malloc( sizeof(int) );
	*val = 15;
	key[0] = 123;
	rc = ght_insert(p_table, val, sizeof(int), key);
	CU_ASSERT( rc == 0 );

	val = malloc( sizeof(int) );
	*val = 111;
	key[0] = 111;
	rc = ght_insert(p_table, val, sizeof(int), key);
	CU_ASSERT( rc == 0 );

	val = malloc( sizeof(int) );
	*val = 321;
	key[0] = 112;
	rc = ght_insert(p_table, val, sizeof(int), key);
	CU_ASSERT( rc == 0 );

	hnum  = ght_size( p_table );
	hsize = ght_table_size( p_table );
	printf( "num=%d, size=%d\n", hnum, hsize );

	/* 重複登録した場合は戻り値が0以外となる */
	for (i = hnum; i < hsize ; i++)
	{
		key[0] = i;
		rc = ght_insert(p_table, val, sizeof(int), key);

		if (i == 123 || i == 111 || i == 112)
		{
			CU_ASSERT( rc != 0 );
		}
		else
		{
			CU_ASSERT( rc == 0 );
		}
	}

	/* サイズ以上の登録をした場合は0意外となる */
	rc = ght_insert(p_table, val, sizeof(int), key);
	CU_ASSERT( rc != 0 );

	i = 0;
	for ( pv = (char *) ght_first(p_table, &iterator, &pk);
	      pv;
	      pv = (char *) ght_next(p_table, &iterator, &pk), i++ )
	{
	    printf("[%d] %d => %d\n",i, *pk, *pv);
	}

	/* キーの検索。指定したキーが存在しない場合はNULLが返る */
	key[0] = 123;
	p_he = ght_get(p_table, sizeof(int), key);
	printf("val[%d]=%d\n", key[0], *p_he);
	CU_ASSERT(*p_he == 15);
	gpfFree( p_he );

	key[0] = 112;
	p_he = ght_get(p_table, sizeof(int), key);
	printf("val[%d]=%d\n", key[0], *p_he);
	CU_ASSERT(*p_he == 321);
	gpfFree( p_he );

	key[0] = 111;
	p_he = ght_get(p_table, sizeof(int), key);
	printf("val[%d]=%d\n", key[0], *p_he);
	CU_ASSERT(*p_he == 111);
	gpfFree( p_he );

	key[0] = 999;
	p_he = ght_get(p_table, sizeof(int), key);
	CU_ASSERT(p_he == NULL);

	/* ハッシュ表の削除 */
	ght_finalize(p_table);
}

/**
 * gpfExecSOAPCommandPM() 動作確認テスト
 * ホスト名moiでsslconf.zip をダウンロード、アップロードする。
 */
void test_gpf_agent_008(void)
{
	int result;
	GPFConfig *config     = NULL;
	char *configFile      = NULL;
	char cwd[MAXFILENAME];
	char *upload_zip      = "arc_ostrich__HW_20150223_000000.zip";
	char *zipDownloadPath = NULL;
	char *zipUploadPath   = NULL;

	getcwd(cwd, sizeof(cwd));

	configFile = gpfCatFile(cwd, "cfg", "getperf.ini", NULL);

	result = gpfInitAgent( &config, "gpf_test", configFile, GPF_PROCESS_RUN );
	CU_ASSERT(result == 1);
	gpfFree(config->host);
	config->host = strdup("moi");
	printf("home=%s,host=%s\n", config->home, config->host);

	zipDownloadPath = gpfCatFile( config->workCommonDir, "sslconf.zip", NULL );
	zipUploadPath   = gpfCatFile( config->archiveDir,    upload_zip, NULL );
	unlink( zipDownloadPath );
	unlink( zipUploadPath );

	/* --getの場合、{home}/_wk の下にダウンロード */
	result = gpfExecSOAPCommandPM( config, "--get", "sslconf.zip" ) ;
	CU_ASSERT(result == 1);

	/* --putの場合、{home}/_bk の下にアップロード。ファイルなしエラー */
	result = gpfExecSOAPCommandPM( config, "--send", upload_zip ) ;
	CU_ASSERT(result == 0);

	/* コピーして再アップロード */
	gpfCopyFile( zipDownloadPath, zipUploadPath );
	result = gpfExecSOAPCommandPM( config, "--send", upload_zip ) ;
	CU_ASSERT(result == 1);
	
	gpfFree(zipDownloadPath);
	gpfFree(zipUploadPath);
	gpfFree(configFile);
	gpfRemoveWorkDir( config );
	gpfFreeConfig( &config );
}

/**
 * gpfPurgeData() 動作確認テスト
 *  {home}/test/cfg/log/{日付}/{時刻} の下の採取データ保存用ディレクトリの削除
 */
void test_gpf_agent_009(void)
{
	int result;
	GPFConfig *config       = NULL;
	GPFSchedule *schedule   = NULL;
	GPFCollector *collector = NULL;
	GPFTask *task           = NULL;
	char *configFile        = NULL;
	char cwd[MAXFILENAME];
	char *script = NULL;
	char *cmd = NULL;
	char *buf = NULL;
	time_t currTime = 0;

	getcwd(cwd, sizeof(cwd));

	configFile = gpfCatFile(cwd, "cfg", "getperf.ini", NULL);

	result = gpfInitAgent( &config, "gpf_test", configFile, GPF_PROCESS_RUN );
	CU_ASSERT(result == 1);

	schedule  = config->schedule;
	collector = gpfFindCollector( schedule, "HW" );
	currTime  = time( NULL );

	gpfCheckTimer( config, currTime );
	gpfShowCollector( collector );
	task = gpfCreateTask( config, collector );
	task->startTime = time( NULL );
	script = gpfCatFile(cwd, "makeTestLog.pl", NULL);
	printf("RUN %s\n", script);

	/* デフォルト設定 
	 *   過去48時間分のデータディレクトリを作成して、デフォルト設定の24H前までの
	 *   データを削除する。戻り値は1を返す。
	 */
	cmd = gpfDsprintf( cmd, "perl %s", script );
	gpfNotice("[Exec][limit=%d] %s", schedule->saveHour, cmd );
	result = system( cmd );
	gpfFree( cmd );
	CU_ASSERT(result == 0);

	result = gpfPurgeData( task );
	CU_ASSERT(result == 1);

	/* なにもしない 
	 *   過去24時間分のデータディレクトリを作成して、49H前までのデータを削除する。
     *   戻り値は1を返す。
     */
	cmd = gpfDsprintf( cmd, "perl %s -ckdir=24", script );
	gpfNotice("[Exec] %s", cmd);
	result = system( cmd );
	gpfFree( cmd );
	CU_ASSERT(result == 0);

	cmd = gpfDsprintf( cmd, "perl %s", script );
	gpfNotice("[Exec] %s", cmd);
	result = system( cmd );
	gpfFree( cmd );
	CU_ASSERT(result == 0);

	schedule->saveHour = 49;
	result = gpfPurgeData( task );
	CU_ASSERT(result == 1);

	cmd = gpfDsprintf( cmd, "perl %s -ckdir=48", script );
	gpfNotice("[Exec] %s", cmd);
	result = system( cmd );
	gpfFree( cmd );
	CU_ASSERT(result == 0);

	/* 3H保存 
	 *   過去24時間分のデータディレクトリを作成して、3H前までのデータを削除する。
     *   戻り値は1を返す。
     */
	cmd = gpfDsprintf( cmd, "perl %s", script );
	gpfNotice("[Exec] %s", cmd);
	result = system( cmd );
	gpfFree( cmd );
	CU_ASSERT(result == 0);

	schedule->saveHour = 3;
	result = gpfPurgeData( task );
	CU_ASSERT(result == 1);

	cmd = gpfDsprintf( cmd, "perl %s -ckdir=3", script );
	gpfNotice("[Exec] %s", cmd);
	result = system( cmd );
	gpfFree( cmd );
	CU_ASSERT(result == 0);

	gpfFreeTask( &task );
	gpfFree( script );
	gpfFree( configFile );
	gpfFree( cmd );
}

void test_gpf_agent_010(void)
{
	int interval = 300;
	double curr = gpfTime();
	time_t currTime = interval * (time_t)(curr/interval);
//	currTime *= interval;
	char dateDir[100];
	char timeDir[100];

	gpfGetTimeString( currTime, dateDir, GPF_DATE_FORMAT_YYYYMMDD );
	gpfGetTimeString( currTime, timeDir, GPF_DATE_FORMAT_HHMISS );

	printf("%s/%s", dateDir, timeDir);
}

void test_gpf_agent_011(void)
{
#if defined(_WINDOWS)
	char odir[]   = "c:\\";
	char target[] = "\\hoge\\aaa\\test.txt";
#else
	char odir[]   = "/tmp";
	char target[] = "/hoge/aaa/test.txt";
#endif

	int pos;
	char *outDir;
	char *postfix = strdup(target);
	for (pos = strlen(postfix) - 1; pos > 0; pos --) {
		if ( *(postfix + pos) == '/' || *(postfix + pos) == '\\' ) {
			*(postfix + pos) = '\0';
			outDir = gpfCatFile( odir, postfix, NULL );
			gpfMakeDirectory( outDir );
			break;
		}
	}
	gpfFree( postfix );
	gpfFree( outDir );	

}

void test_gpf_agent_012(void)
{
}

void test_gpf_agent_013(void)
{
}

void test_gpf_agent_014(void)
{
}

void test_gpf_agent_015(void)
{
}

void test_gpf_agent_016(void)
{
}

void test_gpf_agent_017(void)
{
}

void test_gpf_agent_018(void)
{
}

void test_gpf_agent_019(void)
{
}

void test_gpf_agent_020(void)
{
}

