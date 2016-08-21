/* 
** GETPERF
** Copyright (C) 2015-2016, Minoru Furusawa, Toshiba corporation.
**
** This program is free software; you can redistribute it and/or modify
** it under the terms of the GNU General Public License as published by
** the Free Software Foundation; either version 2 of the License, or
** (at your option) any later version.
**
** This program is distributed in the hope that it will be useful,
** but WITHOUT ANY WARRANTY; without even the implied warranty of
** MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
** GNU General Public License for more details.
**
** You should have received a copy of the GNU General Public License
** along with this program; if not, write to the Free Software
** Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
**/

/*
 * Function: strlcpy, strlcat
 * Copyright (c) 1998 Todd C. Miller <Todd.Miller@courtesan.com>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

#ifndef GETPERF_GPF_COMMON_H
#define GETPERF_GPF_COMMON_H

#include "gpf_config.h"

#if defined(_WINDOWS)
#define GPF_OSNAME        "Windows"
#define GPF_OSTAG         "Windows"
#define GPF_OSTYPE        "Windows"
#define GPF_ARCH          "Win32"
#define GPF_MODULE_TAG    "Windows-Win32"
#else
#if defined(__linux)

#include "gpf_common_linux.h"

/*
#define GPF_OSNAME        "CentOS6"
#define GPF_OSTAG         "UNIX"
#define GPF_OSTYPE        "Linux"
#define GPF_ARCH          "x86_64"
#define GPF_MODULE_TAG    "CentOS6-x86_64"
*/
#elif defined(__FreeBSD__)
#define GPF_OSNAME        "FreeBSD8"
#define GPF_OSTAG         "UNIX"
#define GPF_OSTYPE        "FreeBSD"
#define GPF_ARCH          "amd64"
#define GPF_MODULE_TAG    "FreeBSD8-amd64"
#else
#define GPF_OSNAME      "Unknown"
#define GPF_OSTAG       "Unknown"
#define GPF_OSTYPE      "Unknown"
#define GPF_ARCH        "x86_64"
#define GPF_MODULE_TAG  "Unknown"
#endif

#endif

#if defined(_WINDOWS)
#define GPF_GETPERF       "getperf.exe"
#define GPF_GETPERF_BASE  "getperf.exe"
#define GPF_GETPERFZIP    "getperfzip.exe"
#define GPF_GETPERFSOAP   "getperfsoap.exe"
#define GPF_GETPERFCTL    "getperfctl.exe"
#define GPF_DEPLOY_SCRIPT "gpfDeployModule.bat"
#else
#define GPF_GETPERF       "getperf"
#define GPF_GETPERF_BASE  "_getperf"
#define GPF_GETPERFZIP    "getperfzip"
#define GPF_GETPERFSOAP   "getperfsoap"
#define GPF_GETPERFCTL    "getperfctl"
#define GPF_DEPLOY_SCRIPT "gpfDeployModule.pl"
#endif

#define APPLICATION_NAME  "GETPERF Agent"
#define GPF_MAJOR_VER     2
#define GPF_VERSION       "2.12.0"
#define GPF_BUILD         8
#define GPF_BUILD_DATE    "20160716.16.00"

#define GETPERF_PROC_TITLE  "getperf"
#define GPF_TITLE_SIZE  10

/*
#ifndef(_WINDOWS)
#define MAX_COMPUTERNAME_LENGTH 1024
#endif 
*/
/* _WINDOWS */

#if defined(_WINDOWS)
#define GPF_CURRENT_PATH    ".\\"
#define GPF_PARENT_PATH     "..\\"
#define GPF_FILE_SEPARATOR  '\\'
#define GPF_FILE_SEPARATORS "\\"
#define GPF_LINE_SEPARATORS "\r\n"
#else
#define GPF_CURRENT_PATH    "./"
#define GPF_PARENT_PATH     "../"
#define GPF_FILE_SEPARATOR  '/'
#define GPF_FILE_SEPARATORS "/"
#define GPF_LINE_SEPARATORS "\n"
#define MAX_COMPUTERNAME_LENGTH 1024
#endif /* _WINDOWS */

