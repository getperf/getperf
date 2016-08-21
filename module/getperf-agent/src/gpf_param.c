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
#include "gpf_param.h"

/**
 * パラメータファイル読み込み
 * @param schedule    スケジュール構造体
 * @param configType  入力データ種別(ファイル, バッファ)
 * @param paramPath   パラメータパス
 * @param paramBuffer 読み込みバッファ
 * @return 合否
 */
int gpfLoadConfig(GPFSchedule *schedule, int configType, char *paramPath, char *paramBuffer)
{
	int result = 0;
	/* パラメータ定義 */
	GPFConfigParam cfg[] =
	{
/*       PARAMETER       ,VAR    ,FUNC,  TYPE, MANDATORY, MIN, MAX
*/
		/* 採取データの容量 */
		{"DISK_CAPACITY", &(schedule->diskCapacity), 0, TYPE_INT, PARM_OPT, 0, 0},
		{"SAVE_HOUR",     &(schedule->saveHour),     0, TYPE_INT, PARM_OPT, 0, 24},
		{"RECOVERY_HOUR", &(schedule->recoveryHour), 0, TYPE_INT, PARM_OPT, 0, 24},
		{"MAX_ERROR_LOG", &(schedule->maxErrorLog),  0, TYPE_INT, PARM_OPT, 0, 0},

		/* ログ */
		{"LOG_LEVEL",     &(schedule->logLevel),     0, TYPE_INT,  PARM_OPT, 0, 7},
		{"DEBUG_CONSOLE", &(schedule->debugConsole), 0, TYPE_BOOL, PARM_OPT, 0, 1},
		{"LOG_SIZE",      &(schedule->logSize),      0, TYPE_INT,  PARM_OPT, 100000, 0},
		{"LOG_ROTATION",  &(schedule->logRotation),  0, TYPE_INT,  PARM_OPT, 1, 100},
		{"LOG_LOCALIZE",  &(schedule->logLocalize),  0, TYPE_BOOL, PARM_OPT, 0, 1},
		
		/* クラスター */
		{"HANODE_ENABLE", &(schedule->hanodeEnable), 0, TYPE_BOOL,   PARM_OPT, 0, 1},
		{"HANODE_CMD",    &(schedule->hanodeCmd),    0, TYPE_STRING, PARM_OPT, 0, 0},

		/* 後処理 */
		{"POST_ENABLE",   &(schedule->postEnable),   0, TYPE_BOOL,   PARM_OPT, 0, 1},
		{"POST_CMD",      &(schedule->postCmd),      0, TYPE_STRING, PARM_OPT, 0, 0},

		/* WEBサービス */
		{"REMHOST_ENABLE", &(schedule->remhostEnable), 0, TYPE_BOOL,   PARM_OPT, 0, 1},
		{"URL_CM",         &(schedule->urlCM),         0, TYPE_STRING, PARM_OPT, 0, 0},
		{"URL_PM",         &(schedule->urlPM),         0, TYPE_STRING, PARM_OPT, 0, 0},
		{"SOAP_TIMEOUT",   &(schedule->soapTimeout),   0, TYPE_INT,    PARM_OPT, 1, 300},
		{"SITE_KEY",       &(schedule->siteKey),       0, TYPE_STRING, PARM_MAND, 0, 0},

		/* プロキシー */
		{"PROXY_ENABLE", &(schedule->proxyEnable), 0, TYPE_BOOL,   PARM_OPT, 0, 1},
		{"PROXY_HOST",   &(schedule->proxyHost),   0, TYPE_STRING, PARM_OPT, 0, 0},
		{"PROXY_PORT",   &(schedule->proxyPort),   0, TYPE_INT,    PARM_OPT, 0, 65536},
		
		/* コレクター */
		{"STAT_ENABLE",    schedule, &gpfSetCollector, TYPE_BOOL,   PARM_OPT, 0, 1},
		{"BUILD",          schedule, &gpfSetCollector, TYPE_INT,    PARM_OPT, 0, 0},
		{"STAT_STDOUTLOG", schedule, &gpfSetCollector, TYPE_BOOL,   PARM_OPT, 0, 1},
		{"STAT_INTERVAL",  schedule, &gpfSetCollector, TYPE_INT,    PARM_OPT, 1, 0},
		{"STAT_TIMEOUT",   schedule, &gpfSetCollector, TYPE_INT,    PARM_OPT, 1, 0},
		{"STAT_MODE",      schedule, &gpfSetCollector, TYPE_STRING, PARM_OPT, 0, 0},

		/* ジョブ */
		{"STAT_CMD",     schedule, &gpfSetJob, TYPE_STRING, PARM_OPT, 0, 0},
		{0}
	};

	/* デフォルト設定 */
	schedule->status       = GPF_PROCESS_INIT;
	schedule->diskCapacity = GPF_DEFAULT_DISK_CAPACITY;
	schedule->saveHour     = GPF_DEFAULT_SAVE_HOUR;
	schedule->recoveryHour = GPF_DEFAULT_RECOVERY_HOUR;
	schedule->maxErrorLog  = GPF_DEFAULT_MAX_ERROR_LOG;
	schedule->proxyPort    = GPF_DEFAULT_PROXY_PORT;
	schedule->logLevel     = GPF_DEFAULT_LOG_LEVEL;
	schedule->logSize      = GPF_DEFAULT_LOG_SIZE;
	schedule->logRotation  = GPF_DEFAULT_LOG_ROTATION;
	schedule->logLocalize  = GPF_DEFAULT_LOG_LOCALIZE;
	schedule->soapTimeout  = GPF_SOAP_CONNECT_TIMEOUT;
	schedule->_last_update = 0;
	
	/* パラメータロード */
	if (configType == GPF_CONFIG_TYPE_FILE && paramPath != NULL)
	{
		result = gpfParseConfigFile(paramPath, cfg, 0);
	}
	else if (configType == GPF_CONFIG_TYPE_BUFFER && paramBuffer != NULL)
	{
		result = gpfParseConfigLine(paramBuffer, cfg, 0);
	}

	if (result == 0) 
	{
		return gpfError("Parameter load error");
	}
	
	/* 値チェック */
	if (configType == GPF_CONFIG_TYPE_FILE && !gpfCheckSchedule(schedule))
	{
		return gpfError("Parameter parse error");
	}

	return 1;
}

