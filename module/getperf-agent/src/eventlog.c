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
** Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
**/

#include "gpf_config.h"
#include "gpf_common.h"
#include "gpf_param.h"
#include "gpf_log.h"
#include "gpf_logrt.h"
#include "gpf_regexp.h"
#include "eventlog.h"
#include "gpftypes.h"
#include "unicode.h"

#define MAX_INSERT_STRS 100
#define MAX_MSG_LENGTH 1024

#define EVENTLOG_REG_PATH TEXT("SYSTEM\\CurrentControlSet\\Services\\EventLog\\")

/* open event logger and return number of records */
static int    gpf_open_eventlog(LPCTSTR wsource, HANDLE *eventlog_handle, 
	long *pNumRecords, long *pLatestRecord)
{
	const char	*__function_name = "gpf_open_eventlog";
	TCHAR		reg_path[MAX_PATH];
	HKEY		hk = NULL;
	int		ret = 0;

	assert(eventlog_handle);
	assert(pNumRecords);
	assert(pLatestRecord);

	gpfDebug("In %s()", __function_name);

	*eventlog_handle = NULL;
	*pNumRecords = 0;
	*pLatestRecord = 0;

	/* Get path to eventlog */
	gpfSnprintf(reg_path, MAX_PATH, EVENTLOG_REG_PATH TEXT("%s"), wsource);

	if (ERROR_SUCCESS != RegOpenKeyEx(HKEY_LOCAL_MACHINE, reg_path, 0, KEY_READ, &hk))
		goto out;

	RegCloseKey(hk);

	if (NULL == (*eventlog_handle = OpenEventLog(NULL, wsource)))	/* open log file */
		goto out;

	if (0 == GetNumberOfEventLogRecords(*eventlog_handle, (unsigned long*)pNumRecords))	/* get number of records */
		goto out;

	if (0 == GetOldestEventLogRecord(*eventlog_handle, (unsigned long*)pLatestRecord))
		goto out;

	gpfDebug("%s() pNumRecords:%ld pLatestRecord:%ld",
			__function_name, *pNumRecords, *pLatestRecord);

	ret = 1;
out:
	gpfDebug("End of %s():%d", __function_name, ret);

	return ret;
}

/* close event logger */
static int	gpf_close_eventlog(HANDLE eventlog_handle)
{
	if (NULL != eventlog_handle)
		CloseEventLog(eventlog_handle);

	return 1;
}