#if defined(__linux)
#define GPF_OS_TAG  "UNIX"
#define GPF_OS_NAME "Linux"
#elif defined(__sun)
#define GPF_OS_TAG  "UNIX"
#define GPF_OS_NAME "Solaris"
#elif defined(__hpux)
#define GPF_OS_TAG  "UNIX"
#define GPF_OS_NAME "HP-UX"
#elif defined(__FreeBSD__)
#define GPF_OS_TAG  "UNIX"
#define GPF_OS_NAME "FreeBSD"
#elif defined(_AIX)
#define GPF_OS_TAG  "UNIX"
#define GPF_OS_NAME "AIX"
#elif defined(__WIN32)
#define GPF_OS_TAG  "Windows"
#define GPF_OS_NAME "Windows"
#elif defined(__WIN64)
#define GPF_OS_TAG  "Windows"
#define GPF_OS_NAME "Windows"
#elif defined(WIN32)
#define GPF_OS_TAG  "Windows"
#define GPF_OS_NAME "Windows"
#else
#define GPF_OS_TAG  "Unknown"
#define GPF_OS_NAME "Unknown"
#endif

#include "lc_message/default.h"
#if defined(__linux)
#include "lc_message/ja_JP.UTF-8.h"
#elif defined(__sun)
#include "lc_message/ja_JP.EUC_JP.h"
#elif defined(__hpux)
#include "lc_message/ja_JP.EUC_JP.h"
#elif defined(__FreeBSD__)
#include "lc_message/ja_JP.EUC_JP.h"
#elif defined(_AIX)
#include "lc_message/ja_JP.Shift_JIS.h"
#elif defined(_WINDOWS)
#include "lc_message/ja_JP.Shift_JIS.h"
#endif

#if defined(__FreeBSD__)
#define HAVE_SEMUN 1
#endif
#define USE_FILE32API 1

#define GPF_CFG_LTRIM_CHARS "\t "
#define GPF_CFG_RTRIM_CHARS GPF_CFG_LTRIM_CHARS "\r\n\0"
#define GPF_CFG_RTRIM_CHARS_SLASH GPF_CFG_RTRIM_CHARS "/"

#define MAX_STRING_LEN  2048
#define MAX_USERNAME_LEN  256
#define MAX_BUF_LEN 65536

#define WRITEBUFFERSIZE (16384)
#define MAXFILENAME (1024)

#ifndef MAX
#   define MAX(a, b) ((a)>(b) ? (a) : (b))
#endif

#ifndef MIN
#   define MIN(a, b) ((a)<(b) ? (a) : (b))
#endif

#define GPF_POLLER_INTERVAL 5

#define GPF_MAX_COLLECTORS 20
#define GPF_MAX_WORKERS 100

#define GPF_SOAP_CONNECT_TIMEOUT 30
#define GPF_SOAP_SEND_TIMEOUT 300
#define GPF_SOAP_RECV_TIMEOUT 300
#define GPF_SOAP_RETRY 3
#define GPF_SOAP_URL_SUFFIX "/axis2/services/GetperfService"

#define GPF_CHECK_LICENSE_CNT      3
#define GPF_CHECK_LICENSE_INTERVAL 5
#define GPF_CHECK_EXPIRED_TIME     604800  /* 7 day */

#define EXIT_TIMEOUT_SCHEDULER 30
#define EXIT_TIMEOUT_COLLECTOR 30
#define EXIT_TIMEOUT_WORKER    3600

#define GPF_HANODE_CMD_TIMEOUT 30
#define GPF_ZIP_CMD_TIMEOUT    300
#define GPF_SOAP_CMD_TIMEOUT   30

#define GPF_VERSION_CMD_TIMEOUT 30
#define GPF_VERIFY_CMD_TIMEOUT  90
#define VERIFY_CMD_INTERVAL "2"
#define VERIFY_CMD_INTERVAL "2"
#define VERIFY_CMD_COUNT    "2"

#define MIN_GETPERF_PORT 1024u
#define MAX_GETPERF_PORT 65535u