/**
 * http_proxy環境変数を読み取りセットする
 * @param schedule スケジュール構造体
 */
void gpfCheckHttpProxyEnv(GPFSchedule **_schedule)
{
	GPFSchedule *schedule = _schedule[0];

	char *p          = NULL;
	char *str        = NULL;
	char *url_host   = NULL;
	char *url_port   = NULL;
	char *str_end    = NULL;
	char delimiter[] = ":";
	int proxyPort    = 80;
	int value        = 0;

	if ((p = getenv("HTTP_PROXY")) || (p = getenv("http_proxy")))
	{
		/* 環境変数 http_proxy を検出しました。本設定を適用します : %s */
		gpfMessage( GPF_MSG056E, GPF_MSG056, p );
		str = strdup(p);
		gpfLRtrim(str, GPF_CFG_LTRIM_CHARS);
		if (strcmp(str, "http://") == 1)
		{
			str += strlen("http://");
			url_host = str;

			delimiter[0] = ':';
			if ((url_port = strstr(str, delimiter)) != NULL)
			{
				*url_port = '\0';
				url_port ++;
				str ++;
			}
			delimiter[0] = '/';
			if ( *str != '\0' ) 
			{
				if ((str_end = strstr(str, delimiter)) != NULL)
				{
					printf("str=%s\n", str);
					*str_end = '\0';
				}
			}
		}
		if ( url_host != NULL )
		{
			gpfFree( schedule->proxyHost );
			schedule->proxyHost = strdup( url_host );

			if ( url_port != NULL )
			{
				value = atoi( url_port );
				if (value > 0 && value < 65536 )
					proxyPort = value;
			}
			schedule->proxyPort = proxyPort;
			schedule->proxyEnable = 1;
		}
	}
}

