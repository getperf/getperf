/* 
** GETPERF
** Copyright (C) 2014-2016, Minoru Furusawa, Toshiba corporation.
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

#include "gpf_config.h"
#include "gpf_common.h"
#include "gpf_log.h"
#include "mutexs.h"

static ZBX_MUTEX logFileAccessFlag = 0;
GPFConfig   *GCON = NULL;

/**
 * ログローテーション
 * クリティカルセクション内の処理であり、多重ロックを回避するため
 * ログ出力は記述不可
 * @param logPath ログファイルパス
 * @param logSize ログサイズ(KB)
 * @param logRotation 世代数
 * @return 合否
 */
int gpfLogRotate( char *logPath, int logSize, int logRotation )
{
	int         rc = 0;
	int         idx;
	struct stat stats;
	char        *srcPath  = NULL;
	char        *destPath = NULL;
	int         maxLogSize = 0;

	if ( logRotation <= 1 || stat( logPath, &stats) != 0)
		return 1;
	
	maxLogSize = logSize;

	/* ログ世代の古い順にログローテーション */
	if (stats.st_size < maxLogSize)
		return 1;

	idx = logRotation;
	while (idx >= 0) 
	{
		idx --;
		
		destPath = gpfDsprintf(destPath, "%s.%d", logPath, idx);

		if (idx == (logRotation - 1) ) 
		{
			unlink(destPath);
		}

		if (idx == 0)
			srcPath = gpfDsprintf(srcPath, "%s", logPath);
		else
			srcPath = gpfDsprintf(srcPath, "%s.%d", logPath, idx - 1);
		
		if ( stat( srcPath, &stats) == 0)
		{
			if ( rename( srcPath, destPath ) == -1)
				goto errange;
		}
	}

	rc = 1;

	errange:
	gpfFree(srcPath);
	gpfFree(destPath);

	return rc;
}

/**
 * ロギングインスタンスの初期化。セマフォとインスタンス変数の初期化
 * @param config エージェント構造体
 * @param module モジュール
 * @return 合否
 */
int gpfOpenLog( GPFConfig *config, char *module)
{
	FILE *file = NULL;
	GPFLogConfig *logConfig = config->logConfig;
	char *logPath;
	if (!gpfSwitchLog(config, module, NULL))
		return gpfError("log switch error");

	gpfMakeDirectory( logConfig->logDir );
	if(!zbx_mutex_create_force(&logFileAccessFlag, ZBX_MUTEX_LOG))
		gpfFatal("Unable to create mutex for log file");

	logConfig->lockOk = 1;
	logPath = logConfig->logPath;
	if( (file = fopen(logPath, "a+")) == NULL)
		return gpfSystemError("%s", logPath);
	fclose(file);

	return 1;
}

/**
 * ログインスタンスのスイッチ
 * @param config エージェント構造体
 * @param module モジュール
 * @param statName 採取種別
 * @return 合否
 */
int gpfSwitchLog( GPFConfig *config, char *module, char *statName)
{
	char *logId   = NULL;
	char *logFile = NULL;
	char *logPath = NULL;
	GPFSchedule *schedule   = config->schedule;
	GPFLogConfig *logConfig = config->logConfig;
	char *logDir = logConfig->logDir;

	if (schedule == NULL)
		return gpfError("schedule is null");

	/* 設定ファイルからログ関連パラメータをセット */
	logConfig->logLevel    = schedule->logLevel;
	logConfig->showLog     = schedule->debugConsole;
	logConfig->logSize     = schedule->logSize;
	logConfig->logRotation = schedule->logRotation;
	logConfig->iniFlag     = 1;

	/* モジュールが設定されていない場合はログパスの初期化をせずに戻る */
	if ( module == NULL)
		return 1;
	
	/* ログファイル名を「モジュール{_種別}.log」にセット */
	if (statName != NULL)
		logId = gpfDsprintf(logId, "%s_%s", module, statName);
	else
		logId = gpfDsprintf(logId, "%s", module);

	logFile = gpfDsprintf(logFile, "%s.log", logId);
	
	gpfFree(logConfig->module);
	logConfig->module  = logId;
	gpfFree(logConfig->logFile);
	logConfig->logFile = logFile;
	
	/* ログディレクトリを {HOME}/_log に設定 */
	if (logDir == NULL && config->home != NULL)
	{
		logDir = gpfCatFile(config->home, "_log", NULL);
		gpfFree(logConfig->logDir);
		logConfig->logDir = logDir;
	}
	
	if (logDir == NULL)
		return gpfError("log directory path is null");

	logPath = gpfCatFile(logDir, logFile, NULL);
	gpfFree(logConfig->logPath);
	logConfig->logPath = logPath;

	return 1;
}

/**
 * ログファイルのクローズ
 * @param config エージェント構造体
 * @return 合否
 */
