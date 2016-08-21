#include <CUnit/CUnit.h>
#include <CUnit/Console.h>
#include <CUnit/Basic.h>

#include "gpf_config.h"
#include "gpf_common.h"
#include "gpf_log.h"
#include "test_config.h"
#include "unit_test.h"
#include "cunit_test.h"

GPFConfig *gpfTestConfig(char *sslDir, int testType);
GPFSetupConfig *gpfTestSetup(int testType);

/**
 * gpfSetUserInfo()動作確認
 */
void test_gpf_admin_001(void)
{
	int result = 0;
	GPFSetupOption *options = NULL;
	
	/* 手動でユーザ情報を入力する場合はコメントアウトを外す */
/*	
	options = gpfCreateSetupOption();
	result  = gpfSetUserInfo( options );
	
	gpfShowSetupOption( options );
	CU_ASSERT(result == 1);
*/
	options = gpfCreateSetupOption();
	options->userName = strdup("username");
	options->password = strdup("password");
	options->siteKey  = strdup("sitekey");
	result  = gpfSetUserInfo( options );
	
	gpfShowSetupOption( options );
	CU_ASSERT(result == 1);
}

/**
 * gpfInitAgent()動作確認
 *   構成ファイル、実行パス、モードの指定により動作が変わる
 */
void test_gpf_admin_002(void)
{
	int result;
	GPFConfig *config     = NULL;
	char *configFile      = NULL;
	char cwd[MAXFILENAME];
	char *zipPath;
	char *exePath, *exePath2;

	getcwd(cwd, sizeof(cwd));

	configFile = gpfCatFile(cwd, "cfg", "getperf.ini", NULL);
	exePath    = gpfCatFile(cwd, "cfg", "bin", "gpf_test", NULL);
	exePath2   = gpfCatFile(".", "cfg", "bin", "gpf_test", NULL);

	/* 正常動作 */
	result = gpfInitAgent( &config, "gpf_test", configFile, GPF_PROCESS_RUN );
	CU_ASSERT(result == 1);
	printf("home=%s\n", config->home);
	gpfFreeConfig( &config );
	
	/* 正常動作(構成ファイルの指定はせずに実行パス指定) */
	result = gpfInitAgent( &config, exePath, NULL, GPF_PROCESS_RUN );
	CU_ASSERT(result == 1);
	printf("home=%s\n", config->home);
	gpfFreeConfig( &config );

	/* 正常動作(相対実行パス指定) */
	result = gpfInitAgent( &config, exePath2, NULL, GPF_PROCESS_RUN );
	CU_ASSERT(result == 1);
	printf("home=%s\n", config->home);
	gpfFreeConfig( &config );

	/* 正常動作(排他ロック用セマフォの初期化しない) */
	result = gpfInitAgent( &config, exePath, NULL, GPF_PROCESS_INIT );
	CU_ASSERT(result == 1);
	printf("home=%s\n", config->home);
	gpfFreeConfig( &config );

	/* 構成ファイルなしエラー */
	result = gpfInitAgent( &config, "gpf_test", "hoge.ini", GPF_PROCESS_INIT );
	CU_ASSERT(result == 0);
	printf("home=%s\n", config->home);
	gpfFreeConfig( &config );

	/* 実行パスなしエラー */
	result = gpfInitAgent( &config, "./gpf_test", NULL, GPF_PROCESS_INIT );
	CU_ASSERT(result == 0);
	printf("home=%s\n", config->home);

	gpfFree( configFile );
	gpfFree( exePath );	
	gpfFreeConfig( &config );
}

/**
 * gpsetCheckSiteLicense()動作確認
 */
void test_gpf_admin_003(void)
{
}

void test_gpf_admin_004(void)
{
	int result;
	GPFConfig      *config = NULL;
	GPFSetupConfig *setup  = NULL;
	// config = gpfTestConfig("ssl", 0);
	// GCON = config;
	// setup  = gpfTestSetup(0);
	
	// result = gpfCheckDomain( config, setup );
	// CU_ASSERT(result == 1);

	// result = gpfInputDomain( config, setup );
	// CU_ASSERT(result == 1);
	
	// gpfShowSetupConfig( setup );
	// gpfFreeConfig(&config);
	// gpfFreeSetupConfig(&setup);
}