/**
 * パラメータファイル読み込み
 * @param paramPath パラメータファイルパス
 * @param cfg       パラメータ定義
 * @return 合否
 */
int	gpfParseConfigFile(char *paramPath, GPFConfigParam *cfg, int level)
{
	int i, lineno;
	char line[MAX_BUF_LEN];
	int	result            = 1;
	char *includeName      = NULL;
	char *includeFileDir   = NULL;
	char *includeParamPath = NULL;
	char *p = NULL;
	FILE *file;

	if (++level > GPF_MAX_INCLUDE_LEVEL)
		return gpfError("Load nest level is over. Skip %s", paramPath);

	if(paramPath)
	{
		if( (file = fopen(paramPath, "r")) == NULL)
		{
			return gpfSystemError("%s", paramPath);
		}
		else
		{
			for(lineno = 1; fgets(line, MAX_BUF_LEN, file) != NULL; lineno++)
			{
				if (strlen(line) >= MAX_STRING_LEN)
				{
					result = gpfError("buffer over flow[%d] \"%d:%s\"", MAX_STRING_LEN, lineno, line);
					break;
				}
				
				/* 設定ファイルをインクルードする */
				if (strstr(line, "Include") == line)
				{
					includeName = strstr(line, " ");
					if (includeName == NULL)
					{
						result = gpfError("Wrong value in \"%s:%d\".", paramPath, lineno);
						break;
					}
					includeName ++;
					gpfLtrim(includeName, GPF_CFG_LTRIM_CHARS);
					gpfRtrim(includeName, GPF_CFG_RTRIM_CHARS);

					includeFileDir = strdup(paramPath);
					p = strrchr(includeFileDir, GPF_FILE_SEPARATOR);
					if (p != NULL) 
					{
						*p = '\0';
						includeParamPath = gpfCatFile(includeFileDir, includeName, NULL);
						if (gpfCheckDirectory(includeParamPath))
							result = gpfParseConfigDirectory(includeParamPath, cfg, level);
						else
							result = gpfParseConfigFile(includeParamPath, cfg, level);
						gpfFree(includeParamPath);

						if (result == 0)
						{
							if ( level == 1 )
								gpfError("Wrong pathname in \"%s:%d %s\".", paramPath, lineno, includeName);
							goto erange;
						}
					} 
					else 
					{
						result = gpfError("Wrong filename in \"%s:%d\".", paramPath, lineno);
					}
					gpfFree(includeFileDir);
				} 
				/* 1行読込み */
				else if (!gpfParseConfigLine(line, cfg, level)) 
				{
					result = gpfError("Wrong value in \"%s:%d\".", paramPath, lineno);
					break;
				}
			}
			fclose(file);
		}
	}
	/* Check for mandatory parameters */
	if (result) 
	{
		for (i = 0; cfg[i].parameter != 0; i++)
		{
			if(PARM_MAND != cfg[i].mandatory)
				continue;

			if (TYPE_INT == cfg[i].type)
			{
				if (*((int*)cfg[i].variable) == 0)
					goto erange_mandatory;
			}
			else if (TYPE_STRING == cfg[i].type)
			{
				if (cfg[i].variable == NULL)
					goto erange_mandatory;
			}
		}
	}

finish:
	gpfFree(includeFileDir);
	gpfFree(includeParamPath);
	return	result;

erange:
	gpfFree(includeFileDir);
	gpfFree(includeParamPath);
	return 0;

erange_mandatory:
	gpfFree(includeFileDir);
	gpfFree(includeParamPath);
	return gpfError("Missing parameter [%s]", cfg[i].parameter);
}