void gpfCloseLog( GPFConfig *config)
{
	GPFLogConfig *logConfig = config->logConfig;
	char *logDir = logConfig->logDir;

	gpfFree(logConfig->module);
	gpfFree(logConfig->logFile);
	gpfFree(logConfig->logDir);
	gpfFree(logConfig->logPath);
	
	zbx_mutex_destroy(&logFileAccessFlag);
}

/**
 * ログ出力
 * @param src マクロ(ソース名)
 * @param lno マクロ(行数)
 * @param func マクロ(関数名)
 * @param level エラーレベル
 * @param format フォーマット

 * @return 合否
 */
int _gpfLog(const char *src, const int lno, const char *func, int level, char *format, ...)
{
	char      *logPath    = NULL;
	int       logLevel    = GPF_INFO;
	int       showLog     = 1;
	int       logSize     = 100;
	int       logRotation = 5;
	int       lockOk      = 0;
	FILE      *file       = NULL;
	
	va_list	args;
	char timeStamp[MAX_STRING_LEN], head[MAX_STRING_LEN], body[MAX_STRING_LEN];
	
	char *logLabel[] = {
		LOG_STR_WARN,
		LOG_STR_NOTICE,
		LOG_STR_INFO,
		LOG_STR_DEBUG
	};
	GPFLogConfig *logConfig = NULL;

	gpfGetCurrentTime(0, timeStamp, GPF_DATE_FORMAT_DEFAULT);

	/* エージェントでログ構成が定義されていれば、その設定に従う。設定されていない場合は標準出力する */
	if (GCON != NULL && GCON->logConfig != NULL)
	{
		logConfig   = GCON->logConfig;
		logPath     = logConfig->logPath;
		logLevel    = logConfig->logLevel;
		showLog     = logConfig->showLog;
		logSize     = logConfig->logSize;
		logRotation = logConfig->logRotation;
		lockOk      = logConfig->lockOk;
		
		if (logLevel < level)
			return 1;
	}
	else
	{
		if (GPF_DEFAULT_LOG_LEVEL < level)
			return 1;
	}
	/* ヘッダ(ソース、行数、関数、ログレベル)登録 */
	gpfSnprintf( head, MAX_STRING_LEN, "[%s:%d][%s:%s]" , src, lno, func, logLabel[level - GPF_WARN]);
	/* gpfSnprintf( head, MAX_STRING_LEN, "%s:%d[%s]" , src, lno, logLabel[level - GPF_WARN]);	*/

	va_start(args, format);
	vsnprintf( &body[0], MAX_STRING_LEN, format, args);
	va_end(args);

	/* 排他ロックをかけてログ出力。セクション内は新たなログ出力不可 */
	if (logPath != NULL)
	{
		if ( lockOk )
			zbx_mutex_lock(&logFileAccessFlag);

		if ( gpfLogRotate( logPath, logSize, logRotation ) == 0)
		{
			goto errange;
		}
		if( (file = fopen(logPath, "a+")) == NULL)
		{
			goto errange;
		}
		fprintf(file, "%s %s %s\n", timeStamp, head, body);
		fclose(file);

		errange:
		if ( lockOk )
			zbx_mutex_unlock(&logFileAccessFlag);
	}

	if (GCON->daemonFlag == 0 && level <= GPF_NOTICE)
	{
		printf("%s\n", body);
	}
	if (showLog)
		printf("%s %s\n", head, body);

	return (int)1;
}

/**
 * エラーログ出力
 * @param src マクロ(ソース名)
 * @param lno マクロ(行数)
 * @param func マクロ(関数名)
 * @param level エラーレベル
 * @param systemFlag システムエラーメッセージ出力フラグ
 * @param exitFlag 終了フラグ
 * @param code コード
 * @param format フォーマット

 * @return 合否
 */