/* get Nth error from event log. 1 is the first. */
static int	gpf_get_eventlog_message(LPCTSTR wsource, HANDLE eventlog_handle, long which, 
	char **out_source, char **out_message, unsigned short *out_severity, 
	unsigned long *out_timestamp, unsigned long *out_eventid)
{
	const char	*__function_name = "gpf_get_eventlog_message";
	int		buffer_size = 512;
	EVENTLOGRECORD	*pELR = NULL;
	DWORD		dwRead, dwNeeded, dwErr;
	TCHAR		stat_buf[MAX_PATH], MsgDll[MAX_PATH];
	HKEY		hk = NULL;
	LPTSTR		pFile = NULL, pNextFile = NULL;
	DWORD		szData, Type;
	HINSTANCE	hLib = NULL;				/* handle to the messagetable DLL */
	LPTSTR		pCh, aInsertStrs[MAX_INSERT_STRS];	/* array of pointers to insert */
	LPTSTR		msgBuf = NULL;				/* hold text of the error message */
	char		*buf = NULL;
	long		i, err = 0;
	int		ret = 0;

	gpfDebug("In %s() which:%ld", __function_name, which);

	*out_source	= NULL;
	*out_message	= NULL;
	*out_severity	= 0;
	*out_timestamp	= 0;
	*out_eventid	= 0;

	memset(aInsertStrs, 0, sizeof(aInsertStrs));
	pELR = (EVENTLOGRECORD *)gpfMalloc((void *)pELR, buffer_size);
retry:
	if (0 == ReadEventLog(eventlog_handle, EVENTLOG_SEEK_READ | EVENTLOG_FORWARDS_READ,
				which, pELR, buffer_size, &dwRead, &dwNeeded))
	{
		dwErr = GetLastError();
		if (dwErr == ERROR_INSUFFICIENT_BUFFER)
		{
			buffer_size = dwNeeded;
			pELR = (EVENTLOGRECORD *)gpfRealloc((void *)pELR, buffer_size);
			goto retry;
		}
		else
		{
			gpfSystemError("%s()", __function_name);
			goto out;
		}
	}
	*out_severity	= pELR->EventType;			/* return event type */
	*out_timestamp	= pELR->TimeGenerated;			/* return timestamp */
	*out_eventid	= pELR->EventID & 0xffff;
	*out_source	= _tcsdup((LPTSTR)(pELR + 1));	/* copy source name */

	err = 0;

	/* prepare the array of insert strings for FormatMessage - the
	insert strings are in the log entry. */
	for (i = 0, pCh = (LPTSTR)((LPBYTE)pELR + pELR->StringOffset);
			i < pELR->NumStrings && i < MAX_INSERT_STRS;
			i++, pCh += gpf_strlen(pCh) + 1) /* point to next string */
	{
		aInsertStrs[i] = pCh;
	}

	/* Get path to message dll */
	gpfSnprintf(stat_buf, MAX_PATH, EVENTLOG_REG_PATH TEXT("%s\\%s"), 
		wsource, (LPTSTR)(pELR + 1));

	if (ERROR_SUCCESS == RegOpenKeyEx(HKEY_LOCAL_MACHINE, stat_buf, 0, KEY_READ, &hk))
	{
		if (ERROR_SUCCESS == RegQueryValueEx(hk, TEXT("EventMessageFile"), NULL, &Type, 
			NULL, &szData))
		{
			buf = gpfMalloc(buf, szData);
			if (ERROR_SUCCESS == RegQueryValueEx(hk, TEXT("EventMessageFile"), NULL, &Type, 
				(LPBYTE)buf, &szData))
				pFile = (LPTSTR)buf;
		}

		RegCloseKey(hk);
	}

	err = 0;

	while (NULL != pFile && 0 == err)
	{
		if (NULL != (pNextFile = gpf_strchr(pFile, ';')))
		{
			*pNextFile = '\0';
			pNextFile++;
		}

		if (ExpandEnvironmentStrings(pFile, MsgDll, MAX_PATH))
		{
			if (NULL != (hLib = LoadLibraryEx(MsgDll, NULL, LOAD_LIBRARY_AS_DATAFILE)))
			{
				/* Format the message from the message DLL with the insert strings */
				if (0 != FormatMessage(FORMAT_MESSAGE_FROM_HMODULE | 
						FORMAT_MESSAGE_ALLOCATE_BUFFER |
						FORMAT_MESSAGE_ARGUMENT_ARRAY | 
						FORMAT_MESSAGE_FROM_SYSTEM |
						FORMAT_MESSAGE_MAX_WIDTH_MASK,	/* do not generate new line breaks */
						hLib,				/* the messagetable DLL handle */
						pELR->EventID,		/* message ID */
						MAKELANGID(LANG_NEUTRAL, SUBLANG_ENGLISH_US),	/* language ID */
						(LPTSTR)&msgBuf,	/* address of pointer to buffer for message */
						0,
						(va_list *)aInsertStrs))	
						/* array of insert strings for the message */
				{
//					*out_message = gpf_unicode_to_utf8(msgBuf);
					*out_message = _tcsdup(msgBuf);
					gpfRtrim(*out_message, "\r\n ");

					/* Free the buffer that FormatMessage allocated for us. */
					LocalFree((HLOCAL)msgBuf);

					err = 1;
				}
				FreeLibrary(hLib);
			}
		}
		pFile = pNextFile;
	}

	gpfFree(buf);

	if (1 != err)
	{
		*out_message = gpfDsprintf(*out_message, 
			"The description for Event ID (%lu) in Source (%s) cannot be found."
			" The local computer may not have the necessary registry information or message DLL files to"
			" display messages from a remote computer.", 
			*out_eventid, NULL == *out_source ? "" : *out_source);
		if (pELR->NumStrings)
			*out_message = gpfStrdcat(*out_message, " The following information is part of the event: ");
		for (i = 0; i < pELR->NumStrings && i < MAX_INSERT_STRS; i++)
		{
			if (i > 0)
				*out_message = gpfStrdcat(*out_message, "; ");
			if (aInsertStrs[i])
			{
//				buf = gpf_unicode_to_utf8(aInsertStrs[i]);
				buf = _tcsdup(aInsertStrs[i]);
				*out_message = gpfStrdcat(*out_message, buf);
				gpfFree(buf);
			}
		}
	}
	else
	{
		ret = 1;
	}
out:
	gpfFree(pELR);

	gpfDebug("End of %s():%d", __function_name, ret);

	return ret;
}

/**
 * Windowsログレベルをラベル名に変換
 * @param level ログレベル
 * @return ラベル
 */ 
static char *getWindowsLogSevereLabel( int level )
{
	switch (level)
	{
		case 1:
		return strdup("error");

		case 2:
		return strdup("warning");

		case 4:
		return strdup("information");

		case 8:
		return strdup("audit success");

		case 16:
		return strdup("audit failure");
	}
	return strdup("unkown");
}

