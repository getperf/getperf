#include <CUnit/CUnit.h>
#include <CUnit/Console.h>
#include <CUnit/Basic.h>

#include "gpf_config.h"
#include "gpf_common.h"
#include "gpf_log.h"

#include "unit_test.h"
#include "cunit_test.h"

struct exec_test_cfg
{
        char *base;
        char *src;
        char *dest;
        char *result;
};

/* gpfStringReplace */

void test_gpf_common_001(void)
{
	{
		char *res1 = NULL;
		char *res2 = NULL;
		char *res3 = NULL;
		int ck = -1;
		char *base = strdup("_pwd_/getnets.sh -l _log_");

		res1 = gpfStringReplace(base, "_pwd_", "/export/home/ptune");
		res2 = gpfStringReplace(res1, "_log_", "/export/home/ptune/log");
		CU_ASSERT(
			strcmp(res2, "/export/home/ptune/getnets.sh -l /export/home/ptune/log") 
			== 0
		);

		res3 = gpfStringReplace(res2, "/export/home", "/home");
		CU_ASSERT(
			strcmp(res3, "/home/ptune/getnets.sh -l /home/ptune/log") 
			== 0
		);

		gpfFree(base);
		gpfFree(res1);
		gpfFree(res2);
		gpfFree(res3);
	}

	{
		char *res1 = NULL;
		int ck = -1;
		char *base = strdup("_pwd_/getnets.sh -l _pwd_");

		res1 = gpfStringReplace(base, "_pwd_", "/export/home/ptune");
		CU_ASSERT(
			strcmp(res1, "/export/home/ptune/getnets.sh -l /export/home/ptune") 
			== 0
		);

		gpfFree(base);
		gpfFree(res1);
	}
}

/* int gpfSnprintf(char* str, size_t count, const char *fmt, ...) */

void test_gpf_common_002(void)
{
	/*
	 * vsnprintf()の拡張。最後に終端文字'\0'を追加する
	 *
	 * 最後に終端文字を追加するため、引数の長さは1バイト足して指定する必要がある
	 */
	 
	int res_size;
	int val_len = 11;
	
	char *val = (char *)malloc((val_len)* sizeof(char));
/*	*val = '\0'; */

	res_size = gpfSnprintf(val, 8, "test %s", "0123456789");
	printf("1.%d : '%s'\n", strlen(val), val);
	CU_ASSERT(res_size == 7);
	res_size = gpfSnprintf(val, val_len, "test %s", "0123");
	printf("2.%d : '%s'\n", res_size, val);
	CU_ASSERT(res_size == 10);
	res_size = gpfSnprintf(val, val_len, "%s", "0123456789");
	printf("3.%d : '%s'\n", res_size, val);
	CU_ASSERT(res_size == 10);
	res_size = gpfSnprintf(val, val_len, "%s", "012345");
	printf("4.%d : '%s'\n", res_size, val);
	CU_ASSERT(res_size == 7);
	res_size = gpfSnprintf(val, 0, "%s", "012345");
	printf("5.%d : '%s'\n", res_size, val);
	CU_ASSERT(res_size == 0);
	res_size = gpfSnprintf(val, -1, "%s", "012345");
	printf("6.%d : '%s'\n", res_size, val);
	CU_ASSERT(res_size == 0);

	gpfFree(val);
}

/* char *gpfStringReplace(char *str, char *src, char *dest) */

void test_gpf_common_003(void)
{
	char *val = NULL;
	
	val = gpfStringReplace("_pwd_/test.sh -l _pwd_/log -s _pwd_/src",
		"_pwd_",
		"/export/home/ptune"
	);
	/* printf("%d : %s\n", strlen(val), val); */
	CU_ASSERT(strlen(val) == 78);
	gpfFree(val);
	
	val = gpfStringReplace("_pwd_/test.sh -l _pwd_/log -s _pwd_/src",
		"",
		"/export/home/ptune"
	);
	/* printf("%d : %s\n", strlen(val), val); */
	CU_ASSERT(val == NULL);
	gpfFree(val);

	val = gpfStringReplace("_pwd_/test.sh -l _pwd_/log -s _pwd_/src",
		"hoge",
		"/export/home/ptune"
	);
	/* printf("%d : %s\n", strlen(val), val); */
	CU_ASSERT(strlen(val) == 39);
	gpfFree(val);
}

/* void gpfLRtrim(char *str, const char *charlist) */