void test_gpf_admin_005(void)
{
	int result;
	GPFConfig      *config = NULL;
	GPFSetupConfig *setup  = NULL;
	config = gpfTestConfig( "ssl", 0 );
	GCON = config;
	setup  = gpfTestSetup( 0 );
	
	result = gpfRunCheckCoreUpdate( config );
	CU_ASSERT( result == 1 );
	
	// result = gpfRunCheckStatUpdate( config, setup );
	// CU_ASSERT( result == 1 );
	
	gpfFreeConfig( &config );
	gpfFreeSetupConfig( &setup );
}

void test_gpf_admin_006(void)
{
	int result;
	GPFConfig      *config = NULL;
	GPFSetupConfig *setup  = NULL;
	config = gpfTestConfig( "ssl", 0 );
	GCON = config;
	setup  = gpfTestSetup( 0 );
	
	result = gpfEntryHost( config, setup );
	CU_ASSERT( result == 1 );
	
	gpfFreeConfig( &config );
	gpfFreeSetupConfig( &setup );
}

void test_gpf_admin_007(void)
{
}

void test_gpf_admin_008(void)
{
}

void test_gpf_admin_009(void)
{
}

void test_gpf_admin_010(void)
{
}

void test_gpf_admin_011(void)
{
	int result;
	GPFConfig *config     = NULL;
	GPFSetupConfig *setup = NULL;
	char *configFile      = NULL;
	char cwd[MAXFILENAME];
	char *zipPath;

	getcwd(cwd, sizeof(cwd));
	configFile = gpfCatFile(cwd, "home", "getperf.ini", NULL);

#if defined _WINDOWS
	setup  = gpfTestSetup(1);
#else
	setup  = gpfTestSetup(0);
#endif

	result = gpfInitAgent( &config, "gpf_test", configFile, GPF_PROCESS_RUN );
	/* SSL 未初期化のためライセンスエラーとなる */
	CU_ASSERT(result == 0);
	printf("home=%s\n", config->home);

	gpfShowConfig( config );

	result = gpfEntryHost( config, setup );
	CU_ASSERT(result == 1);

	result = gpfDeployConfigFile( config, NULL, setup->configZip );
	CU_ASSERT(result == 1);

	gpfFreeConfig(&config);
	gpfFreeSetupConfig(&setup);
}