/**
 * 指定サイズ以降のWindowsイベントログを取得する
 * @param source イベント名
 * @param lastlogsize 前回読み取りログサイズ
 * @param regexp 正規表現キーワード
 * @param eventLog 結果配列(ラウンドロビン)
 * @param row 結果行数
 * @param skip_pld_data 過去ログの読み取りをスキップ
 * @return 合否
 */ 
int	process_eventlog(const char *source, gpf_uint64_t *lastlogsize, char *regexp,
	GPFEventLog **eventLog, int *row, unsigned char skip_old_data)
{
	const char	*__function_name = "process_eventlog";
	int		ret = 0;
	HANDLE		eventlog_handle;
	long		FirstID, LastID;
	register long	i;
	LPTSTR		wsource;

	gpfDebug("In %s() source:'%s' lastlogsize:%d", // gpf_FS_UI64,
			__function_name, source, *lastlogsize);

	if (NULL == source || '\0' == *source)
	{
		gpfWarn("cannot open eventlog with empty name");
		return 0;
	}

	/*　wsource = gpf_utf8_to_unicode(source); */
	wsource = strdup(source);
	if (1 == gpf_open_eventlog(wsource, &eventlog_handle, &LastID , &FirstID ))
	{
		unsigned long out_timestamp = 0;
		char *out_source = NULL;
		unsigned short out_severity = 0;
		char *out_message = NULL;
		unsigned long out_eventid = 0;

		LastID += FirstID;
		if (1 == skip_old_data)
		{
			if ( (LastID - GPF_WINDOWS_EVENT_SCAN_FIRST_SITE) > 0 )
				*lastlogsize = LastID - GPF_WINDOWS_EVENT_SCAN_FIRST_SITE;
			else
				*lastlogsize = LastID - 1;
			gpfDebug("skipping existing data: lastlogsize:%d", //gpf_FS_UI64,
			 *lastlogsize);
		}


		/* 最新ログが前回よりも古い場合はイベントログがクリアされたとしてFirstIDから読む */
		if (*lastlogsize < LastID)
			FirstID = (*lastlogsize) + 1;

		if ( (LastID - FirstID) > GPF_WINDOWS_EVENT_SCAN_LIMIT_SIZE)
			FirstID = LastID - GPF_WINDOWS_EVENT_SCAN_LIMIT_SIZE;
		for (i = FirstID; i < LastID; i++)
		{
			if (1 == gpf_get_eventlog_message(wsource, eventlog_handle, i, 
					&out_source, &out_message, &out_severity, &out_timestamp, 
					&out_eventid))
			{
				int flag = 1;
				int len = 0;
				char *severeLabel = NULL;
				*lastlogsize = i;
				severeLabel = getWindowsLogSevereLabel(out_severity);
				/* 正規表現を指定している場合はキーワードでフィルタリング */
				if ( regexp )
				{
					if (gpf_regexp_match(severeLabel, regexp, &len) == NULL &&
						gpf_regexp_match(out_message, regexp, &len) == NULL)
						flag = 0;
				}

				if ( flag == 1 )
				{
					GPFEventLog *ev = NULL;	
					int pivot = *row % GPF_WINDOWS_EVENT_SCAN_LIMIT_ROW;
					if (*row > GPF_WINDOWS_EVENT_SCAN_LIMIT_ROW)
						gpfFreeEventLog(&eventLog[pivot]);

					eventLog[pivot]	= gpfCreateEventLog(out_timestamp, out_source,
						severeLabel, out_message, out_eventid);
					ev = eventLog[pivot];

					gpfDebug("lastlogsize = %lu\n",   *lastlogsize);
					gpfDebug("timestamp   = %lu\n",   ev->timestamp);
					gpfDebug("severity    = %s\n",    ev->severeLabel);
					gpfDebug("source      = %s\n",    ev->source);
					gpfDebug("value       = %s\n",    ev->message);
					gpfDebug("logeventid  = %lu\n\n", ev->eventid);

					(*row) ++;
				}
				gpfFree(severeLabel);
				gpfFree(out_source);
				gpfFree(out_message);
			}

		}
		gpf_close_eventlog(eventlog_handle);

		ret = 1;
	}
	else
		gpfSystemError("cannot open eventlog '%s'", source);

	gpfFree(wsource);

	gpfDebug("End of %s():%d", __function_name, ret);

	return ret;
}

/**
 * Windowsイベントログ結果を出力する
 * @param outPath 出力ファイルパス(NULLの場合は標準出力)
 * @param res 結果配列(ラウンドロビン)
 * @param row 結果行数
 * @return 合否
 */ 