void test_gpf_common_004(void)
{
	/* NULL は不可 */
	
	char *val = strdup("   \t   test");
	gpfLtrim(val, GPF_CFG_LTRIM_CHARS);
/*	printf("%d : %s\n", strlen(val), val); */
	CU_ASSERT(strlen(val) == 4);
	gpfFree(val);
	
	val = strdup("test\t\t\n");
	gpfRtrim(val, GPF_CFG_RTRIM_CHARS);
/*	printf("%d : %s\n", strlen(val), val);  */
	CU_ASSERT(strlen(val) == 4);
	gpfFree(val);

	val = strdup("   \t\ttest\t\t\n");
	gpfLRtrim(val, GPF_CFG_RTRIM_CHARS);
/*	printf("%d : %s\n", strlen(val), val); */
	CU_ASSERT(strlen(val) == 4);
	gpfFree(val);

	val = strdup("");
	gpfLRtrim(val, GPF_CFG_RTRIM_CHARS);
/*	printf("%d : %s\n", strlen(val), val); */
	CU_ASSERT(strlen(val) == 0);
	gpfFree(val);

/*
	val = NULL;
	gpfLRtrim(val, GPF_CFG_RTRIM_CHARS);
	printf("%d : %s\n", strlen(val), val); 
	CU_ASSERT(strlen(val) == 0);
	gpfFree(val);
*/
}

/** 
 * 「全位置の空白文字列の削除」テスト
 * void gpfRemoveChars(char *str, const char *charlist) 
 */

void test_gpf_common_005(void)
{
	/* NULLの場合は何もしない */

	char *val = strdup(" t e s  t");
	gpfRemoveChars(val, GPF_CFG_LTRIM_CHARS);
/*	printf("%d : %s\n", strlen(val), val); */
	CU_ASSERT(strcmp(val, "test") == 0);
	gpfFree(val);

#if defined _WINDOWS
#else
	val = strdup(" 漢  字  ");
	gpfRemoveChars(val, GPF_CFG_LTRIM_CHARS);
/*	printf("%d : %s\n", strlen(val), val); */
	CU_ASSERT(strcmp(val, "漢字") == 0);
	gpfFree(val);
#endif

	val = strdup("");
	gpfRemoveChars(val, GPF_CFG_LTRIM_CHARS);
/*	printf("%d : %s\n", strlen(val), val); */
	CU_ASSERT(strlen(val) == 0);
	gpfFree(val);

	val = strdup("\t\t\t  \t \t\n");
	gpfRemoveChars(val, GPF_CFG_LTRIM_CHARS);
/*	printf("%d : %s\n", strlen(val), val); */
	CU_ASSERT(strcmp(val, "\n") == 0);
	gpfFree(val);

	val = NULL;
	gpfRemoveChars(val, GPF_CFG_LTRIM_CHARS);
/*	printf("%d : %s\n", strlen(val), val); */
	CU_ASSERT(val == NULL);
//	gpfFree(val);

}

/* gpfStrlcpy(char *dst, const char *src, size_t siz) */

void test_gpf_common_006(void)
{
	/* 予め、コピー先の文字列は指定サイズ分のメモリを確保する必要がある */
	/* 指定サイズはコピー元の文字サイズ+1バイトが必要 */
	
	char *val = strdup("test");
	size_t len = gpfStrlcpy(val, "longname", 4); // n-1 文字目までコピーする
	printf("%d : %s\n", len, val);
	CU_ASSERT(strcmp(val, "lon") == 0 && len == 8);
	gpfFree(val);
	
	/* コピー元のサイズが指定サイズより小さい場合は正常終了するがメモリ破壊が起きる。
	   必ずコピー元のサイズより小さい値にすること。
	val = strdup("test");
	len = gpfStrlcpy(val, "longname", 12);       // n-1 文字目までコピーする
	printf("%d : %s\n", len, val);
	CU_ASSERT(strcmp(val, "lon") == 0 && len == 8);
	gpfFree(val);
	*/
	
	val = strdup("longname");
	len = gpfStrlcpy(val, "test", 5);
	CU_ASSERT(strcmp(val, "test") == 0 && len == 4);
	gpfFree(val);

	val = strdup("longname");
	len = gpfStrlcpy(val, "test2", 8);
	CU_ASSERT(strcmp(val, "test2") == 0 && len == 5);
	gpfFree(val);

	val = strdup("longname");
	len = gpfStrlcpy(val, "test2", 0);		// サイズが0の場合は何もしない
	printf("%d : %s\n", strlen(val), val); 
	CU_ASSERT(strcmp(val, "longname") == 0);
	gpfFree(val);


}

/* size_t gpfStrlcat(char *dst, const char *src, size_t siz) */