int _gpfLogError(const char *src, const int lno, const char *func, 
	int level, int systemFlag, int exitFlag, char *format, ...)
{
	char    *logPath      = NULL;
	int     logLevel      = GPF_ERR;
	int     showLog       = 1;
	int     logSize       = 100;
	int     logRotation   = 5;
	FILE    *file         = NULL;
	char    *systemError  = NULL;  
	va_list	args;
	char timeStamp[MAX_STRING_LEN], head[MAX_STRING_LEN], body[MAX_STRING_LEN];
	
	char *logLabel[] = {
		LOG_STR_FATAL,
		LOG_STR_CRIT,
		LOG_STR_ERR,
	};
	GPFLogConfig *logConfig = NULL;

	gpfGetCurrentTime(0, timeStamp, GPF_DATE_FORMAT_DEFAULT);

	/* エージェントでログ構成が設定されていれば、その設定に従う。設定されていない場合は標準出力する */
	if (GCON != NULL && GCON->logConfig != NULL)
	{
		logConfig   = GCON->logConfig;
		logPath     = logConfig->logPath;
		logLevel    = logConfig->logLevel;
		showLog     = logConfig->showLog;
		logSize     = logConfig->logSize;
		logRotation = logConfig->logRotation;

		if (logLevel < level)
			return 1;
	}

	if (systemFlag)
		systemError = gpfErrorFromSystem();
	
	gpfSnprintf( head, MAX_STRING_LEN, "[%s:%d][%s:%s]" , src, lno, func, logLabel[level - 1]);
	/* gpfSnprintf( head, MAX_STRING_LEN, "%s:%d[%s]" , src, lno, logLabel[level - GPF_WARN]); */

	va_start(args, format);
	vsnprintf( &body[0], MAX_STRING_LEN, format, args);
	va_end(args);

	/* システムエラーメッセージを追加してログ出力 */
	if (logPath != NULL)
	{
		zbx_mutex_lock(&logFileAccessFlag);

		if ( gpfLogRotate( logPath, logSize, logRotation ) == 0)
		{
			goto errange;
		}

		if( (file = fopen(logPath, "a+")) == NULL)
		{
			goto errange;
		}

		if (systemError == NULL)
			fprintf(file, "%s %s %s\n", timeStamp, head, body);
		else
			fprintf(file, "%s %s %s : %s\n", timeStamp, head, body, systemError);

		fclose(file);

		errange:
			zbx_mutex_unlock(&logFileAccessFlag);
	}

	if (GCON == NULL || GCON->daemonFlag == 0 )
	{
		if (systemError == NULL)
			printf("%s\n", body);
		else
			printf("%s : %s\n", body, systemError);
	}
	else
	{
		if (showLog)
			if (systemError == NULL)
				printf("%s %s\n", head, body);
			else
				printf("%s %s : %s\n", head, body, systemError);
	}
	
	if (exitFlag)
		exit(-1);
	
	return (int)0;
}

/**
 * コンソールログ出力
 * @param commonFormat 共通フォーマット
 * @param localeFormat 地域別フォーマット

 * @return 合否
 */
int gpfMessage( char *commonFormat, char *localFormat, ...)
{
	char body[MAX_STRING_LEN];
	va_list	args;
	va_start(args, localFormat);
	if (GCON != NULL && GCON->localeFlag == 0)
		vsnprintf( &body[0], MAX_STRING_LEN, commonFormat, args);
	else
		vsnprintf( &body[0], MAX_STRING_LEN, localFormat, args);
	va_end(args);

	printf("%s\n", body);
	return 1;
}

/**
 * コンソールログ出力(OK, NG)
 * @param okng 0:NG,1:OK
 * @return 合否
 */
int gpfMessageOKNG( int okng )
{
#if defined(WIN32)

	HANDLE hStdOut = GetStdHandle(STD_OUTPUT_HANDLE);
	CONSOLE_SCREEN_BUFFER_INFO ScreenInfo;
	COORD pos;
	if (!GetConsoleScreenBufferInfo( hStdOut, &ScreenInfo )) 
		return 0;

	pos.X = 60;
	pos.Y = ScreenInfo.dwCursorPosition.Y;
	SetConsoleCursorPosition( hStdOut, pos );

	if ( okng == 1)
	{
		SetConsoleTextAttribute( hStdOut, FOREGROUND_INTENSITY|FOREGROUND_GREEN );
		printf("OK\n");
	}
	else
	{
		SetConsoleTextAttribute( hStdOut, FOREGROUND_INTENSITY|FOREGROUND_RED );
		printf("NG\n");
	}

	SetConsoleTextAttribute( hStdOut, ScreenInfo.wAttributes );
	
#else

	if ( okng == 1)
	{
		printf("\033[60G\033[32;1m");
		printf("OK\n");
	}
	else
	{
		printf("\033[60G\033[31;1m");
		printf("NG\n");
	}
	printf("\033[0m");

#endif
	gpfInfo( (okng == 1) ? "OK":"NG" );

	return 1;
}

/**
 * コンソールログ出力(改行なし)
 * @param commonFormat 共通フォーマット
 * @param localeFormat 地域別フォーマット
 * @return 合否
 */
int gpfMessageCROff( char *commonFormat, char *localFormat, ...)
{
	char body[MAX_STRING_LEN];
	va_list	args;
	va_start(args, localFormat);
	if (GCON != NULL && GCON->localeFlag == 0)
		vsnprintf( &body[0], MAX_STRING_LEN, commonFormat, args);
	else
		vsnprintf( &body[0], MAX_STRING_LEN, localFormat, args);
	va_end(args);

	fputs(body, stdout);
	return 1;
}

/**
 * システムエラーメッセージ
 *
 * @return  メッセージ文字列
 */

char *gpfErrorFromSystem()
{
#if defined(WIN32)
	unsigned long error = 0;
	static char buffer[MAX_STRING_LEN];

	memset(buffer, 0, sizeof(buffer));

	if(FormatMessage(
		FORMAT_MESSAGE_FROM_SYSTEM, 
		NULL, 
		GetLastError(),
		MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), 
		buffer, 
		sizeof(buffer), 
		NULL) == 0)
	{
		gpfSnprintf(buffer, sizeof(buffer), "error code [0x%X]", GetLastError());
	}

	return buffer;
#else

	return strerror(errno);
#endif
}