void test_gpf_admin_012(void)
{

	int rc                = 0;
	GPFConfig *config     = NULL;
	GPFSetupConfig *setup = NULL;
	GPFSetupOption *options = NULL;
	GPFSchedule *schedule = NULL;
	char    *program      = NULL;
	char    *configPath   = NULL;
	int     mode          = 0;
	int timeout           = 0;
	int auth_rc           = 0;
	int continueFlag      = 0;
	int host_rc           = 0;
	pid_t exitPid         = 0;
	char *configFile      = NULL;
	char dateStr[MAX_STRING_LEN];
	struct stat sb;
	char cwd[MAXFILENAME];
	char *badName = NULL;
	char *buf;

	getcwd(cwd, sizeof(cwd));
	configFile = gpfCatFile(cwd, "home", "getperf.ini", NULL);

	options = gpfCreateSetupOption();
	options->program    = strdup("gpf_test");
	options->configPath = strdup(configFile);
	options->userName   = strdup("");
//	options->password   = strdup(ACCESS_KEY);
//	options->siteKey    = strdup(SITE_KEY);
//	gpfSetUserInfo( options );

	program      = options->program;
	configPath   = options->configPath;
	mode         = options->mode;

#if defined _WINDOWS
	setup  = gpfTestSetup(1);
#else
	setup  = gpfTestSetup(0);
#endif
	
	/* エージェント構造体の初期化 */
	if ( (rc = gpfInitAgent( &config, program, configPath, mode )) == 0)
	{
		gpfMessage( GPF_MSG002E, GPF_MSG002 );
		exit (-1);
	}

	/* PROXY_ENABLE がtrueで、PROXY_HOST が空白(NULL)の場合は環境変数にプロキシーを適用する。 */
	/* falseの場合は有効にしない。環境変数に設定されたproxyも有効にしない。 */
	schedule = config->schedule;
	if (schedule->proxyEnable == 1 && strcmp(schedule->proxyHost, "") == 0) {
		gpfCheckHttpProxyEnv( &(config->schedule) );
	}

	/* ログの初期化 */
	GCON = config;

	if ( ( rc = gpfOpenLog( config, config->programName ) ) == 0 )
		exit (-1);

	/* エージェントの起動チェック */
	if ( gpfCheckServiceExist( config, config->pidFile, &exitPid ) ) 
	{
		/* "既存のエージェントPID=%dを検出しました" */
		gpfMessage( GPF_MSG003E, GPF_MSG003, exitPid );

		/* "%s stop コマンドでエージェントを停止して下さい" */
		gpfMessage( GPF_MSG044E, GPF_MSG044, GPF_GETPERFCTL );

		exit( -1 );
	}
	
	/* コアモジュールの更新チェック */
	// if (! gpfRunCheckCoreUpdate( config ) ) {
	// 	/* 管理用Webサービス接続に失敗しました */
	// 	gpfMessage( GPF_MSG076E, GPF_MSG076, config->schedule->urlCM );
	// 	exit (-1);
	// }

	/* SSLライセンスファイルの読込 */
	if ( gpfLoadSSLLicense( config->sslConfig, config->licenseFile ) == 0)
	{
		/* SSLライセンスファイルの初期化をします */
		gpfMessage( GPF_MSG060E, GPF_MSG060 );
	}
	else 
	{
		gpfFree(options->siteKey);
		gpfFree(options->password);
		options->siteKey  = strdup(config->schedule->siteKey);
		options->password = strdup(config->sslConfig->code);
	}

	/* ユーザ情報の入力 */
	setup = gpfCreateSetupConfig();
	gpfSetUserInfo( options );
	gpfSetSetupConfig( setup, options );
	
	// /* 登録ホストの認証。存在しない場合は新規登録 */
	auth_rc = gpfCheckHostStatus( config, setup );
	CU_ASSERT(auth_rc == 1);

	if ( auth_rc == 0 ) 
	{
		/* ユーザ認証に失敗しました */
		gpfMessage( GPF_MSG045E, GPF_MSG045 );
		exit( -1 );
	} 
	else if ( auth_rc == -1 ) 
	{
		/* ホストの登録情報がありませんでした。新規に登録します */
		gpfMessage( GPF_MSG011E, GPF_MSG011 );
		if ( gpfEntryHost( config, setup ) == 0 ) 
		{
			gpfMessage( GPF_MSG046E, GPF_MSG046 );
			exit( -1 );
		}
	} 
	else if ( auth_rc == 1 ) 
	{
		char *expired = config->sslConfig->expired;
		/* 有効期限のチェック */
		gpfGetCurrentTime( 0, dateStr, GPF_DATE_FORMAT_YYYYMMDD );
		if ( !expired || strcmp( dateStr, expired ) > 0 )
		 {
		 	if ( expired ) {
				/* SSL有効期限が切れています : %s。ホストを再登録します */
				gpfMessage( GPF_MSG047E, GPF_MSG047, expired );
		 	} else {
		 		/* ライセンスファイルがありません。ホストを再登録します */
				gpfMessage( GPF_MSG080E, GPF_MSG080 );
		 	}
			if ( gpfEntryHost( config, setup ) == 0 ) 
			{
				gpfMessage( GPF_MSG046E, GPF_MSG046 );
				exit( -1 );
			}
		}
	}

	// /* 構成ファイルのデプロイ */
	if ( setup->configZip ) {
		if (!gpfDeployConfigFile( config, NULL, setup->configZip )) {
			gpfError( "deploy % failed", setup->configZip );
			exit( -1 );
		}
	}

	gpfWriteWorkFile( config, "_setup_flg", "" );
	gpfRemoveWorkDir( config ) ;
	rc = 1;
}

void test_gpf_admin_013(void)
{
}

void test_gpf_admin_014(void)
{
}

void test_gpf_admin_015(void)
{
}

void test_gpf_admin_016(void)
{
}

void test_gpf_admin_017(void)
{
}

void test_gpf_admin_018(void)
{
}

void test_gpf_admin_019(void)
{
}

void test_gpf_admin_020(void)
{
}