#define GPF_DATE_FORMAT_DEFAULT         0
#define GPF_DATE_FORMAT_YYYYMMDD        1
#define GPF_DATE_FORMAT_HHMISS          2
#define GPF_DATE_FORMAT_YYYYMMDD_HHMISS 3
#define GPF_DATE_FORMAT_DIR             4

/*
 * Wrapper
 */

#define strscpy(x,y)    gpfStrlcpy(x,y,sizeof(x))
#define strnscpy(x,y,n) gpfStrlcpy(x,y,n);
#define gpfRealloc(old, size) _gpfRealloc2(__FILE__, __LINE__, old , size)
#define gpfMalloc(old, size)  _gpfMalloc2(__FILE__, __LINE__, old , size)

#if defined(_WINDOWS)
#define gpfGetUserName(x,y)    GetUserName(x,(LPDWORD)y)
#else
#define gpfGetUserName(x,y)    getlogin_r(x,y)
#endif

/*
 * Windows memory leak check
 */

#if defined(_WINDOWS)
#	define _CRTDBG_MAP_ALLOC
#	include <crtdbg.h>

#	define REINIT_CHECK_MEMORY() \
		_CrtMemCheckpoint(&oldMemState)

#	define INIT_CHECK_MEMORY() \
		char DumpMessage[0x1FF]; \
		_CrtMemState  oldMemState, newMemState, diffMemState; \
		REINIT_CHECK_MEMORY()

#	define CHECK_MEMORY(fncname, msg) \
		DumpMessage[0] = '\0'; \
		_CrtMemCheckpoint(&newMemState); \
		if(_CrtMemDifference(&diffMemState, &oldMemState, &newMemState)) \
		{ \
			gpfSnprintf(DumpMessage, sizeof(DumpMessage), \
				"%s\n" \
				"free:  %10li bytes in %10li blocks\n" \
				"normal:%10li bytes in %10li blocks\n" \
				"CRT:   %10li bytes in %10li blocks\n", \
				 \
				fncname ": Memory changed! (" msg ")\n", \
				 \
				(long) diffMemState.lSizes[_FREE_BLOCK], \
				(long) diffMemState.lCounts[_FREE_BLOCK], \
				 \
				(long) diffMemState.lSizes[_NORMAL_BLOCK], \
				(long) diffMemState.lCounts[_NORMAL_BLOCK], \
				 \
				(long) diffMemState.lSizes[_CRT_BLOCK], \
				(long) diffMemState.lCounts[_CRT_BLOCK]); \
		} \
		else \
		{ \
			gpfSnprintf(DumpMessage, sizeof(DumpMessage), \
					"%s: Memory OK! (%s)", fncname, msg); \
		} \
		fprintf(stderr, "MEMORY_LEAK: %s", DumpMessage); fflush(stderr)
#else
#	define INIT_CHECK_MEMORY() ((void)0)
#	define CHECK_MEMORY(fncname, msg) ((void)0)
#endif

/**
 * Free memory, if pointer is not NULL
 */
#define gpfFree(ptr)		\
	if (ptr)		\
	{			\
		free(ptr);	\
		ptr = NULL;	\
	}

/**
 * Close file pointer, if pointer is not NULL
 */
#define gpf_fclose(f) { if(f){ fclose(f); f = NULL; } }

/**
 * malloc() extention. old shuld not be null
 */
void *_gpfMalloc2(char *filename, int line, void *old, size_t size);

/**
 * realloc() extention
 */
void *_gpfRealloc2(char *filename, int line, void *src, size_t size);

/**
 * vsnprintf() extention. Add '\0' character to last
 */
int gpfSnprintf(char* str, size_t count, const char *fmt, ...);

/**
 * Replace string
 */
char *gpfStringReplace(char *str, char *src, char *dest);

/**
 * Trim right null character
 */
void gpfRtrim(char *str, const char *charlist);

/**
 * Trim left null character
 */
void gpfLtrim(char *str, const char *charlist);

/**
 * Trim left and right null character
 */
void gpfLRtrim(char *str, const char *charlist);

/**
 * Remove null caracter
 */
void gpfRemoveChars(char *str, const char *charlist);

/**
 * strncpy() extention. Copy string from src to dst, Add '\0' to last.
 */
