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
#include "gpf_logrt.h"
#include "gpf_regexp.h"

/**
 * ログファイルオフセットコンストラクター
 */
GPFLogStat *gpfCreateLogStat(char *logPath, long inode, long fsize, time_t upd)
{
	GPFLogStat *offset = NULL;
	offset = gpfMalloc(offset, sizeof(GPFLogStat));

	offset->fname = strdup(logPath);
	offset->inode = inode;
	offset->fsize = fsize;
	offset->upd   = upd;

	return offset;
}

/**
 * ログファイルオフセットコンストラクター(パス指定)
 */
GPFLogStat *gpfCheckLogStat(char *logPath)
{
	GPFLogStat *offset = NULL;
	struct stat sb;

	if ( stat( logPath, &sb ) == 0 )
	{
		offset = gpfCreateLogStat(logPath, sb.st_ino, sb.st_size, sb.st_mtime);
	}
	return offset;
}

/**
 * ログファイルオフセットデストラクター
 */
void gpfFreeLogStat( GPFLogStat **_offset )
{
	GPFLogStat *offset = _offset[0];
	
	if (_offset == NULL || offset == NULL)
		return;

	gpfFree( offset->fname );
	gpfFree( offset );

	*_offset = NULL;
}

#if defined _WINDOWS

/**
 * Windowsイベントログコンストラクター
 */
GPFEventLog *gpfCreateEventLog(unsigned long timestamp, char *source, 
	char *severeLabel, char *message, unsigned long	eventid)
{
	GPFEventLog *eventLog = NULL;
	eventLog = gpfMalloc(eventLog, sizeof(GPFEventLog));

	eventLog->timestamp   = timestamp;
	eventLog->source      = strdup(source);
	eventLog->severeLabel = strdup(severeLabel);
	eventLog->message     = strdup(message);
	eventLog->eventid     = eventid;

	return eventLog;
}

/**
 * Windowsイベントログデストラクター
 */
void gpfFreeEventLog( GPFEventLog **_eventLog )
{
	GPFEventLog *eventLog = _eventLog[0];
	
	if (_eventLog == NULL || eventLog == NULL)
		return;

	gpfFree( eventLog->source );
	gpfFree( eventLog->message );
	gpfFree( eventLog );

	*_eventLog = NULL;
}

#endif

/**
 * ログオフセット値(i-node,位置,更新時刻)の読み込み
 * @param config  エージェント構造体
 * @param logid   オフセットファイルID
 * @param logname オフセットファイル名
 * @return ログ状態構造体
 */
GPFLogStat *gpfLoadLogOffset( GPFConfig *config, char *logid, char *logname )
{
	GPFLogStat *offset = NULL;
	char *workFile = NULL;
	char *line     = NULL;
	char **vals    = NULL;
	char *filename = NULL;
	unsigned long inode = 0;
	unsigned long fsize = 0;
	time_t upd = 0;

	if ( logid )
		workFile = gpfDsprintf( workFile, "_%s_%s", logid, logname );
	else
		workFile = gpfDsprintf( workFile, "_logretrieve_%s", logname );

	if ( gpfReadWorkFile( config, workFile, &line ) == 1 )
	{
		int coln = 0;
		char *invalidValue = NULL;
		vals = gpfSplit( &coln, " ", line );
	
		if (vals != NULL && coln == 3) {
			inode = strtol(vals[0], &invalidValue, 10);  
			if (*invalidValue != '\0' )
				goto errata;
			fsize = strtol(vals[1], &invalidValue, 10);  
			if (*invalidValue != '\0' )
				goto errata;
			upd   = strtol(vals[2], &invalidValue, 10);  
			if (*invalidValue != '\0' )
				goto errata;
		}
	}
	offset = gpfCreateLogStat("", inode, fsize, upd);

errata:
	gpfFree(workFile);
	gpfFree(vals);
	gpfFree(line);

	return offset;
}