void test_gpf_common_007(void)
{
	/* 予め、コピー先の文字列は指定サイズ分のメモリを確保する必要がある */
	/* 指定サイズは連結後の文字サイズに1バイト足したサイズが必要 */
	
	char *val = NULL;
	size_t len = 0;

	/* 通常ケース */
	val = strdup("longlongname");
	len = gpfStrlcpy(val, "test", strlen(val) );
	len = gpfStrlcat(val, "test2", 12);
	gpfError("%d : %s", len, val); 
	
	CU_ASSERT(strcmp(val, "testtest2") == 0 && len == 9);
	gpfFree(val);

	val = gpfMalloc( val, MAX_STRING_LEN );
	len = gpfStrlcpy(val, "test2", MAX_STRING_LEN);
	len = gpfStrlcat(val, "test3", MAX_STRING_LEN);
	gpfError("%d : %s", len, val); 
	
	CU_ASSERT(strcmp(val, "test2test3") == 0 && len == 10);
	gpfFree(val);

	/* バッファオーバーフロー */
	val = strdup("01234567890");
	len = gpfStrlcpy(val, "test",  11 );
	gpfError("%d : %s", len, val); 
	len = gpfStrlcat(val, "test2", 11 );
	gpfError("%d : %s", len, val); 
	CU_ASSERT(strcmp(val, "testtest2") == 0 && len == 9);

	len = gpfStrlcat(val, "test3", 11 );
	gpfError("%d : %s", len, val); 
	CU_ASSERT(strcmp(val, "testtest2t") == 0 && len == 10);
	gpfFree(val);
}


/**
 * char* gpfDsprintf(char *dest, const char *f, ...)
 *
 * vsnprintf()の拡張。必要なメモリを確保する。
 * 連続して使用する場合は、第一引数に戻り値の変数を指定すること
 * @param dst   コピー先文字列
 * @param f     フォーマット
 * @param ...   可変長引数
 * @return 変換した文字列
 */
void test_gpf_common_008(void)
{
	/* gpfDsprintf() を連続して使用する場合は、第一引数に変数を指定すること */
	/* 指定しないとメモリリークが発生する */
	
	char *val = NULL;
	size_t len = 0;
	int i = 0;
	
	val = gpfDsprintf(val, "this is a %s() test", "gpfDsprintf");
	printf("%d : %s\n", strlen(val), val); 
	CU_ASSERT(strcmp(val, "this is a gpfDsprintf() test") == 0);
	
	val = gpfDsprintf(val, "this is a %s() test2", "gpfDsprintf");
	printf("%d : %s\n", strlen(val), val); 
	CU_ASSERT(strcmp(val, "this is a gpfDsprintf() test2") == 0);
	
	val = gpfDsprintf(val, "this is a %s() test3", val);
	printf("%d : %s\n", strlen(val), val); 
	CU_ASSERT(strcmp(val, "this is a this is a gpfDsprintf() test2() test3") == 0);

	gpfFree(val);

	val = strdup("test");
	
	for (i = 0; i < 100; i++) {
		val = gpfDsprintf(val, "%s:%d", val, i);
	}
	CU_ASSERT(strlen(val) == 294);

	gpfFree(val);
}


/**
 * char* gpfStrdcat(char *dest, const char *src)
 *
 * strncat()の拡張。必要なメモリを確保する
 * @param dst   コピー先文字列
 * @param src   コピー元文字列
 * @return 連結後のサイズ
 */
void test_gpf_common_009(void)
{
	/* gpfStrdcat() を連続して使用する場合は、第一引数に変数を指定すること */
	/* 指定しないとメモリリークが発生する */

	char *dest = strdup("");
	char *src  = strdup("test2");
	char *val  = NULL;
	int i = 0;
	
	val = gpfStrdcat(dest, src);
	CU_ASSERT(strlen(val) == 5);
	val = gpfStrdcat(val, src);
	CU_ASSERT(strlen(val) == 10);

	gpfFree(val);
	for (i = 0; i < 100; i++) {
		val = gpfStrdcat( val, "0123456789" );
	}
	CU_ASSERT(strlen(val) == 1000);

	gpfFree(src);
	gpfFree(val);
}

/* char **gpfSplit(int *n, char *sep, char *string) */

