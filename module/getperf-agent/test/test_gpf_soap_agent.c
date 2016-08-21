#include <CUnit/CUnit.h>
#include <CUnit/Console.h>
#include <CUnit/Basic.h>

#include "gpf_common.h"
#include "gpf_log.h"
#include "gpf_config.h"
#include "gpf_param.h"
#include "gpf_soap_common.h"
#include "gpf_soap_agent.h"
#include "soapH.h"
#include "stdsoap2.h"

#include "test_config.h"
#include "unit_test.h"
#include "cunit_test.h"

GPFConfig *gpfTestConfig(char *sslDir, int testType);
GPFConfig *_gpfTestConfig(char *sslDir, int testType);
GPFSetupConfig *gpfTestSetup(int testType);

/**
 * テスト用の設定
 *  urlCM,urlPM はテスト環境に合わせて、ホスト名を変更する。ホスト名は証明書のCommonNameと一致させる
 *  必要がある。不一致の場合、SSL通信の事前処理でコネクトエラーとなる。
 */
GPFConfig *gpfTestConfig(char *sslDir, int testType)
{
	int sec;
	int result;
	GPFConfig *config;
	GPFLogConfig *logConfig;
	char cwd[MAXFILENAME];
	char *cacert    = NULL;
	char *clkey     = NULL;

	getcwd(cwd, sizeof(cwd));
	config = gpfCreateConfig(AGENT_HOSTNAME, cwd, "test", "testpath", cwd, "getperf.ini");

	config->schedule = gpfCreateSchedule();
	config->schedule->debugConsole = 1;
	config->schedule->logLevel     = GPF_DBG;
	gpfOpenLog( config, "getperf");
	GCON = config;

	cacert = gpfCatFile(cwd, "cfg", sslDir, "ca.crt", NULL);
	clkey  = gpfCatFile(cwd, "cfg", sslDir, "client.pem", NULL);

	config->cacertFile    = cacert;
	config->clkeyFile     = clkey;

	config->schedule->soapTimeout = 30;
	config->schedule->proxyEnable = 0;
	config->schedule->proxyHost   = strdup("192.168.24.2");
	config->schedule->proxyPort   = 8080;
	
	if (testType == 0) 
	{
		config->schedule->siteKey     = strdup(SITE_KEY);
		config->schedule->urlCM       = strdup(URL_CM);
		config->schedule->urlPM       = strdup(URL_PM);
		// config->schedule->siteKey     = strdup("IZA5971");
		// config->schedule->urlCM       = strdup("https://getperf.cm:57443/axis2/services/GetperfCMService");
		// config->schedule->urlPM       = strdup("https://getperf.cm:57443/axis2/services/GetperfPMService");
	}
	else if (testType == 1)
	{
		config->schedule->siteKey     = strdup("IZA5971");
		config->schedule->urlCM       = strdup("https://hoge:57443/axis2/services/GetperfCMService");
		config->schedule->urlPM       = strdup("https://hoge:57443/axis2/services/GetperfPMService");
	}
	else if (testType == 2)
	{
//		config->schedule->proxyEnable = 1;
		config->schedule->siteKey     = strdup(SITE_KEY);
		config->schedule->urlCM       = strdup(URL_CM);
		config->schedule->urlPM       = strdup(URL_PM);
		// config->schedule->siteKey     = strdup("IZA5971");
		// config->schedule->urlCM       = strdup("https://getperf.cm:57443/axis2/services/GetperfCMService");
		// config->schedule->urlPM       = strdup("https://getperf.cm:57443/axis2/services/GetperfPMService");
	}
	else if (testType == 3)
	{
		config->schedule->siteKey     = strdup("HOGE");
		config->schedule->urlCM       = strdup(URL_CM);
		config->schedule->urlPM       = strdup(URL_PM);
		// config->schedule->urlCM       = strdup("https://getperf.cm:57443/axis2/services/GetperfCMService");
		// config->schedule->urlPM       = strdup("https://getperf.cm:57443/axis2/services/GetperfPMService");
	}
	else if (testType == 4)
	{
		// 192.168.10.1:57443
		config->schedule->siteKey     = strdup(SITE_KEY);
		config->schedule->urlCM       = strdup(URL_CM_NO_SSL);
		config->schedule->urlPM       = strdup(URL_PM_NO_SSL);
	}
	return(config);
}

/**
 *  PM用ReserveFileSender()動作確認。クライアントSSL使用。
 */