/**
 * ログオフセット値(i-node,位置,更新時刻)の書き込み
 * @param config エージェント構造体
 * @param offset ログ状態構造体
 * @param logid   オフセットファイルID
 * @param logname オフセットファイル名
 * @return 合否
 */
int gpfSaveLogOffset( GPFConfig *config, GPFLogStat *offset, char *logid, char *logname )
{
	int rc         = 1;
	char *workFile = NULL;
	char *line     = NULL;

	if ( logid )
		workFile = gpfDsprintf( workFile, "_%s_%s", logid, logname );
	else
		workFile = gpfDsprintf( workFile, "_logretrieve_%s", logname );

	gpfDebug("save offset %s", workFile);
	line = gpfDsprintf( line, "%ld %ld %ld", 
		offset->inode, offset->fsize, offset->upd );
	rc = gpfWriteWorkFile( config, workFile, line );
	gpfFree(line);
	gpfFree(workFile);

	return rc;
}

/**
 * ローテーションした1世代目のログファイルをチェックする。存在する場合はステータスをログ状態構造体に設定する
 * @param logdir ログディレクトリ
 * @param logname ログファイル名
 * @return ログ状態構造体
 */
#if defined _WINDOWS
GPFLogStat *gpfCheckRotatedLogFile( char *logdir, char *logname )
{
	char *searchPath = NULL;
	WIN32_FIND_DATA fd;
	HANDLE h;
	int fname_length   = strlen(logname);
	ULONGLONG updated  = 0;
	ULONGLONG fsize    = 0;
	ULONGLONG inode    = 0;
	char *rotated      = NULL;
	char *logPath      = NULL;
	GPFLogStat *offset = NULL;

	searchPath = gpfCatFile(logdir, "*", NULL);
    h = FindFirstFileEx(searchPath, FindExInfoStandard, &fd, 
    	FindExSearchNameMatch, NULL, 0);
	gpfFree(searchPath);

    if ( INVALID_HANDLE_VALUE == h ) 
	{
		gpfSystemError( "open %s", logdir );
		goto errata;
	}

	while ( FindNextFile( h, &fd ) )
	{
		/* ファイル名を前方一致してローテーションしたログを抽出する */
		if ( (strstr(fd.cFileName, logname)) != NULL)
		{
			HANDLE hFile;
			BY_HANDLE_FILE_INFORMATION fi;

			struct stat sb;
			char *targetPath = NULL;


			/* 同一ファイル名は現在のログファイルとしてスキップ */
			if (strlen(fd.cFileName) == fname_length)
				continue;

			/* 更新日付が最も新しいものを1世代目のログファイルとする */
			targetPath = gpfCatFile( logdir, fd.cFileName, NULL );
			hFile = CreateFile(targetPath, GENERIC_READ, FILE_SHARE_READ,
				NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
			if (hFile == INVALID_HANDLE_VALUE)
			{
				gpfSystemError( "open %s", targetPath);
			}

			if ( GetFileInformationByHandle(hFile, &fi) != 0)
			{
				FILETIME ft = fi.ftLastWriteTime;
				ULONGLONG utime;

				/* 更新日付が最も新しいファイルを候補とする */
				/* high,low の2変数を　64bit 符号ナシ整数として登録する　*/
				utime = (((ULONGLONG) ft.dwHighDateTime) << 32) + ft.dwLowDateTime;
				if ( utime > updated )
				{
					inode = (((ULONGLONG) fi.nFileIndexHigh) << 32) + fi.nFileIndexLow;	
					fsize = (((ULONGLONG) fi.nFileSizeHigh) << 32)  + fi.nFileSizeLow;
					updated = utime;
					gpfFree(rotated);
					rotated = strdup(fd.cFileName);
				}
			}
			CloseHandle(hFile);
			gpfFree(targetPath);
		}
	}
    FindClose( h );

	if ( !rotated )
		goto errata;

	logPath = gpfCatFile( logdir, rotated, NULL );
	offset  = gpfCreateLogStat( logPath, inode, fsize, updated );
	gpfDebug("inode=%llu,size=%llu,last=%llu : %s\n", 
		inode, fsize, updated, logPath);
errata:
	gpfFree(logPath);

	return offset;
}
#else 
GPFLogStat *gpfCheckRotatedLogFile( char *logdir, char *logname )
{
	DIR	*dir           = NULL;
	struct dirent *d   = NULL;
	int fname_length   = 0;
	long inode         = 0;
	long fsize         = 0;
	time_t updated     = 0;
	char *rotated      = NULL;
	char *logPath      = NULL;
	GPFLogStat *offset = NULL;
	struct stat	  sb;

	fname_length = strlen(logname);
	if ((dir = opendir( logdir )) == NULL ) 
	{
		gpfSystemError("open %s", logdir);
		goto errata;
	}

	while ((d = readdir(dir)) != NULL) 
	{
		/* ファイル名を前方一致してローテーションしたログを抽出する */
		if ( (strstr(d->d_name, logname)) != NULL)
		{
			char *targetPath;
			struct stat sb;

			/* 同一ファイル名は現在のログファイルとしてスキップ */
			if (strlen(d->d_name) == fname_length)
				continue;

			/* 更新日付が最も新しいものを1世代目のログファイルとする */
			targetPath = gpfCatFile( logdir, d->d_name, NULL );
			if ( stat( targetPath, &sb ) == 0 )
			{
				/* 更新日付が最も新しいファイルを候補とする */
				if (sb.st_mtime > updated) {
					updated = sb.st_mtime;
					inode   = sb.st_ino;
					fsize   = sb.st_size;
					rotated = d->d_name;
				}
			}
			gpfFree(targetPath);
		}
	}
	logPath = gpfCatFile( logdir, rotated, NULL );

	if ( closedir(dir) == -1) 
	{
		gpfSystemError("close %s", logdir);
		goto errata;
	}
	offset = gpfCreateLogStat(logPath, inode, fsize, updated);

errata:
	gpfFree(logPath);

	return offset;
}
#endif

/**
 * 前回読み取りからログファイルを差分読込みしてファイル保存する
 * ログローテーションしている場合は、１世代前のロググラフから読み込む
 * @param config エージェント構造体
 * @param logdir ログディレクトリ
 * @param logname ログファイル名
 * @param logid ログID(省略時はログファイル名とする)
 * @param regexp 正規表現キーワード
 * @param outDir 出力ディレクトリ
 * @return 合否
 */ 
int gpfRetrieveLog( GPFConfig *config, char *logdir, char *logname, char *logid, 
	char *regexp, char *outDir )
{
	int rc         = 0;
	GPFLogStat *offset     = NULL;
	GPFLogStat *rotated    = NULL;
	GPFLogStat *current    = NULL;
	int limitSize = 0;
	int row       = 0;
	char *res[GPF_LOG_SCAN_LIMIT_ROW];
	int i;
	char *outPath = NULL;
	char *outFile = NULL;
	char *logPath = gpfCatFile( logdir, logname, NULL );

	/* 結果データの初期化。サイズの制限とつけてローテーションさせる */
	for (i = 0; i < GPF_LOG_SCAN_LIMIT_ROW; i++)
	{
		res[i] = NULL;
	}

	/* 前回読み取りオフセットのロード */
	offset = gpfLoadLogOffset( config, logid, logname );

	/* 読み取り上限値の設定。前回オフセットが記録されていない場合は最小限のサイズを設定する */
	if ( offset->inode == 0 )
		limitSize = GPF_LOG_SCAN_FIRST_KB * 1024;
	else
		limitSize = GPF_LOG_SCAN_LIMIT_KB * 1024;

	/* カレントログファイルの読込 */
	if ( ( current = gpfCheckLogStat( logPath )) == NULL)
		goto errata;

	/* ローテーテッドログファイルの読込 */
	if ( (rotated = gpfCheckRotatedLogFile( logdir, logname )) != NULL) 
	{
		long fsize = rotated->fsize;

		/* オフセットのinodeが一致している場合のみ処理 */
		if ( offset->inode == rotated->inode ) {
			long pos = offset->fsize;
			if (pos < fsize) {
				long newpos = 0;
				/* 1世代前ログと、現在ログからリミットサイズを引いた値をログ読み取り下限値とする */
				long lowerLimit = rotated->fsize + current->fsize - limitSize;
				if ( pos < lowerLimit)
				{
					gpfError("Log scan limit exceed. Read %d KB", GPF_LOG_SCAN_LIMIT_KB);
					pos = lowerLimit;
				}

				if ((newpos = gpfLogTail(rotated->fname, pos, regexp, res, &row)) == -1)
					goto errata;

				rotated->fsize = newpos;
				gpfSaveLogOffset( config, rotated, logid, logname );
			}
		}
	}

	/* カレントログファイルの読込 */
	if ( current )
	{
		long newpos = -1;
		long pos = offset->fsize;

		/* 現在ログからリミットサイズを引いた値を読み取り下限値とする */
		long lowerLimit = current->fsize - limitSize;
		if (lowerLimit < 0)
			lowerLimit = 0;

		/* オフセットのinodeが一致していない場合ははじめから読む */
		if ( offset->inode != current->inode )
		{
			newpos = gpfLogTail(current->fname, lowerLimit, regexp, res, &row);
		}
		else if ( pos < current->fsize )
		{
			if ( pos < lowerLimit &&  offset->inode != 0 )
			{
				gpfError("Log scan limit exceed. Read %d KB", GPF_LOG_SCAN_LIMIT_KB);
				pos = lowerLimit;
			}

			newpos = gpfLogTail(current->fname, pos, regexp, res, &row);
		}
		else
		{
			rc = 1;
		}

		if ( newpos == -1 )
			goto errata;

		current->fsize = newpos;
		gpfSaveLogOffset( config, current, logid, logname );
	}

	if (row > GPF_LOG_SCAN_LIMIT_ROW)
		gpfError("Log scan limit exceed. Write %d row", GPF_LOG_SCAN_LIMIT_ROW);

	if ( logid )
		outFile = gpfDsprintf( outFile, "%s_%s", logid, logname );
	else
		outFile = gpfDsprintf( outFile, "%s", logname );

	outPath = gpfCatFile( outDir, outFile, NULL );
	rc = gpfSaveTailResult( outPath, res, &row);

errata:
	gpfFree(logPath);
	gpfFree(outPath);
	gpfFreeLogStat(&offset);
	gpfFreeLogStat(&rotated);
	gpfFreeLogStat(&current);

	return rc;
}

/**
 * 指定位置からログファイルを読込み正規表現によるキーワードフィルタリングをして結果を出力する
 * @param logPath ログファイルパス
 * @param pos 読み取り位置
 * @param regexp 正規表現キーワード
 * @param res 結果配列(ラウンドロビン)
 * @param row 結果行数
 * @return 読み取り後の位置(エラーの場合は-1)
 */ 
long gpfLogTail(char *logPath, long pos, char *regexp, char **res, int *row)
{
	FILE *logFile = NULL;
	char line[MAX_BUF_LEN];
	long newpos = -1;

	if( (logFile = fopen(logPath, "r")) == NULL)
	{
		gpfSystemError("%s", logPath);
		goto errata;
	}

	if ( fseek( logFile, pos, SEEK_SET ) != 0 ) 
	{
		gpfSystemError("%s", logPath);
		goto errata;
	}

	while ( fgets(line, MAX_BUF_LEN, logFile) != NULL )
	{
		int flag = 1;
		int len = 0;

		/* 正規表現を指定している場合はキーワードでフィルタリング */
		if ( regexp && gpf_regexp_match(line, regexp, &len) == NULL)
			flag = 0;

		if (flag == 1)
		{
			int pivot = *row % GPF_LOG_SCAN_LIMIT_ROW;
			if (*row > GPF_LOG_SCAN_LIMIT_ROW)
			{
				gpfFree(res[pivot]);
				res[pivot] = NULL;
			}
			res[pivot] = strdup(line);
			(*row) ++;
		}
		gpfDebug( "gofLogTail[%d] %s", flag, line );
		newpos = ftell( logFile );
	}
	newpos = ftell( logFile );

errata:
	gpf_fclose( logFile );

	return newpos;
}

/**
 * tail処理実行後の結果を出力する
 * @param outPath 出力ファイルパス(NULLの場合は標準出力)
 * @param res 結果配列(ラウンドロビン)
 * @param row 結果行数
 * @return 合否
 */ 
int gpfSaveTailResult(char *outPath, char **res, int *row)
{
	int rc = 0;
	FILE *outFile = NULL;
	int i;

	/* 初期化フラグが1の場合は上書き更新、そうでない場合は追加更新 */
	if ( outPath )
	{
		if ( (outFile = fopen(outPath, "w" )) == NULL)
		{
			gpfSystemError("%s", outPath);
			goto errata;
		}

		/* ローテートした結果を登録順に出力 */
		for (i = 0; i < GPF_LOG_SCAN_LIMIT_ROW; i++)
		{
			int pivot = ( i + *row) % GPF_LOG_SCAN_LIMIT_ROW;
			if (res[pivot] != NULL)
			{
				if ( fputs(res[pivot], outFile) == -1)
				{
					gpfSystemError("%s", outPath);
					goto errata;
				}
				gpfFree(res[pivot]);			
			}
		}
	}
	else
	{
		for (i = 0; i < GPF_LOG_SCAN_LIMIT_ROW; i++)
		{
			int pivot = ( i + *row) % GPF_LOG_SCAN_LIMIT_ROW;
			if (res[pivot] != NULL)
			{
				fputs(res[pivot], stdout);
				gpfFree(res[pivot]);
			}
		}		
	}
	rc = 1;

errata:
	gpf_fclose( outFile );
	return rc;
}

/**
 * Function: split_string
 * Purpose: separates given string to two parts by given delimiter in string
 *                                                                          
 * Parameters: str - the string to split                                    
 *             del - pointer to a character in the string                   
 *             part1 - pointer to buffer for the first part with delimiter  
 *             part2 - pointer to buffer for the second part                
 * Return value: SUCCEED - on splitting without errors                      
 *               FAIL - on splitting with errors                            
 *                                                                          
 * Author: Dmitry Borovikov, Aleksandrs Saveljevs                           
 *                                                                          
 * Comments: Memory for "part1" and "part2" is allocated only on SUCCEED.   
 *                                                                          
 **/
int	split_string(const char *str, const char *del, char **part1, char **part2)
{
	const char	*__function_name = "split_string";
	size_t		str_length = 0, part1_length = 0, part2_length = 0;
	int		ret = 0;

	assert(NULL != str && '\0' != *str);
	assert(NULL != del && '\0' != *del);
	assert(NULL != part1 && '\0' == *part1);	/* target 1 must be empty */
	assert(NULL != part2 && '\0' == *part2);	/* target 2 must be empty */

	gpfDebug("In %s() str:'%s' del:'%s'", __function_name, str, del);

	str_length = strlen(str);

	/* since the purpose of this function is to be used in split_filename(), */
	/* we allow part1 to be */
	/* just *del (e.g., "/" - file system root), but we do not allow part2 (filename) */
	/* to be empty */
	if (del < str || del >= (str + str_length - 1))
	{
		gpfDebug("%s() cannot proceed: delimiter is errata of range", __function_name);
		goto errata;
	}

	part1_length = del - str + 1;
	part2_length = str_length - part1_length;

	*part1 = gpfMalloc(*part1, part1_length + 1);
	gpfStrlcpy(*part1, str, part1_length + 1);

	*part2 = gpfMalloc(*part2, part2_length + 1);
	gpfStrlcpy(*part2, str + part1_length, part2_length + 1);

	ret = 1;
errata:
	gpfDebug("End of %s():%d part1:'%s' part2:'%s'", __function_name, ret,
			*part1, *part2);

	return ret;
}

/**
 * Function: split_filename                                                   
 * Purpose: separates filename to directory and to file format (regexp)       
 *                                                                            
 * Parameters: filename - first parameter of log[] item                       
 * Return value: SUCCEED - on successful splitting                            
 *               FAIL - on unable to split sensibly                           
 *                                                                            
 * Author: Dmitry Borovikov                                                   
 *                                                                            
 * Comments: Allocates memory for "directory" and "format" only on success.   
 *           On fail, memory, allocated for "directory" and "format",         
 *           is freed.                                                        
 *                                                                            
 **/
int gpfSplitFilename(const char *filename, char **directory, char **format)
{
	const char	*__function_name = "split_filename";
	const char	*separator = NULL;
	struct stat	buf;
	int		ret = 0;
#ifdef _WINDOWS
	size_t		sz;
#endif

	assert(NULL != directory && '\0' == *directory);
	assert(NULL != format && '\0' == *format);

	gpfDebug( "In %s() filename:'%s'", __function_name, filename ? filename : "NULL");

	if (NULL == filename || '\0' == *filename)
	{
		gpfError( "cannot split empty path");
		goto errata;
	}

#ifdef _WINDOWS
	/* special processing for Windows, since PATH part cannot be simply divided 
	from REGEXP part (file format) */
	for (sz = strlen(filename) - 1, separator = &filename[sz]; separator >= filename; separator--)
	{
		if (GPF_FILE_SEPARATOR != *separator)
			continue;

		gpfDebug( "%s() %s", __function_name, filename);
		gpfDebug( "%s() %*s", __function_name, separator - filename + 1, "^");

		/* separator must be relative delimiter of the original filename */
		if (0 == split_string(filename, separator, directory, format))
		{
			gpfError( "cannot split '%s'", filename);
			goto errata;
		}

		sz = strlen(*directory);

		/* Windows world verification */
		if (sz + 1 > MAX_PATH)
		{
			gpfError( "cannot proceed: directory path is too long");
			gpfFree(*directory);
			gpfFree(*format);
			goto errata;
		}

		/* Windows "stat" functions cannot get info aberrata directories with '\' at 
		the end of the path, */
		/* except for root directories 'x:\' */
		if (0 == stat(*directory, &buf) && S_ISDIR(buf.st_mode))
			break;

		if (sz > 0 && GPF_FILE_SEPARATOR == (*directory)[sz - 1])
		{
			(*directory)[sz - 1] = '\0';

			if (0 == stat(*directory, &buf) && S_ISDIR(buf.st_mode))
			{
				(*directory)[sz - 1] = GPF_FILE_SEPARATOR;
				break;
			}
		}

		gpfError( "cannot find directory '%s'", *directory);
		gpfFree(*directory);
		gpfFree(*format);
	}

	if (separator < filename)
		goto errata;

#else/* _WINDOWS */
	if (NULL == (separator = strrchr(filename, GPF_FILE_SEPARATOR)))
	{
		gpfDebug( "filename '%s' does not contain any path separator '%c'", filename, GPF_FILE_SEPARATOR);
		goto errata;
	}
	if (1 != split_string(filename, separator, directory, format))
	{
		gpfError( "cannot split filename '%s' by '%c'", filename, GPF_FILE_SEPARATOR);
		goto errata;
	}

	if (-1 == stat(*directory, &buf))
	{
		gpfError( "cannot find directory '%s' on the file system", *directory);
		gpfFree(*directory);
		gpfFree(*format);
		goto errata;
	}

	if (0 == S_ISDIR(buf.st_mode))
	{
		gpfError( "cannot proceed: directory '%s' is a file", *directory);
		gpfFree(*directory);
		gpfFree(*format);
		goto errata;
	}
#endif/* _WINDOWS */

	ret = 1;
errata:
	gpfDebug( "End of %s():%d directory:'%s' format:'%s'", __function_name, ret,
			*directory, *format);

	return ret;
}
