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

#define GPF_MAIN_MODULE 1
#include "gpf_config.h"
#include "gpf_common.h"
#include "gpf_log.h"
#include "gpf_getopt.h"
#include "gpf_logrt.h"

char *gpfHelpMessage[] = {
	"logretrieve [--config(-c) getperf.cfg] [--regexp(-r) \"err|ERR\"]",
	"    [--logid(-l) id] [--event(-e)] [--verify(-v)] ",
	"	--output(-o) \"output directory\" \"<logfile path>,...\"",
	"Options:",
	"  -c --config  config file",
	"  -r --regexp  regular expression",
	"  -l --logid   unique id",
	"  -v --verify  run as verify mode",
	"  -e --event   use Windows event log",
	0 /* end of text */
};

int main ( int argc, char **argv )
{
	int rc = 0;
	int option;
	int eventLogFlag  = 0;
	int verifyFlag    = 0;
	int logidx        = 0;
	int lognum        = 0;
	char **logs       = NULL;
	char *yesno       = NULL;
	char *regexp      = NULL;
	char *logid       = NULL;
	char *logpath     = NULL;
	char *_logpath    = NULL;
	char *logdir      = NULL;
	char *logname     = NULL;
	char *output      = NULL;
	char *configFile  = NULL;
	GPFConfig *config = NULL;
	char username[MAX_USERNAME_LEN];
	
	GCON = NULL;
	
	while (1)
	{
		static struct gpf_option longOptions[] =
		{
			{ "config", gpf_required_argument, 0, 'c' },
			{ "regexp", gpf_required_argument, 0, 'r' },
			{ "logid",  gpf_required_argument, 0, 'l' },
			{ "output", gpf_required_argument, 0, 'o' },
			{ "event",  gpf_no_argument,       0, 'e' },
			{ "verify", gpf_no_argument,       0, 'v' },
			{0, 0, 0, 0}
		};
		int optionIndex = 0;
		option = gpf_getopt_long (argc, argv, "c:r:l:o:ev", longOptions, &optionIndex);

		if ( option == -1 )
			break;

		switch ( option )
		{
		case 'c':
			configFile = gpf_optarg;
			break;

		case 'r':
			regexp     = gpf_optarg;
			break;

		case 'l':
			logid      = gpf_optarg;
			break;

		case 'o':
			output     = gpf_optarg;
			break;

		case 'e':
			eventLogFlag = 1;
			break;

		case 'v':
			verifyFlag   = 1;
			break;

		case '?':
		case 'h':
		default:
			gpfUsage ( gpfHelpMessage );
			exit(-1);
		}
	}
	if ( gpf_optind < argc )
		logpath = argv[gpf_optind++];

	if ( output == NULL || logpath == NULL || gpf_optind != argc )
	{
		gpfUsage( gpfHelpMessage );
		exit(-1);
	}

#ifndef _WINDOWS
	if ( eventLogFlag )
	{
		/* Windows環境のみで利用するコマンドです。詳細は Install.txt を参照して下さい */
		gpfMessage( GPF_MSG029E, GPF_MSG029 );
		exit(-1);
	}
#endif

	/* getperf.ini パラメータファイルの読込とログの初期化 */
	if ( (rc = gpfInitAgent( &config, argv[0], NULL )) == 0)
		exit (-1);
	gpfSwitchLog( config, NULL, NULL);
	
	/* ベリファイモードの場合、処理内容の事前説明をする */
	if (verifyFlag == 1)
	{
		char *yesno = NULL;

		/* エージェントは以下の通りシステムログをスキャンし、モニタリングサイトへ転送します。 */
		/* ・5分間隔でログをスキャンし、差分を集計サーバに転送します。 */
		/* ・1回あたりの転送行は1,000行までの制約があります。それ以上のレコードは、過去の行から読み飛ばします。 */
		/* ・ログスキャンする対象は '%s' です (アップグレードにより他のログの監視も可能です) */
		gpfMessage( GPF_MSG069E, GPF_MSG069, 
			(eventLogFlag) ? GPF_WINDOWS_EVENT_SCAN_LIMIT_ROW : GPF_LOG_SCAN_LIMIT_ROW,
			logpath );

		/* これより、ログへのアクセス検証します。よろしいですか(y/n)？ */
		gpfGetLine( GPF_MSG070E, GPF_MSG070, &yesno );
		if ( strcmp( yesno, "y" ) != 0 ) 
		{
			gpfError("Canceled");
			goto errata;
		}
	}

	/* ログファイルを複数指定した場合の分割 */
	_logpath = strdup(logpath);
	logs = gpfSplit( &lognum, ",", _logpath);

	/* Windowsイベントログモードの場合、Windowsイベントを抽出する */
	if ( eventLogFlag )
	{
#ifdef _WINDOWS
		for ( logidx = 0; logidx < lognum; logidx++ )
		{
			rc = gpfRetrieveWindowsEventLog(config, logid, logs[logidx], 
				regexp, output, 0);
			if ( rc != 1 )
				break;
		}
		if (verifyFlag)
		{
			if (rc != 1)
			{
			/* Windowsイベントログを監視する場合はadministrator権限が付与されたユーザで実行してください。 */
				gpfMessage( GPF_MSG075E, GPF_MSG075);
			}
		}
#endif
	}
	else
	{
		/* ログ抽出処理。べりファイモードのログ抽出の場合、再実行確認メッセージを表示する */
		int continueFlag = 0;
		while ( continueFlag == 0 )
		{
			for ( logidx = 0; logidx < lognum; logidx ++)
			{
				if ( gpfSplitFilename(logs[logidx], &logdir, &logname) == 0)
				{
					gpfError("Can't parse path : %s", logs[logidx]);
					goto errata;
				}
				rc = gpfRetrieveLog( config, logdir, logname, logid, 
					regexp, output );
				gpfFree(logdir);
				gpfFree(logname)
				if (rc != 1)
					break;
			}
			if ( rc == 1 )
			{					
				continueFlag = 1;
			}
			else
			{
				if (verifyFlag)
				{
					char *loglist = gpfStringReplace( logpath, ",", " " );
					#ifdef _WINDOWS
						/* %s に読み取り権限が無いようです。 */
						gpfMessage( GPF_MSG073E, GPF_MSG073, logpath);
						/* 読み取り権限を付与してから再実行してください。再実行しますか(y/n) ? */
						gpfGetLine( GPF_MSG074E, GPF_MSG074, &yesno );
					#else
						if (gpfGetUserName(username, 255) != 0)
						{
							gpfSystemError("get login name");
							goto errata;
						}
						/* /var/log 下のファイルはroot権限を付与するよう手順を出力する */
						if ( (strstr(logpath, "/var/log")) != NULL)
						{
							gpfMessage( GPF_MSG071E, GPF_MSG071, logpath, username,
								loglist, username, loglist, loglist );
							gpfGetLine( GPF_MSG072E, GPF_MSG072, &yesno );
						}
						else
						{
							gpfMessage( GPF_MSG073E, GPF_MSG073, logpath);
							gpfGetLine( GPF_MSG074E, GPF_MSG074, &yesno );
						}
					#endif
					if ( strcmp( yesno, "y" ) != 0 ) 
						goto errata;
					gpfFree( yesno );
				}
				else
				{
					continueFlag = 1;
				}
			}
		}
	}

errata:
	/* ワークディレクトリ削除。gpfInitAgent()を実行した後は終了時に必要 */
	gpfRemoveWorkDir( config );

	gpfFree( yesno );
	exit ( ( rc == 1) ? 0 : -1 );
}
