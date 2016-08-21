#include <CUnit/CUnit.h>
#include <CUnit/Console.h>
#include <CUnit/Basic.h>

#include "gpf_common.h"
#include "gpf_log.h"
#include "gpf_config.h"
#include "gpf_param.h"
#include "gpf_soap_common.h"
#include "gpf_soap_admin.h"
#include "soapH.h"
#include "stdsoap2.h"

#include "unit_test.h"
#include "cunit_test.h"
#include "test_config.h"

GPFConfig *gpfTestConfig(char *sslDir, int testType);
GPFSetupConfig *gpfTestSetup(int testType);

GPFSetupConfig *gpfTestSetup(int testType)
{
	char cwd[MAXFILENAME];
	GPFSetupConfig *setup;

	setup    = gpfCreateSetupConfig();
	setup->configZip = strdup("sslconf.zip");
	if (testType == 0)
	{
		setup->osType   = strdup("Linux");
		setup->statName = strdup("HW");
		setup->userName = strdup("test1");
		setup->password = strdup(ACCESS_KEY);
		setup->siteKey  = strdup(SITE_KEY);
		setup->siteId   = 1;
		setup->domainId = 1;
	}
	else if (testType == 1)
	{
		setup->osType   = strdup("Windows");
		setup->statName = strdup("HW");
		setup->userName = strdup("test1");
		setup->password = strdup("test1");
		setup->siteKey  = strdup("IZA5971");
		setup->siteId   = 1;
		setup->domainId = 1;
	}
	else if (testType == 2)
	{
		setup->osType   = strdup("Linux");
		setup->statName = strdup("HW");
		setup->userName = strdup("test1");
		setup->password = strdup("hogehoge");
		setup->siteKey  = strdup("IZA5971");
		setup->siteId   = 1;
		setup->domainId = 1;
	}
	else if (testType == 3)
	{
		setup->osType   = strdup("Linux");
		setup->statName = strdup("HW");
		setup->userName = strdup("test1");
		setup->password = strdup("test1");
		setup->siteKey  = strdup("HOGEHOGE");
		setup->siteId   = 1;
		setup->domainId = 1;
	}

	return setup;
}

/**
 *  CM用gpfCheckDomain()動作確認。サーバSSL使用。
 */
void test_gpf_soap_admin_001(void)
{
}

/**
 *  CM用gpsetCheckVerifyCommands()動作確認。
 */
void test_gpf_soap_admin_002(void)
{
}

/**
 *  CM用gpfRegistHost()動作確認。
 */
void test_gpf_soap_admin_003(void)
{
}

/**
 *  CM用gpfCheckHostStatus()動作確認。
 *    ユーザ認証はしたがホストが存在しない場合は-1を返す（新規登録の場合）
 */
void test_gpf_soap_admin_004(void)
{
}

/**
 *  CM用gpfRequestCertifyHost()動作確認。
 */
void test_gpf_soap_admin_005(void)
{
}

/**
 *  CM用gpfCheckCoreUpdate()動作確認
 *    マクロ GPF_OSNAME, GPF_ARCH をパラメータに使用
 *    gpfTestConfig()内に記述したプロキシー設定を使用。（テストはエラーにしている）
 */
void test_gpf_soap_admin_006(void)
{
}

/**
 *  CM用gpfCheckStatUpdate()動作確認
 *     ビルドが更新されず複数のビルドがない場合は0を返す
 */
void test_gpf_soap_admin_007(void)
{
}

/**
 *  CM用gpfSendVerifyResult()動作確認
*     {home}\test\_bkの下のMakefile.iniを送信する
 */
void test_gpf_soap_admin_008(void)
{
}

/**
 *  CM用gpfDownloadConfigFileCM()動作確認
*     {home}\test\_wk\... の下のMakefile.iniを受信する
 */

void test_gpf_soap_admin_009(void)
{
}

/**
 *  CM用gpsetCheckSiteLicense()動作確認
 */

void test_gpf_soap_admin_010(void)
{
}

/**
 * getModuleArchive() 動作確認
 * skel/module/{バージョン番号}/の下のアーカイブをダウンロードする
 * 命名例は以下のとおり
     /2/getperf-RHEL5-x86_64-2.zip
     /2/getperf-stat-JVM-UNIX-1.zip
     /2/getperf-stat-JVM-Windows-1.zip
 */

void test_gpf_soap_admin_011(void)
{
}

void test_gpf_soap_admin_012(void)
{
	int result;
	GPFConfig      *config  = NULL;
	GPFConfig      *config4 = NULL;
	GPFSetupConfig *setup   = NULL;
	setup  = gpfTestSetup(0);

	/* 正常動作 */
	config = gpfTestConfig("ssl", 0);
	GCON = config;

	result = gpsetGetLatestBuild( config );
	CU_ASSERT(result == 4);
}

void test_gpf_soap_admin_013(void)
{
}

void test_gpf_soap_admin_014(void)
{
	int result;
	GPFConfig      *config = NULL;
	GPFSetupConfig *setup  = NULL;
	setup  = gpfTestSetup(0);

	/* 正常動作 */
	config = gpfTestConfig("ssl", 0);
	GCON = config;
	result = gpsetRegistAgent( config, setup );
	CU_ASSERT(result == 1);

	/* サイト名不一致 */
	gpfFreeSetupConfig(&setup);
	setup  = gpfTestSetup(2);
	GCON = config;
	result = gpsetRegistAgent( config, setup );
	CU_ASSERT(result == 0);
}

void test_gpf_soap_admin_015(void)
{
	int result;
	int build = 0;
	GPFConfig      *config = NULL;
	GPFSetupConfig *setup  = NULL;
	config = gpfTestConfig("ssl", 0);
	GCON = config;

	/* 正常終了 */
	build = 4;
	result = gpfDownloadUpdateModule( config, build, "getperf-bin-CentOS6-x86_64-4.zip" );
	CU_ASSERT(result == 1);

	gpfFreeConfig(&config);
	gpfFreeSetupConfig(&setup);
}

void test_gpf_soap_admin_016(void)
{
}

void test_gpf_soap_admin_017(void)
{
}

void test_gpf_soap_admin_018(void)
{
}

void test_gpf_soap_admin_019(void)
{
}

void test_gpf_soap_admin_020(void)
{
}