/**
 * ディレクトリ下のパラメータファイル読み込み
 * @param paramPath パラメータファイルパス
 * @param cfg       パラメータ定義
 * @return 合否
 */
#ifdef _WINDOWS
# include <windows.h>
# include <winbase.h>
int	gpfParseConfigDirectory(char *paramPath, GPFConfigParam *cfg, int level)
{
	char *searchPath = NULL;
	char *includePath = NULL;
	char *suffix = NULL;
	WIN32_FIND_DATA fd;
	HANDLE h;
	searchPath = gpfCatFile(paramPath, "*", NULL);
    h = FindFirstFileEx(searchPath, FindExInfoStandard, &fd, FindExSearchNameMatch, NULL, 0);
	gpfFree(searchPath);
	
    if ( INVALID_HANDLE_VALUE == h )
		return gpfSystemError( "%s", paramPath);

	while ( FindNextFile( h, &fd ) )
	{
		includePath = gpfCatFile(paramPath, fd.cFileName, NULL);
		if ((suffix = strchr(fd.cFileName, '.')) != NULL)
		{
			suffix ++;
			if (*suffix == '\0' || strcmp(suffix, "ini") != 0)
				goto read_end;
		}

		if (gpfParseConfigFile(includePath, cfg, level) == 0) 
			break;

		read_end:
			gpfFree(includePath);
	}
	gpfFree(includePath);
    FindClose( h );

	return 1;
}
#else
int	gpfParseConfigDirectory(char *paramPath, GPFConfigParam *cfg, int level)
{
	DIR		      *dir;
	struct stat	  sb;
	struct dirent *d;
	char          *suffix = NULL;
	char          *includePath = NULL;

	if ((dir = opendir(paramPath)) == NULL) {
		return gpfSystemError("%s", paramPath);
	}

	while ((d = readdir(dir)) != NULL) {
		includePath = gpfCatFile(paramPath, d->d_name, NULL);

		if ((suffix = strchr(d->d_name, '.')) != NULL)
		{
			suffix ++;
			if (*suffix == '\0' || strcmp(suffix, "ini") != 0)
				goto read_end;
		}
		if (stat(includePath, &sb) == -1 || !S_ISREG(sb.st_mode))
			goto read_end;
		if (gpfParseConfigFile(includePath, cfg, level) == 0) 
			break;
		read_end:
			gpfFree(includePath);
	}
	gpfFree(includePath);

	if (closedir(dir) == -1) {
		return gpfSystemError("%s", paramPath);
	}

	return 1;
}
#endif

/**
 * パラメータ行読み込み
 * @param line  パラメータ入力行
 * @param cfg   パラメータ定義
 * @param level レベル(インクルード時のネストの階層)
 * @return 合否
 */