void test_gpf_common_010(void)
{
	/* 入力文字列はstrtok()関数内で更新されるので、strdup関数などで予めコピーした文字列を
	 * 指定する。静的変数は利用不可
	*/
	 
	int i = 0;
	int n = 0;

	char **val = NULL;
	char *src = strdup("this \tis a test1 b \ntest c");
	
	val = gpfSplit(&n, " \t\n", src);
	CU_ASSERT(n == 7 
		&& strcmp( val[0], "this")  == 0
		&& strcmp( val[1], "is")    == 0
		&& strcmp( val[2], "a")     == 0
		&& strcmp( val[3], "test1") == 0
		&& strcmp( val[4], "b")     == 0
		&& strcmp( val[5], "test")  == 0
		&& strcmp( val[6], "c")     == 0
	);
	gpfFree(val);
	gpfFree(src);

	src = strdup("");
	val = gpfSplit(&n, " \t\n", src);
	printf("split1=%d\n", n );
	CU_ASSERT(n == 0);
	gpfFree(val);
	gpfFree(src);

	src = NULL;
	val = gpfSplit(&n, " \t\n", src);
	printf("split1=%d\n", n );
	CU_ASSERT(n == 0);
	gpfFree(val);
	gpfFree(src);

	src = strdup("this is a test");
	val = gpfSplit(&n, "", src);
	CU_ASSERT(n == 1 
		&& strcmp( val[0], "this is a test")  == 0
	);
	gpfFree(val);
	gpfFree(src);

	/* sep は NULL 指定不可 */
	/*
	src = strdup("this is a test");
	val = gpfSplit(&n, NULL, src);
	CU_ASSERT(n == 1 
		&& strcmp( val[0], "this is a test")  == 0
	);
	gpfFree(val);
	gpfFree(src);
	*/
}

/**
 * 相対パスを絶対パスに変換します
 * char *rel2abs(const char *path, const char *base, char *result, const size_t size);
 *
 * @param path   変換対象パス
 * @param base   基準ディレクトリ
 * @param result 変換結果格納バッファ
 * @param size   バッファサイズ
 * @return 絶対パス
 */
void test_gpf_common_011(void)
{
	char val[MAXFILENAME];
#ifdef WIN32
	rel2abs("..\\..\\src\\sys", "c:\\usr\\local\\lib", val, MAXFILENAME);
	CU_ASSERT(strcmp(val, "c:\\usr\\src\\sys") == 0);
	rel2abs("src\\sys", "c:\\usr", val, MAXFILENAME);
	CU_ASSERT(strcmp(val, "c:\\usr\\src\\sys") == 0);
	rel2abs(".", "c:\\usr\\local\\lib", val, MAXFILENAME);
	CU_ASSERT(strcmp(val, "c:\\usr\\local\\lib") == 0);
	rel2abs("c:\\", "c:\\usr\\local\\lib", val, MAXFILENAME);
	printf("%d : %s\n", strlen(val), val); 
#else
	rel2abs("../../src/sys", "/usr/local/lib", val, MAXFILENAME);
	printf("path=%s,base=%s,res=%s\n", "../../src/sys", "/usr/local/lib", val);
	CU_ASSERT(strcmp(val, "/usr/src/sys") == 0);
	rel2abs("src/sys", "/usr", val, MAXFILENAME);
	printf("path=%s,base=%s,res=%s\n", "src/sys", "/usr", val);
	CU_ASSERT(strcmp(val, "/usr/src/sys") == 0);
	rel2abs(".", "/usr/src/sys", val, MAXFILENAME);
	printf("path=%s,base=%s,res=%s\n", ".", "/usr/src/sys", val);
	CU_ASSERT(strcmp(val, "/usr/src/sys") == 0);
	rel2abs("/", "/usr/src/sys", val, MAXFILENAME);
	printf("path=%s,base=%s,res=%s\n", "/", "/usr/src/sys", val);
	printf("%d : %s\n", strlen(val), val); 
#endif

}
/**
 * 実行パスから上位のディレクトリを絶対パスに変換して返す
 * char *gpfGetParentPathAbs( char *inPath, int parentLevel )
 *
 * @param inPath 入力パス
 * @param parentLevel 上位の階層の数
 * @return 合否
 */
void test_gpf_common_012(void)
{
	char cwd[MAXFILENAME];
	char absPath[MAXFILENAME];
	char *test[] = {
		".",
		"../abc",
		"./../def",
		"h/i/j",
		"/usr/local",
		"c:\\program files\\test",
		"\\\\getperf.moi\\test",
		""
	};
	
	char *path  = NULL;
	char *path1 = NULL;
	char *path2 = NULL;
	char *val   = NULL;
	int i = 0;
	int parentFlag = 0;
	
	getcwd(cwd, sizeof(cwd));
	for (i = 0; strcmp(test[i], "") != 0; i++) 
	{
		path1 = rel2abs(test[i], cwd, absPath, MAXFILENAME);
		CU_ASSERT(path1 != NULL);
		printf("[%d] %s\n", i, path1);  
	}

	for (parentFlag = 0; parentFlag <= 1; parentFlag ++) 
	{
		for (i = 0; strcmp(test[i], "") != 0; i++) 
		{
			path = gpfStringReplace(test[i], "/", GPF_FILE_SEPARATORS);
			val = gpfGetParentPathAbs(path, parentFlag);
			CU_ASSERT(val != NULL);
			printf("[%d][%10s] %s\n", parentFlag, path, val); 

			gpfFree(path);
			gpfFree(val);
		}
	}
}