int gpfSaveEventLogResult(char *outPath, GPFEventLog **res, int *row)
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
				if ( gpfPutEventLog(res[pivot], outFile) == -1)
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
				gpfPutEventLog(res[pivot], stdout);
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
 * YAML形式でWindowsイベントログを1行出力する
 * @param ev イベントログ結果
 * @param out ファイル出力ポインタ
 * @return 合否
 */ 
int gpfPutEventLog(GPFEventLog *ev, FILE *out)
{
	int rc = -1;
	char *buff = NULL;
	char *line = NULL;
	line = gpfMalloc( line, MAX_STRING_LEN );

	/* - timestamp: 1292437879 */
	gpfSnprintf(line, MAX_STRING_LEN, "- timestamp: %d\n", ev->timestamp );
	buff = gpfStrdcat( buff, line );

	/*   logeventid: 1033 */
	gpfSnprintf(line, MAX_STRING_LEN, "  logeventid: %d\n", ev->eventid );
	buff = gpfStrdcat( buff, line );

	/*   severity: 4 */
	gpfSnprintf(line, MAX_STRING_LEN, "  severity: %s\n", ev->severeLabel );
	buff = gpfStrdcat( buff, line );

	/*   source: Software Protection Platform Service */
	gpfSnprintf(line, MAX_STRING_LEN, "  source: %s\n", ev->source );
	buff = gpfStrdcat( buff, line );

	/*   value: |- */
	if ( ev->message != NULL )
	{
		int row      = 0;
		int rown     = 0;
		char **lines = NULL;
		buff = gpfStrdcat( buff, "  value: |-\n" );
		lines = gpfSplit( &rown, GPF_LINE_SEPARATORS, ev->message );
		for ( row = 0; row < rown; row ++ )
		{
			gpfSnprintf(line, MAX_STRING_LEN, "    %s\n", lines[ row ] );
			buff = gpfStrdcat( buff, line );
		}
		gpfFree( lines );
	}
	rc = fputs( buff, out );
	gpfFree(buff);
	gpfFree(line);

	return rc;
}

/**
 * 前回読み取りからログファイルを差分読込みしてファイル保存する
 * ログローテーションしている場合は、１世代前のロググラフから読み込む
 * @param config エージェント構造体
 * @param eventname ログファイル名
 * @param regexp 正規表現キーワード
 * @param outDir 出力ディレクトリ
 * @param skip_old_data 過去ログのスキップ
 * @return 合否
 */ 
int gpfRetrieveWindowsEventLog( GPFConfig *config, char *logid, char *eventname, 
	char *regexp, char *outDir, int _skip_old_data )
{
	int rc             = 0;
	int row            = 0;
	int skip_old_data  = _skip_old_data;
	char *outPath      = NULL;
	char *outFile      = NULL;
	GPFLogStat *offset = NULL;
	gpf_uint64_t lastlogsize = 0;
	GPFEventLog *eventLogs[GPF_WINDOWS_EVENT_SCAN_LIMIT_ROW];
	int i;

	/* 結果データの初期化。サイズの制限とつけてローテーションさせる */
	for (i = 0; i < GPF_WINDOWS_EVENT_SCAN_LIMIT_ROW; i++)
	{
		eventLogs[i] = NULL;
	}

	/* 前回読み取りオフセットのロード */
	offset = gpfLoadLogOffset( config, NULL, eventname );
	lastlogsize = offset->fsize;

	/* 前回オフセットが無い場合は、過去データの読み取りをスキップ */
	if ( lastlogsize == 0)
		skip_old_data = 1;

	/* カレントログファイルの読込 */
	if ( (rc = process_eventlog(eventname, &lastlogsize, regexp, eventLogs,
		&row, skip_old_data)) == 1)
	{
		offset->fsize = lastlogsize;

		gpfSaveLogOffset( config, offset, NULL, eventname );
	}

	if (row > GPF_WINDOWS_EVENT_SCAN_LIMIT_ROW)
		gpfError("Log scan limit exceed. Write %d row", GPF_WINDOWS_EVENT_SCAN_LIMIT_ROW);

	if ( logid )
		outFile = gpfDsprintf( outFile, "%s_%s", logid, eventname );
	else
		outFile = gpfDsprintf( outFile, "%s", eventname );

	outPath = gpfCatFile( outDir, outFile, NULL);
	rc = gpfSaveEventLogResult( outPath, eventLogs, &row );

errata:
	gpfFree(outPath);
	gpfFreeLogStat(&offset);

	return rc;
}