int	gpfParseConfigLine(char *line, GPFConfigParam *cfg, int level)
{
	char parfile[MAXFILENAME];
	char *parameter    = NULL;
	char *value        = NULL;
	char *stat         = NULL;
	char *invalidValue = NULL;
	int i = 0;
	int unkownFlag = 1;
	int	var = 0;

	if (strlen(line) >= MAX_STRING_LEN)
		return gpfError("buffer over flow[%d] %s", MAX_STRING_LEN, line);

	/* コメントを取り除き、「項目{.種別} = 値」の形式でパースする */
	gpfLRtrim(line, GPF_CFG_LTRIM_CHARS);

	if (line[0] == '#')	return 1;
	if (line[0] == ';')	return 1;
	if (strlen(line) < 3)	return 1;

	parameter	= line;
	value		= strstr(line, "=");

	if (NULL == value)
		return 0;

	*value = '\0';
	value++;

	gpfLtrim(value, GPF_CFG_LTRIM_CHARS);
	gpfRtrim(value, GPF_CFG_RTRIM_CHARS);

	gpfRtrim(parameter, GPF_CFG_RTRIM_CHARS);
	stat = strstr(parameter, ".");
	if (stat != NULL)
	{
		*stat = '\0';
		stat++;
		gpfDebug("param: [%s][%s] val [%s]", parameter, stat, value);

		if (*stat == '\0')
			return gpfError("stat parameter is null : %s", parameter);
	} 
	else
	{
		gpfDebug("param: [%s] val [%s]", parameter, value);
	}

	for (i = 0; value[i] != '\0'; i++)
	{
		if  (value[i] == '\n')
		{
			value[i] = '\0';
			break;
		}
	}

	/* パラメータリストから項目に一致するパラメータを順にパース */
	for (i = 0; cfg[i].parameter != 0; i++)
	{
		if (strcmp(cfg[i].parameter, parameter))
			continue;

		unkownFlag = 0;
		gpfDebug("configuration parameter: '%s' = '%s'", parameter, value);

		if (cfg[i].type == TYPE_INT)
		{
			invalidValue = value;
			var = strtol(value, &invalidValue, 10);  
			if (*invalidValue != '\0')
				return gpfError("invalid number '%s' = '%s'", parameter, value);
				
			if ( var < cfg[i].min )
				return gpfError("limit error %s[%d] < %d", parameter, var, cfg[i].min);
			else if ( cfg[i].max && var > cfg[i].max ) 
				return gpfError("limit error %s[ %d..%d]", parameter, cfg[i].min, cfg[i].max);
		}
		else if ( cfg[i].type == TYPE_BOOL )
		{
			if (strcmp("true", value) == 0) 
				var = 1;
			else if (strcmp("false", value) == 0) 
				var = 0;
			else
				return gpfError("invalid value [true|false] : %s", value);
		}

		if (cfg[i].function != 0)
		{
			if (cfg[i].function(cfg[i].variable, parameter, stat, value, var) == 0)
				return 0;
		}
		else if ( cfg[i].type == TYPE_INT || cfg[i].type == TYPE_BOOL)
		{
			*(int *)(cfg[i].variable) = var;
		}
		else
		{
			*(char **)cfg[i].variable = strdup(value);
		}
	}

	if (unkownFlag == 1)
		return gpfError("unkown parameter : %s", parameter);
		
	return 1;
}

/**
 * コレクター構造体のパラメータ登録
 * @param schedule スケジュール構造体
 * @param param    パラメータ名
 * @param stat     採取種別(HW,...)
 * @param str      入力文字列
 * @param val      入力数値
 * @return 合否
 */
int gpfSetCollector (GPFSchedule *schedule, char *param, char *stat, char *str, int val)
{
	GPFCollector *collector = NULL;

	if ((collector = gpfFindAndAddCollector(schedule, stat)) == NULL)
		return 0;

	if (strcmp(param, "STAT_ENABLE") == 0)
	{
		collector->statEnable = val;
	}
	else if (strcmp(param, "BUILD") == 0)
	{
		collector->build = val;
	}
	else if (strcmp(param, "STAT_STDOUTLOG") == 0)
	{
		collector->statStdoutLog = val;
	}
	else if (strcmp(param, "STAT_INTERVAL") == 0)
	{
		collector->statInterval = val;
	}
	else if (strcmp(param, "STAT_TIMEOUT") == 0)
	{
		collector->statTimeout = val;
	}
	else if (strcmp(param, "STAT_MODE") == 0)
	{
		collector->statMode    = strdup(str);
	} 
	else 
	{
		return 0;
	}

	return 1;
}

/**
 * ジョブ構造体のパラメータ登録
 * @param schedule スケジュール構造体
 * @param param    パラメータ名
 * @param stat     採取種別(HW,...)
 * @param str      入力文字列
 * @param val      入力数値
 * @return 合否
 */