/**
 * ファイルパスを連結する
 * char *gpfCatFile(const char *fmt, ...)
 * @param fmt   第一パス名
 * @param ...   可変長ファイルパス名
 * @return 連結後のパス
 */
void test_gpf_common_013(void)
{
	char *val   = NULL;
	char *indir = NULL;
	char *base  = NULL;
	char *huge  = NULL;
	
	/* 正常ケース */
	indir = strdup("/home/psadmin/work");
	base  = gpfStringReplace(indir, "/", GPF_FILE_SEPARATORS);
	val = gpfCatFile(base, "test1", "test2", NULL);
	printf("%d : %s\n", strlen(val), val); 
	CU_ASSERT(val != NULL && strlen(val) > 0);
	gpfFree(val);
	gpfFree(base);

	/* 異常ケース NULL 文字 */
	base  = gpfStringReplace(indir, "/", GPF_FILE_SEPARATORS);
	val = gpfCatFile(base, "", NULL);
	printf("%d : %s\n", strlen(val), val); 
	CU_ASSERT(val != NULL && strlen(val) > 0);
	gpfFree(val);
	gpfFree(base);
	
	/* 異常ケース バッファオーバフロー */
	huge = (char *)gpfMalloc(huge, sizeof(char) * (MAXFILENAME + 1));
	memset(huge, '0', MAXFILENAME);
	huge[MAXFILENAME] = '\0';
	
	base = gpfStringReplace(indir, "/", GPF_FILE_SEPARATORS);
	val = gpfCatFile(base, huge, NULL);
//	printf("%d : %s\n", strlen(val), val); 
	CU_ASSERT(val == NULL);
	gpfFree(val);
	gpfFree(base);
	gpfFree(huge);

	gpfFree(indir);
}
/**
 * gpfCatFile()の基本動作テスト
 */
void test_gpf_common_014(void)
{
	int i = 0;
	char *val  = NULL;
	char *base = NULL;
	char wkDir[] = "/home/psadmin/work";
	for (i = 0; i< 10; i++)
	{
		base = strdup(wkDir);
		val = gpfCatFile(base, "test1", "test2", NULL);
		printf("%d : %s\n", strlen(val), val); 
		CU_ASSERT(val != NULL && strlen(val) > 0);
		gpfFree(val);
		gpfFree(base);
	}
}


/**
 * ディレクトリの存在確認
 * int gpfCheckDirectory( const char *path)
 *
 * @param path 指定ディレクトリ
 * @return 合否
 */
void test_gpf_common_015(void)
{
	int result = 0;
#ifdef WIN32
	result = gpfCheckDirectory("c:\\windows");
	CU_ASSERT(result == 1);
	result = gpfCheckDirectory("c:\\windows\\system.ini");
	CU_ASSERT(result == 0);
	result = gpfCheckDirectory("c:\\hoge");
	CU_ASSERT(result == 0);
#else
	result = gpfCheckDirectory("/tmp");
	CU_ASSERT(result == 1);
	result = gpfCheckDirectory("/hoge");
	CU_ASSERT(result == 0);
	result = gpfCheckDirectory("");
	CU_ASSERT(result == 0);
#endif
}

/**
 * ワークファイルの読み込み(先頭行のみ)
 * int gpfReadWorkFileHead( GPFConfig *config, char *filename, char **buf, int maxRows)
 * @param config エージェント構造体
 * @param filename ファイル名
 * @param buf バッファ
 * @param maxRows 最大行数
 * @return 合否
 */
void test_gpf_common_016(void)
{
	char cwd[MAXFILENAME];
	int result;
	int lineno = 0;
	GPFConfig *config;
	char *fname = "test.txt";
	char *fpath = NULL;
	FILE *file  = NULL;
	char *buf   = NULL;
	
	getcwd(cwd, sizeof(cwd));
	config = gpfCreateConfig("hoge", cwd, "test", "testpath", cwd, "getperf.ini");
	GCON = config;
	printf("work : %s\n", config->workDir);
	printf("common : %s\n", config->workCommonDir);

	mkdir(config->workDir, 0775);
	
	fpath = gpfCatFile(config->workDir, fname, NULL);
	if ( (file = fopen(fpath, "w")) == NULL)
	{
		gpfSystemError("%s", fpath);
		return ;
	}
	gpfFree(fpath);
	
	for (lineno = 1; lineno < 10; lineno ++)
	{
		fprintf(file, "%d\n", lineno);
	}
	fclose(file);
	
	result = gpfReadWorkFileHead(config, fname, &buf, 5);
	CU_ASSERT(result == 1);
	printf("res1:%s", buf); 
	gpfFree(buf);

	result = gpfReadWorkFileHead(config, fname, &buf, 110);
	CU_ASSERT(result == 1);
	printf("res2:%s", buf); 
	gpfFree(buf);

	result = gpfReadWorkFile(config, fname, &buf);
	CU_ASSERT(result == 1);
	printf("res3:%s", buf); 
	gpfFree(buf);

	result = gpfWriteWorkFile(GCON, fname, "this is a test");
	CU_ASSERT(result == 1);
	gpfFree(buf);

	result = gpfReadWorkFile(GCON, fname, &buf);
	CU_ASSERT(result == 1);
	printf("res3:%s", buf); 
	gpfFree(buf);
	
	gpfRemoveWorkDir( config );
	gpfFreeConfig(&config);
}

