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

GPFConfig *gpfTestConfig(char *sslDir, int testType);
GPFSetupConfig *gpfTestSetup(int testType);

/**
 * zip圧縮テスト
 * {home}\test下のsslディレクトリを{home}\test\sslconf.zipに圧縮
 */
void test_gpf_soap_common_001(void)
{
	int result        = 0;
	char *zipfile     = NULL;
	char *basedir     = NULL;
	char *parentpath  = NULL;
	char *passwd      = NULL;
	char cwd[MAXFILENAME];
	
	getcwd(cwd, sizeof(cwd));
	
	/* 基本動作
	 * {home}\test下のsslディレクトリを{home}\test\sslconf.zipに圧縮
	 */
	
	zipfile    = gpfCatFile ( cwd, "sslconf.zip", NULL );
	basedir    = cwd;
	parentpath = "ssl";
	passwd     = "test";
	
	printf("zipfile : %s\n", zipfile);
	printf("basedir : %s\n", basedir);
	printf("parent  : %s\n", parentpath);
	printf("passwd  : %s\n", passwd);
	
	result = zipDir( zipfile, basedir, parentpath, NULL );
	CU_ASSERT(result == 1);

	/* パスワード付きで圧縮 */
	result = zipDir( zipfile, basedir, parentpath, "test" );
	CU_ASSERT(result == 1);

	/* エラー（圧縮対象ディレクトリなし） */
	result = zipDir( zipfile, basedir, "hogehoge", passwd );
	CU_ASSERT(result == 0);
	gpfFree(zipfile);

	/* エラー（zipファイルディレクトリなし） */
	zipfile    = gpfCatFile ( cwd, "hogehoge", "hoge.zip", NULL );
	result = zipDir( zipfile, basedir, parentpath, passwd );
	CU_ASSERT(result == 0);
	
	gpfFree(zipfile);
}

/**
 * zip解凍テスト
 * {home}\test下のsslディレクトリを{home}\test\sslconf.zipに圧縮、解凍
 */
void test_gpf_soap_common_002(void)
{
	int result        = 0;
	char *zipfile     = NULL;
	char *basedir     = NULL;
	char *basedirsrc  = NULL;
	char *parentpath  = NULL;
	char *passwd      = NULL;
	char cwd[MAXFILENAME];
	
	getcwd(cwd, sizeof(cwd));
	
	/* 基本動作
	 * {home}\test下のsslディレクトリを{home}\test\sslconf.zipに圧縮、解凍
	 */
	zipfile    = gpfCatFile ( cwd, "sslconf.zip", NULL );
	basedir    = cwd;
	parentpath = "ssl";
	passwd     = "hogehoge";
	
	printf("zipfile : %s\n", zipfile);
	printf("basedir : %s\n", basedir);
	
	basedirsrc = gpfCatFile ( cwd, "home", NULL );
	result = zipDir( zipfile, basedirsrc, "ssl", NULL );
	CU_ASSERT(result == 1);
	result = unzipDir( zipfile, basedir, NULL );
	CU_ASSERT(result == 1);

	/* パスワード付き圧縮、解凍 */
	result = zipDir( zipfile, basedirsrc, "ssl", passwd );
	CU_ASSERT(result == 1);
	result = unzipDir( zipfile, basedir, passwd );
	CU_ASSERT(result == 1);
	
	/* パスワードエラー */
	/* (注意) 空ファイルの場合はパスワードエラーにならずに解凍できてしまう */
	result = unzipDir( zipfile, basedir, NULL );
	CU_ASSERT(result == 0);

	result = unzipDir( zipfile, basedir, "hogehogehoge" );
	CU_ASSERT(result == 0);

	/* ベースディレクトリなしエラー */
	gpfFree(zipfile);
	result = unzipDir(zipfile, "/hoge", passwd );
	CU_ASSERT(result == 0);

	/* 解凍ファイルなしエラー */
	gpfFree(zipfile);
	zipfile    = gpfCatFile ( cwd, "hoge.zip", NULL );
	result = unzipDir(zipfile, basedir, passwd );
	CU_ASSERT(result == 0);
	gpfFree(zipfile);
	gpfFree(basedirsrc);

}

void test_gpf_soap_common_003(void)
{
}

void test_gpf_soap_common_004(void)
{
}

void test_gpf_soap_common_005(void)
{
}

void test_gpf_soap_common_006(void)
{
}

void test_gpf_soap_common_007(void)
{
}

void test_gpf_soap_common_008(void)
{
}

void test_gpf_soap_common_009(void)
{
}

void test_gpf_soap_common_010(void)
{
}

void test_gpf_soap_common_011(void)
{
}

void test_gpf_soap_common_012(void)
{
}

void test_gpf_soap_common_013(void)
{
}

void test_gpf_soap_common_014(void)
{
}

void test_gpf_soap_common_015(void)
{
}

void test_gpf_soap_common_016(void)
{
}

void test_gpf_soap_common_017(void)
{
}

void test_gpf_soap_common_018(void)
{
}

void test_gpf_soap_common_019(void)
{
}

void test_gpf_soap_common_020(void)
{
}