int gpfSetJob (GPFSchedule *schedule, char *param, char *stat, char *str, int val)
{
	GPFCollector *collector = NULL;
	GPFJob *job             = NULL;
	char *cmd        = NULL;
	char *ofile      = NULL;
	char *cycle_str  = NULL;
	char *step_str   = NULL;
	char delimiter[] = "'";
	char *token      = NULL;
	char *invalidVal = NULL;
	int cycle        = 0;
	int step         = 0;
	
	if ((collector = gpfFindAndAddCollector(schedule, stat)) == NULL)
		return 0;

	if (strcmp(param, "STAT_CMD") == 0)
	{
		/* parse cmd */
		if (*str == '\'' || *str == '"') 
			delimiter[0] = *str;
		else 
			goto lbl_delimiter_error_end;
		str++;
		cmd = str;
		if ((str = strstr(cmd, delimiter)) == NULL)
			goto lbl_delimiter_error_end;
		*str = '\0';

		/* parse ofile */
		str++;
		gpfLtrim(str, GPF_CFG_LTRIM_CHARS);
		if (*str == '\0')
			goto lbl_parse_end;
		else if (*str != ',')
			goto lbl_delimiter_error_end;
		str ++;
		ofile = str;
		delimiter[0] = ',';
		str = strstr(str, delimiter);
		if (str == NULL)
		{
			gpfLRtrim(ofile, GPF_CFG_LTRIM_CHARS);
			goto lbl_parse_end;
		}
		else
		{
			gpfLtrim(str, GPF_CFG_LTRIM_CHARS);
			if (*str != ',')
				goto lbl_delimiter_error_end;
		}
		*str = '\0';
		gpfLRtrim(ofile, GPF_CFG_RTRIM_CHARS);
		str ++;

		/* parse cycle */
		gpfLtrim(str, GPF_CFG_LTRIM_CHARS);
		cycle_str = str;
		delimiter[0] = ',';
		str = strstr(str, delimiter);
		if (str == NULL)
		{
			gpfLRtrim(cycle_str, GPF_CFG_RTRIM_CHARS);
			cycle = strtol(cycle_str, &invalidVal, 10);  
			if (*invalidVal != '\0' || *cycle_str == '\0' )
				goto lbl_delimiter_error_end;

			goto lbl_parse_end;
		}
		else
		{
			gpfLtrim(str, GPF_CFG_LTRIM_CHARS);
			if (*str != ',')
				goto lbl_delimiter_error_end;
		}
		*str = '\0';
		gpfLRtrim(cycle_str, GPF_CFG_RTRIM_CHARS);
		cycle = strtol(cycle_str, &invalidVal, 10);  
		if (*invalidVal != '\0' || *cycle_str == '\0' )
			goto lbl_delimiter_error_end;
		str ++;

		/* parse step */
		gpfLtrim(str, GPF_CFG_LTRIM_CHARS);
		step_str = str;
		delimiter[0] = ',';
		str = strstr(str, delimiter);
		if (str == NULL)
		{
			gpfRtrim(ofile, GPF_CFG_RTRIM_CHARS);
			step = atoi(step_str);
			goto lbl_parse_end;
		}
		else
		{
			goto lbl_delimiter_error_end;
		}

		if (str == NULL)
			goto lbl_parse_end;
	} 
	else 
	{
		return 0;
	}

lbl_parse_end:

	if ( ofile != NULL )
	{
//		if ( strstr( ofile, GPF_FILE_SEPARATORS ) != NULL || strcmp( ofile, "" ) == 0 )
		if ( strcmp( ofile, "" ) == 0 )
			goto lbl_delimiter_error_end;
	}
	
	if ((job = gpfAddJob(collector, cmd)) == NULL)
		return 0;

	if ( ofile != NULL )
	{
		job->ofile = strdup( ofile );
		job->cycle = cycle;
		job->step  = step;
	}
	
	return 1;

lbl_delimiter_error_end:
	return gpfError("delimiter error %s %s", param, stat );
}