/**
 * 指定したフォーマット形式で何秒前の現在時刻を取得
 * @param sec 経過秒
 * @param format フォーマット
 * @param type フォーマットタイプ
 *   GPF_DATE_FORMAT_DEFAULT         0
 *   GPF_DATE_FORMAT_YYYYMMDD        1
 *   GPF_DATE_FORMAT_HHMISS          2
 *   GPF_DATE_FORMAT_YYYYMMDD_HHMISS 3
 *   GPF_DATE_FORMAT_DIR             4
 * @return 合否
 */
void test_gpf_common_017(void)
{
	int result = 0;
	char timeStamp[MAX_STRING_LEN];
	
	result = gpfGetCurrentTime(0, timeStamp, GPF_DATE_FORMAT_DEFAULT);
	CU_ASSERT(result == 1);
	printf("time1 : %s\n", timeStamp);

	result = gpfGetCurrentTime(0, timeStamp, GPF_DATE_FORMAT_YYYYMMDD);
	CU_ASSERT(result == 1);
	printf("time2 : %s\n", timeStamp);

	result = gpfGetCurrentTime(0, timeStamp, GPF_DATE_FORMAT_HHMISS);
	CU_ASSERT(result == 1);
	printf("time3 : %s\n", timeStamp);

	result = gpfGetCurrentTime(0, timeStamp, GPF_DATE_FORMAT_YYYYMMDD_HHMISS);
	CU_ASSERT(result == 1);
	printf("time4 : %s\n", timeStamp);

	result = gpfGetCurrentTime(0, timeStamp, GPF_DATE_FORMAT_DIR);
	CU_ASSERT(result == 1);
	printf("time5 : %s\n", timeStamp);

	result = gpfGetCurrentTime(-10, timeStamp, 0);
	CU_ASSERT(result == 1);
	printf("time6 : %s\n", timeStamp);

	result = gpfGetCurrentTime(0, timeStamp, 999);
	CU_ASSERT(result == 0);
}

/**
 * 指定したディレクトリのディスク使用量[%]を取得
 * @param dir パス名
 * @param capacity ディスク使用率
 * @return 合否
 */
void test_gpf_common_018(void)
{
	char cwd[MAXFILENAME];
	int result = 0;
	int capacity = 0;
	GPFConfig *config = NULL;
	GPFSchedule *schedule = NULL;
	char path[MAX_STRING_LEN];
	
	getcwd(cwd, sizeof(cwd));
	config = gpfCreateConfig("hoge", cwd, "test", "testpath", cwd, "getperf.ini");
	config->schedule = gpfCreateSchedule();
	
	getcwd(path, sizeof(path));
	result = gpfCheckDiskFree(path, &capacity);
	CU_ASSERT(result == 1);
	printf("capacity : %d\n", capacity);

	config->schedule->diskCapacity = 0;
	result = gpfCheckDiskUtil( config );
	CU_ASSERT(result == 1);
	
	config->schedule->diskCapacity = 100;
	result = gpfCheckDiskUtil( config );
	CU_ASSERT(result == 0);

	gpfFreeConfig(&config);
}

void test_gpf_common_019(void)
{
	int i;
	double d0, d1;
	d0 = gpfTime();
	printf("elapsed1: %f", d0);
	sleep(2);
	d1 = gpfTime();
	printf("elapsed2: %f", d1);
	printf("elapsed: %f", d1 - d0);
	CU_ASSERT(1 == 1);

}

void test_gpf_common_020(void)
{
	int ch = 0;
/*
	while ((ch = gpfGetch()) == 0)
	{
		printf("W");
		sleep( 1 );
	}

	printf( "\nKey struck was '%c'\n", ch );
*/
}