void test_gpf_soap_agent_001(void)
{
	int sec;
	int result;
	GPFConfig *config;
	GPFLogConfig *logConfig;
	char cwd[MAXFILENAME];

	/* 正常動作。クライアントホスト名と証明書のCommonNameのチェックはしていないため、
	   ホスト名を変えてもエラーは生じない */
	config = gpfTestConfig("ssl", 0);
	config->host = strdup( "hogehoge" );
	printf("host=%s\n", config->host); 
	result = gpfReserveFileSender( config, "ON", &sec );
	CU_ASSERT(result == 1);

	/* 証明書エラー */
	gpfFreeConfig(&config);
	config = gpfTestConfig("ssl_old", 0);
	GCON = config;
	result = gpfReserveFileSender( config, "ON", &sec );
	CU_ASSERT(result == 0);
	gpfCloseLog(config);
	gpfFreeConfig(&config);

	/* URLの記述エラー(ホスト名が正しくない) */
	config = gpfTestConfig("ssl", 1);
	GCON = config;
	result = gpfReserveFileSender( config, "ON", &sec );
	CU_ASSERT(result == 0);
	gpfCloseLog(config);
	gpfFreeConfig(&config);

	/* サイトキーが合っていなくても予約はできてしまう。
	   クライアント認証で事前チェックはしており、サーバ側の負荷軽減のため
	*/
	config = gpfTestConfig("ssl", 3);
	GCON = config;
	result = gpfReserveFileSender( config, "ON", &sec );
	CU_ASSERT(result == 1);
	gpfCloseLog(config);
	gpfFreeConfig(&config);
}

/**
 *  PM用SendZipData()動作確認。
 */

void test_gpf_soap_agent_002(void)
{
	int sec;
	int result;
	GPFConfig   *config, *config2;
	
	/* {home}\test\_bk の下の Makefile.inを送信する */
	config = gpfTestConfig("ssl", 0);
	GCON = config;
	printf("arc : %s\n", config->archiveDir );	
	result = gpfReserveFileSender( config, "ON", &sec );
	CU_ASSERT(result == 1);
	result = gpfSendZipData( config, "Makefile.in");
	CU_ASSERT(result == 1);
	
	/* 事前予約していない場合のエラー */
	result = gpfSendZipData( config, "Makefile.in");
	CU_ASSERT(result == 0);

	/* 送信ファイルなしエラー */
	result = gpfSendZipData( config, "hoge");
	CU_ASSERT(result == 0);
	gpfCloseLog(config);
	gpfFreeConfig(&config);

	/* サイトキーが合っていなくても予約はできてしまう。
	   クライアント認証で事前チェックはしており、サーバ側の負荷軽減のため */
	config = gpfTestConfig("ssl", 3);
	GCON = config;
	result = gpfReserveFileSender( config, "ON", &sec );
	result = gpfSendZipData( config, "Makefile.in");
	CU_ASSERT(result == 1);
	gpfCloseLog(config);
	gpfFreeConfig(&config);
}

/**
 *  タイムアウト処理の動作確認
 */

void test_gpf_soap_agent_003(void)
{
	int sec;
	int result;
	GPFConfig   *config;

	/* URL接続エラー。タイムアウトを5秒に設定しているが効かない。
	   もっと短い時間でエラー発生。TCPセッションの初期の確立で失敗する場合はタイムアウト
	   まで待たない */
	config = gpfTestConfig("ssl", 1);
	GCON = config;
	config->schedule->soapTimeout = 5;
	result = gpfReserveFileSender( config, "ON", &sec );
	CU_ASSERT(result == 0);
	gpfFreeConfig(&config);

	/* プロキシー接続エラー。5秒でタイムアウトする(タイムアウトが効いてる)。 */
	config = gpfTestConfig("ssl", 2);
	GCON = config;
	config->schedule->soapTimeout = 5;
	result = gpfReserveFileSender( config, "ON", &sec );
	CU_ASSERT(result == 0);
	gpfFreeConfig(&config);

	/* プロキシー接続エラー。30秒でタイムアウトする(タイムアウトが効いてる)。 */
	config = gpfTestConfig("ssl", 2);
	result = gpfReserveFileSender( config, "ON", &sec );
	CU_ASSERT(result == 0);		
	gpfFreeConfig(&config);
}

/**
  * プロキシーテスト。gpfTestConfig()に記述した、
  * 以下のアドレス、ポートでプロキシーが存在すること。
	config->schedule->proxyHost   = strdup("192.168.24.2");
	config->schedule->proxyPort   = 8080;
 */
void test_gpf_soap_agent_004(void)
{
	int sec;
	int result;
	GPFConfig   *config;

	/* 正常動作 */
	config = gpfTestConfig("ssl", 3);
	GCON = config;
	printf("debug : %d\n", config->logConfig->showLog );	
	result = gpfReserveFileSender( config, "ON", &sec );
	CU_ASSERT(result == 1);

	/* ポートエラー */
	config->schedule->proxyPort   = 1234;
	result = gpfReserveFileSender( config, "ON", &sec );
	CU_ASSERT(result == 0);

	gpfFreeConfig(&config);

}