/**
 * 読み込んだパラメータのバリデーション
 * @param schedule スケジュール構造体
 * @return 合否
 */
int gpfCheckSchedule (GPFSchedule *schedule) 
{
	int rc = 1;
	GPFCollector *collector;
	GPFJob *job;

	if (schedule == NULL)
		return gpfError("schedule is null");

	if (schedule->hanodeEnable == 1 && schedule->hanodeCmd == NULL)
	{
		rc = gpfError("Parameter HANODE_CMD must specified");
	}
	if (schedule->postEnable == 1 && schedule->postCmd == NULL)
	{
		rc = gpfError("Parameter POST_CMD must specified");
	}
	if (schedule->remhostEnable == 1)
	{
		if (schedule->postEnable == 1)
			rc = gpfError("Both POST_ENABLE, REMHOST_ENABLE parameter cannot be set to true");

		if (schedule->urlCM == NULL)
			rc = gpfError("Parameter URL_CM must specified");

		if (schedule->urlPM == NULL)
			rc = gpfError("Parameter URL_PM must specified");

		if (schedule->siteKey == NULL)
			rc = gpfError("Parameter SITE_KEY must specified");
	}

	if (schedule->proxyEnable == 1)
	{
		if (schedule->proxyHost == NULL)
			rc = gpfError("Parameter PROXY_HOST must specified");
	}

	for (collector = schedule->collectorStart; 
		collector != NULL; 
		collector = collector->next) 
	{
		if (collector->statTimeout == 0)
			collector->statTimeout = collector->statInterval;

		if (collector->statMode == NULL || strlen(collector->statMode) == 0)
		{
			gpfFree(collector->statMode);
			collector->statMode = strdup("concurrent");
		}
		else if (strcmp(collector->statMode, "concurrent") != 0 
			&& strcmp(collector->statMode, "serial") != 0)
		{
			rc = gpfError(
				"Parameter STAT_MODE.%s must be \"concurrent\" or \"serial\"",
				collector->statName);
		}

		for (job = collector->jobStart; 
			job != NULL; 
			job = job->next) 
		{
			if (job->cmd == NULL || strlen(job->cmd) == 0)
			{
				rc = gpfError(
					"Parameter CMD of STAT_CMD.%s must specified", 
					collector->statName);
			}
		}
	}

	return rc;
}

/**
 * SSLライセンスファイルの読み込み
 * @param config SSLライセンス構造体
 * @param paramPath パラメータパス
 * @return 合否
 */
int gpfLoadSSLLicense( GPFSSLConfig *sslConfig, char *paramPath)
{
	int result = 0;

	GPFConfigParam cfg[] =
	{
/*           PARAMETER      ,VAR    ,FUNC,  TYPE(0i,1s), MANDATORY, MIN, MAX
*/
		{"HOSTNAME", &(sslConfig->hostname), 0, TYPE_STRING, PARM_MAND, 0, 0},
		{"EXPIRE",   &(sslConfig->expired),  0, TYPE_STRING, PARM_MAND, 0, 0},
		{"CODE",     &(sslConfig->code),     0, TYPE_STRING, PARM_MAND, 0, 0},
		{0}
	};

	sslConfig->hostname = NULL;
	sslConfig->expired  = NULL;
	sslConfig->code     = NULL;

	if ( (result = gpfParseConfigFile(paramPath, cfg, 0)) == 0) 
	{
		return 0;
	}
	
	if ( sslConfig->hostname == NULL ) {
		return gpfError("SSL License load error %s: HOSTNAME not found", paramPath);
	} else if ( sslConfig->expired == NULL ) {
		return gpfError("SSL License load error %s: EXPIRED not found", paramPath);
	} else if ( sslConfig->code == NULL ) {
		return gpfError("SSL License load error %s: CODE not found", paramPath);
	}
	return 1;
}