void test_gpf_common_021(void)
{
	int result       = 0;
	GPFStrings *zips = NULL;
	int i;
	
	zips   = gpfCreateStrings();
	result = gpfInsertStrings( zips, strdup("test1.zip") );
	CU_ASSERT( result == 1 );
	result = gpfInsertStrings( zips, strdup("hoge.zip") );
	CU_ASSERT( result == 1 );
	result = gpfInsertStrings( zips, strdup("1234567") );
	CU_ASSERT( result == 1 );
	result = gpfInsertStrings( zips, strdup("") );
	CU_ASSERT( result == 1 );

	qsort( zips->strings, zips->size, sizeof(char *), gpfCompareString );
	CU_ASSERT( zips->size == 4 
		&& strcmp( zips->strings[0], "" )          == 0
		&& strcmp( zips->strings[1], "1234567" )   == 0
		&& strcmp( zips->strings[2], "hoge.zip" )  == 0
		&& strcmp( zips->strings[3], "test1.zip" ) == 0
	);
	gpfFreeStrings( zips );

}

/**
 * メッセージを出力し、1行入力する。手動入力が必要なため、テストは省略
 * @param commonFormat 英語メッセージ
 * @param localFormat 日本語メッセージ
 * @param result バッファ
 * @return 合否
 */
void test_gpf_common_022(void)
{
	char *buf   = NULL;
	int result = 0;

	// ユーザIDを入力して下さい   :
	result = gpfGetLine( GPF_MSG031E, GPF_MSG031, &buf);
	printf("res4:[%s]\n", buf); 
	CU_ASSERT( buf != NULL && result == 1 );

	result = gpfGetLine( GPF_MSG031E, GPF_MSG031, &buf);
	printf("res4:[%s]\n", buf); 
	CU_ASSERT( buf != NULL && result == 1 );
	gpfFree(buf);

/*	
	// パスワードを入力して下さい :
	result = gpfGetPass( GPF_MSG031E, GPF_MSG031, &buf);
	printf("res5:[%s]\n", buf); 
	CU_ASSERT( buf != NULL && result == 1 );
	gpfFree(buf);
*/	
}

/**
 * ファイルのコピー
 * @param srcPath コピー元パス
 * @param targetPath コピー先パス
 * @return 合否
 */
void test_gpf_common_023(void)
{
	char cwd[MAXFILENAME];
	char *src  = NULL;
	char *dest = NULL;
	int result = 0;
	
	getcwd(cwd, sizeof(cwd));

	/* 異常ケース(ソースファイルなし) */
	src  = gpfCatFile( cwd, "cfg", "getperf.ini", NULL );
	dest = gpfCatFile( "/", "getperf.ini", NULL );
	result = gpfCopyFile( src, dest );
	CU_ASSERT( result == 0 );
	gpfFree( src );
	gpfFree( dest );
	
	/* 異常ケース(ターゲットファイルなし) */
	src  = gpfCatFile( cwd, "hogehoge.ini", NULL );
	dest = gpfCatFile( cwd, "hogehoge2.ini", NULL );
	result = gpfCopyFile( src, dest );
	CU_ASSERT( result == 0 );
	gpfFree( src );
	gpfFree( dest );
	
	/* 正常ケース */
	src  = gpfCatFile( cwd, "cfg", "getperf.ini", NULL );
	dest = gpfCatFile( cwd, "cfg", "copy_test.ini", NULL );
	result = gpfCopyFile( src, dest );
	CU_ASSERT( result == 1 );
	gpfFree( src );
	gpfFree( dest );
}

/**
 * ワークファイルの読み込み
 * @param config エージェント構造体
 * @param filename ファイル名
 * @param result バッファ
 * @param maxRows 最大行数
 * @return 合否
 */
void test_gpf_common_024(void)
{
	char cwd[MAXFILENAME];
	GPFConfig *config = NULL;
	char *buf         = NULL;
	int number        = 0;
	int result        = 0;
	
	getcwd(cwd, sizeof(cwd));
	config = gpfCreateConfig("hoge", cwd, "test", "testpath", cwd, "getperf.ini");
	printf("work : %s\n", config->workDir );

	/* 全行読込み */
	result = gpfReadWorkFile( config, "_test01.txt", &buf );
	CU_ASSERT( result == 1 && strcmp(buf,
		"this is a test 01\nthis is a test 02\nthis is a test 03\nthis is a test 04\nthis is a test 05\n" )
		== 0 );
	gpfFree( buf );
	
	/* 指定行読込み */
	result = gpfReadWorkFileHead( config, "_test01.txt", &buf, 2 );
	CU_ASSERT( result == 1 && strcmp(buf,
		"this is a test 01\nthis is a test 02\n" )
		== 0 );
	gpfFree( buf );

	/* オーバーフロー 、エラーにはならずに MAX_BUF_LENまで読み込む */
	result = gpfReadWorkFile( config, "_overflow01.txt", &buf );
	printf("result = %d, buf = %d\n", result, strlen( buf ));
	CU_ASSERT( result == 1 && buf != NULL );
	gpfFree( buf );

	/* 読込みファイルなし */
	result = gpfReadWorkFile( config, "_hogehoge.txt", &buf );
	CU_ASSERT( result == 0 && buf == NULL );

	/* 数値ファイル読込み */
	result = gpfReadWorkFileNumber( config, "_num01.txt", &number );
	CU_ASSERT( result == 1 && number == 123456789 );
	
	/* 数値ファイル読込み */
	result = gpfReadWorkFileNumber( config, "_num02.txt", &number );
	CU_ASSERT( result == 1 && number == 1234 );
	
	gpfFreeConfig(&config);

}