size_t gpfStrlcpy(char *dst, const char *src, size_t siz);

/**
 * strncat() extention
 */
size_t gpfStrlcat(char *dst, const char *src, size_t siz);

/**
 * vsnprintf() extention
 */
 char* gpfDsprintf(char *dest, const char *f, ...);

/**
 * strncat() extention
 */
char* gpfStrdcat(char *dest, const char *src);

/**
 * 文字列の分割
 * @param n      分割数
 * @param sep    連結文字
 * @param string 対象文字列
 * @return 分割後の文字列配列
 */
char **gpfSplit(int *n, char *sep, char *string);

/** 文字列の比較
 *
 * @param   a 比較する文字列
 * @param   b 比較する文字列
 *
 * @return  aの方が大きい場合は負数、bのほうが大きい場合は整数、aとbが同じ場合は0
 */
int gpfCompareString( const void* a, const void* b );

/** 文字列配列の初期化
 *
 * @return 文字列配列構造体のポインタ
 */
GPFStrings *gpfCreateStrings();

/** 文字列配列のメモリ開放
 *
 * @param   gs 文字列配列構造体のポインタ
 */
void gpfFreeStrings(GPFStrings *gs);

/** 文字列配列構造体に文字列を挿入
 *
 * @param   gs 文字列配列構造体のポインタ
 * @param   str 文字列
 * @return  合否
 */
int gpfInsertStrings(GPFStrings *gs, char *str);

/**
 * ファイルパスを連結する
 * @param fmt   第一パス名
 * @param ...   可変長ファイルパス名
 * @return 連結後のパス
 */
char *gpfCatFile(const char *fmt, ...);

/**
 * 相対パスを絶対パスに変換します
 * @param path   変換対象パス
 * @param base   基準ディレクトリ
 * @param result 変換結果格納バッファ
 * @param size   バッファサイズ
 * @return 絶対パス
 */
char *rel2abs(const char *path, const char *base, char *result, const size_t size);

/**
 * ディレクトリの作成。親ディレクトリが存在しない場合は順次作成する。
 * @param   *newdir ディレクトリパス
 * @return  合否
 */
int gpfMakeDirectory( char * newdir );

/**
 * ホスト名の取得。「.」以降の文字列はカットし、大文字は小文字に変換する。
 * @param   *hostName ホスト名
 * @return  合否
 */

int gpfGetHostname (char *hostName);

/**
 * 実行パスから上位のディレクトリを絶対パスに変換して返す
 * @param inPath     入力パス
 * @param parentLevel 上位の階層の数
 * @return 変換後のパス
 */
char *gpfGetParentPathAbs( char *inPath, int parentLevel );

/**
 * ディレクトリの存在確認
 * @param path 指定ディレクトリ
 * @return 合否
 */
int gpfCheckDirectory( const char *path);

/**
 * ファイルのコピー
 * @param srcPath コピー元パス
 * @param targetPath コピー先パス
 * @return 合否
 */
int gpfCopyFile( const char *srcPath, const char *targetPath );

/**
 * ワークファイルの読み込み(先頭行のみ)
 * @param config エージェント構造体
 * @param filename ファイル名
 * @param buf バッファ
 * @param maxRows 最大行数
 * @return 合否
 */
int gpfReadWorkFileHead( GPFConfig *config, char *filename, char **buf, int maxRows);

/**
 * ワークファイルの読み込み(全行)
 * @param config エージェント構造体
 * @param filename ファイル名
 * @param buf バッファ
 * @return 合否
 */
int gpfReadWorkFile( GPFConfig *config, char *filename, char **buf);

/**
 * ワークファイルから数値の読み込み
 * @param config エージェント構造体
 * @param filename ファイル名
 * @param value 数値
 * @return 合否
 */
int gpfReadWorkFileNumber( GPFConfig *config, char *filename, int *num );

/**
 * ワークファイルの確認
 * @param config エージェント構造体
 * @param filename ファイル名
 * @return 合否
 */
int gpfCheckWorkFile( GPFConfig *config, char *filename );

/**
 * ワークファイルの削除
 * @param config エージェント構造体
 * @param filename ファイル名
 * @return 合否
 */