/**
 * CM用ダウンロードgpfDownloadConfigFilePM() 動作確認
 */

void test_gpf_soap_agent_005(void)
{
	int result;
	GPFConfig   *config;
	
	/* 正常動作 */
	config = gpfTestConfig("ssl", 0);
	GCON = config;
	result = gpfDownloadConfigFilePM( config, "sslconf.zip" );
	CU_ASSERT(result == 1);

	/* 対処ファイルない場合は即時にエラー */
	result = gpfDownloadConfigFilePM( config, "hoge" );
	CU_ASSERT(result == 0);

	/* サイトキーが合っていない場合はサーバ側チェックでエラー
	   Directory not found */
	gpfFreeConfig(&config);
	config = gpfTestConfig("ssl", 3);
	GCON = config;
	result = gpfDownloadConfigFilePM( config, "sslconf.zip" );
	CU_ASSERT(result == 0);
	
	gpfFreeConfig(&config);
}

void test_gpf_soap_agent_006(void)
{
	int result;
	GPFConfig *config;
	GPFConfig *config4;

	/* 正常動作。クライアントホスト名と証明書のCommonNameのチェックはしていないため、
	   ホスト名を変えてもエラーは生じない */
	config = gpfTestConfig("ssl", 0);
	config->host = strdup( AGENT_HOSTNAME );
	printf("host   = %s\n", config->host); 
	printf("url_cm = %s\n", config->schedule->urlCM);
	// arc_{host}__{stat}_{date}_{time}.zip
	result = gpfReserveSender( config, "arc_host1__stat_20150201_000000.zip" );
	CU_ASSERT(result == 1);

	result = gpfReserveSender( config, "hoge.zip" );
	CU_ASSERT(result == 0);

	/* 正常動作。クライアントホスト名と証明書のCommonNameのチェックはしていないため、
	   ホスト名を変えてもエラーは生じない */
	config4 = gpfTestConfig("ssl", 4);
	config4->host = strdup( AGENT_HOSTNAME );
	printf("host=%s\n", config4->host); 
	printf("url_cm = %s\n", config4->schedule->urlCM);
	// arc_{host}__{stat}_{date}_{time}.zip
	result = gpfReserveSender( config4, "arc_host1__stat_20150201_000000.zip" );
	CU_ASSERT(result == 1);

//	gpfFreeConfig(&config);
}

void test_gpf_soap_agent_007(void)
{
	int result;
	GPFConfig   *config;
	char *zip = "arc_host1__stat_20150201_000000.zip";

	config = gpfTestConfig("ssl", 0);
	GCON = config;
	printf("arc : %s\n", config->archiveDir );	
	result = gpfReserveSender( config, zip );
	CU_ASSERT(result == 1);
	result = gpfSendData( config, zip);
	CU_ASSERT(result == 1);
}

void test_gpf_soap_agent_008(void)
{
	int result;
	GPFConfig   *config;

	config = gpfTestConfig("ssl", 0);
	GCON = config;
	result = gpfSendMessage( config, 1, "info message" );
	CU_ASSERT(result == 1);
	result = gpfSendMessage( config, 2, "warn message" );
	CU_ASSERT(result == 1);
	result = gpfSendMessage( config, 3, "error message" );
	CU_ASSERT(result == 1);
	result = gpfSendMessage( config, 4, "fatal message" );
	CU_ASSERT(result == 1);
	result = gpfSendMessage( config, 5, "unkown message" );
	CU_ASSERT(result == 0);
}

void test_gpf_soap_agent_009(void)
{
	int result;
	long timestamp = 0;
	GPFConfig   *config;

	config = gpfTestConfig("ssl", 0);
	GCON = config;
	result = gpfDownloadCertificate( config, timestamp );
	CU_ASSERT(result == 1);
}

void test_gpf_soap_agent_010(void)
{
}

void test_gpf_soap_agent_011(void)
{
}

void test_gpf_soap_agent_012(void)
{
}

void test_gpf_soap_agent_013(void)
{
}

void test_gpf_soap_agent_014(void)
{
}

void test_gpf_soap_agent_015(void)
{
}

void test_gpf_soap_agent_016(void)
{
}

void test_gpf_soap_agent_017(void)
{
}

void test_gpf_soap_agent_018(void)
{
}

void test_gpf_soap_agent_019(void)
{
}

void test_gpf_soap_agent_020(void)
{
}