/**
 * ワークファイルへの数値の書き込み。ファイル名が'_'で始まる場合は共有ディレクトリ_wkに保存し、そうでない場合はローカルディレクトリ_wk/_{pid}に保存する
 * @param config エージェント構造体
 * @param filename ファイル名
 * @param num 数値
 * @return 合否
 */
void test_gpf_common_025(void)
{
	char cwd[MAXFILENAME];
	GPFConfig *config = NULL;
	char *buf         = NULL;
	int number        = 0;
	int result        = 0;
	
	getcwd(cwd, sizeof(cwd));
	config = gpfCreateConfig("hoge", cwd, "test", "testpath", cwd, "getperf.ini");

	result = gpfWriteWorkFile( config, "_write01.txt", "this is a test" );
	CU_ASSERT( result == 1 );
	
	result = gpfReadWorkFile( config, "_write01.txt", &buf );
	CU_ASSERT( result == 1 && strcmp(buf, "this is a test" ) == 0 );
	gpfFree( buf );

	result = gpfWriteWorkFileNumber( config, "_write01.txt", 123456789 );
	CU_ASSERT( result == 1 );
	
	result = gpfReadWorkFile( config, "_write01.txt", &buf );
	CU_ASSERT( result == 1 && strcmp(buf, "123456789" ) == 0 );
	gpfFree( buf );
	gpfFreeConfig(&config);
}

/**
 * ディレクトリの作成。親ディレクトリが存在しない場合は順次作成する。
 *  int gpfMakeDirectory( char * newdir )
 * @param   *newdir ディレクトリパス
 * @return  合否
 */
void test_gpf_common_026(void)
{
	char cwd[MAXFILENAME];
	GPFConfig *config = NULL;
	char *buf         = NULL;
	char *path        = NULL;
	char *path2       = NULL;
	int result        = 0;
	
	getcwd(cwd, sizeof(cwd));
	config = gpfCreateConfig("hoge", cwd, "test", "testpath", cwd, "getperf.ini");

	path   = gpfCatFile( config->workDir, "new_dir", "20150830", "172000", NULL );
	path2  = gpfCatFile( config->workDir, "new_dir", NULL );
	printf("dir=%s\n", path);
	result = gpfMakeDirectory( path );
	CU_ASSERT( result == 1);
	result = gpfWriteWorkFileNumber( config, "val01.txt", 123456789 );
	CU_ASSERT( result == 1 );
	result = gpfReadWorkFile( config, "val01.txt", &buf );
	CU_ASSERT( result == 1 && strcmp(buf, "123456789" ) == 0 );
	result = gpfRemoveDir( path2 );
	CU_ASSERT( result == 1);
	result = gpfRemoveWorkDir( config );
	CU_ASSERT( result == 1);

	gpfFree( buf );
	gpfFree( path );
	gpfFree( path2 );
	gpfFreeConfig(&config);
}

/**
 * コピー元からコピー先への上書きコピー
 * (ディレクトリの場合はその下のファイルを全てコピーする)
 * int gpfBackupConfig( char *srcDir, char *targetDir, char *filename )
 * @param srcDir ソースディレクトリ
 * @param targetDir ターゲットディレクトリ
 * @param filename ファイル名
 * @return 合否
 */
void test_gpf_common_027(void)
{
	char cwd[MAXFILENAME];
	GPFConfig *config = NULL;
	char *buf         = NULL;
	char *path        = NULL;
	int number        = 0;
	int result        = 0;
	
	getcwd(cwd, sizeof(cwd));
	config = gpfCreateConfig("hoge", cwd, "test", "testpath", cwd, "getperf.ini");

	result = gpfBackupConfig( config->workCommonDir, config->workDir, "arc" );
	CU_ASSERT( result == 1 );

	path = gpfCatFile( "arc", "test03.txt", NULL );
	result = gpfReadWorkFile( config, path, &buf );
	CU_ASSERT( result == 1 && 
		strcmp(buf, "this is a test 1\nthis is a test 2\nthis is a test 3\n" ) == 0 );
	result = gpfRemoveWorkDir( config );
	CU_ASSERT( result == 1);

	gpfFree( buf );
	gpfFree( path );
	gpfFreeConfig(&config);
}

void test_gpf_common_028(void)
{
}

void test_gpf_common_029(void)
{
}

void test_gpf_common_030(void)
{
}