int gpfRemoveWorkFile( GPFConfig *config, char *filename );

/**
 * ワークファイルの読み込み
 * @param config エージェント構造体
 * @param filename ファイル名
 * @param buf バッファ
 * @param maxRows 最大行数
 * @return 合否
 */
int _gpfReadWorkFile( GPFConfig *config, char *filename, char **buf, int maxRows);

/**
 * ワークファイルへの数値の書き込み。ファイル名が'_'で始まる場合は共有ディレクトリ_wkに保存し、そうでない場合はローカルディレクトリ_wk/_{pid}に保存する
 * @param config エージェント構造体
 * @param filename ファイル名
 * @param num 数値
 * @return 合否
 */
int gpfWriteWorkFileNumber( GPFConfig *config, char *filename, int num );

/**
 * ワークファイルの書き込み。ファイル名が'_'で始まる場合は共有ディレクトリ_wkに保存し、
 * そうでない場合はローカルディレクトリ_wk/_{pid}に保存する
 * @param config エージェント構造体
 * @param filename ファイル名
 * @param buf バッファ
 * @return 合否
 */
int gpfWriteWorkFile( GPFConfig *config, char *filename, char *buf);

/**
 * ディレクトリの削除
 * @param dirPath ディレクトリパス
 *
 * @return 合否
 */
int gpfRemoveDir( char *dirPath );

/**
 * ワークディレクトリの削除

 * @return 合否
 */
int gpfRemoveWorkDir();

/**
 * 現在時刻の取得
 *
 * @return  浮動小数点の経過秒
 */
double	gpfTime(void);

/**
 * プロセスのタイトルを設定する
 * @param fmt フォーマット
 * @param ... 可変長引数
 */
void	gpfSetproctitle(const char *fmt, ...);

/** キー入力。入力がない場合は処理待ちしない
 *
 * @return  キー入力コード
 */
int gpfGetch();
 
/**
 * メッセージを出力し、1行入力する
 * @param commonFormat 英語メッセージ
 * @param localFormat 日本語メッセージ
 * @param result バッファ
 * @return 合否
 */
int gpfGetLine( char *commonFormat, char *localFormat, char **result);

/**
 * パスワードを入力する
 * @param commonFormat 英語メッセージ
 * @param localFormat 日本語メッセージ
 * @param result バッファ
 * @return 合否
 */
int gpfGetPass( char *commonFormat, char *localFormat, char **result);

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
int gpfGetCurrentTime( int sec, char *format, int type);

/**
 * 指定したフォーマット形式で時刻を変換
 * @param t 時刻
 * @param format フォーマット
 * @param type フォーマットタイプ
 *   GPF_DATE_FORMAT_DEFAULT         0
 *   GPF_DATE_FORMAT_YYYYMMDD        1
 *   GPF_DATE_FORMAT_HHMISS          2
 *   GPF_DATE_FORMAT_YYYYMMDD_HHMISS 3
 *   GPF_DATE_FORMAT_DIR             4
 * @return 合否
 */
int gpfGetTimeString( time_t t, char *format, int type);
int gpfDGetTimeString( char **format, int type, time_t t );

/**
 * 指定したディレクトリのディスク使用量[%]を取得
 * @param dir パス名
 * @param capacity ディスク使用率
 * @return 合否
 */
int gpfCheckDiskFree(char *dir, int *capacity);

/**
 * ディスク容量のチェック
 * @param config エージェント構造体
 * @return 合否
 */
int gpfCheckDiskUtil( GPFConfig *config);

/**
 * パスがホーム下を指定しているか、".."が含まれないかをチェックする
 * @param path パス名
 * @return 合否
 */
int gpfCheckPathInHome( GPFConfig *config, const char *path );

/**
 * ヘルプメッセージの出力
 */
void gpfUsage( char **msgs );

/**
 * 構成ファイルのバックアップ
 * @param srcDir ソースディレクトリ
 * @param targetDir ターゲットディレクトリ
 * @param filename ファイル名
 * @return 合否
 */
int gpfBackupConfig( char *srcDir, char *targetDir, char *filename);

#endif
