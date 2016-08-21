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
#include "gpf_param.h"
#include "gpf_log.h"
#include "gpf_getopt.h"
#include "mutexs.h"
#include "getperfsoap.h"

char *gpfHelpMessage[] = {
	"getperfsoap [--send(-s)|--get(-g)] [--config(-c) getperf.cfg]",
	"            filename.zip",
	"Options:",
	"  -s --send                 send data",
	"  -g --get                  get data",
	"  -c --config <getperf.cfg> config file",
	"  <filename.zip>",
	0 /* end of text */
};

int main ( int argc, char **argv )
{
	int rc = 0;
	int option;
	int waitSec           = GPF_CHECK_LICENSE_INTERVAL;
	int retry             = 0;
	int sendFlag          = 0;
	int getFlag           = 0;
	long timestamp        = 0;
	char *configFile      = NULL;
	char *zipfile         = NULL;
	char *eol             = NULL;
	GPFConfig *config     = NULL;
	GPFSchedule *schedule = NULL;

	GCON = NULL;

	while (1)
	{
		static struct gpf_option longOptions[] =
		{
			{ "send",     gpf_no_argument,       0, 's' },
			{ "get",      gpf_no_argument,       0, 'g' },
			{ "config",   gpf_required_argument, 0, 'c' },
			{0, 0, 0, 0}
		};
		int optionIndex = 0;
		option = gpf_getopt_long (argc, argv, "sgc:", longOptions, &optionIndex);

		if ( option == -1 )
			break;

		switch ( option )
		{
		case 's':
			sendFlag   = 1;
			break;

		case 'g':
			getFlag    = 1;
			break;

		case 'c':
			configFile = gpf_optarg;
			break;

		case '?':
		case 'h':
		default:
			gpfUsage ( gpfHelpMessage );
			exit(-1);
		}
	}

	if ( gpf_optind + 1 == argc )
		zipfile = argv[gpf_optind++];

	if ( (rc = gpfInitAgent( &config, argv[0], configFile )) == 0)
		exit (-1);

	/* If PROXY_ENABLE is true and PROXY_HOST is if blank (NULL), Proxy settings to apply environment variable; HTTP_PROXY. */
	/* It PROXY_ENABLE is false, Proxy setting is disable even if an environment variable has been set. */
	schedule = config->schedule;
	if (schedule->proxyEnable == 1 && strcmp(schedule->proxyHost, "") == 0) {
		gpfCheckHttpProxyEnv( &(config->schedule) );
	}

	config->logConfig->logLevel = GPF_DEFAULT_LOG_LEVEL;
	/* config->logConfig->logLevel = schedule->logLevel; */
	gpfDebug("siteKey=%s", config->schedule->siteKey);
	gpfDebug("urlCM=%s",   config->schedule->urlCM);
	gpfDebug("urlPM=%s",   config->schedule->urlPM);
	gpfDebug("host=%s",    config->host);
	gpfDebug("cacert=%s",  config->cacertFile);
	gpfDebug("clkey=%s",   config->clkeyFile);

	if ( sendFlag == getFlag || zipfile == NULL )
	{
		gpfUsage( gpfHelpMessage );
		exit(-1);
	}
	else
#ifdef _WINDOWS
/* Time-out is not implemented in the case of Windows, because it implemented the agent side */
	{
		if ( sendFlag == 1 )
		{
			for ( retry = 0; retry < GPF_SOAP_RETRY; retry ++ )
			{
				rc = gpfReserveSender( config, zipfile );
				if ( rc == 1 )
				{
					if ( ( rc = gpfSendData( config, zipfile ) ) == 1 )
						gpfNotice("[Sended] %s", zipfile);
					break;
				}

				gpfError("send data failed retry %d/%d", retry +1, GPF_SOAP_RETRY);
				if ( waitSec > 0 )
				{
					sleep( waitSec );
				}
			}
		}
		else if ( getFlag == 1 )
		{
			for ( retry = 0; retry < GPF_SOAP_RETRY; retry ++ )
			{
				if ( ( rc = gpfDownloadCertificate( config, timestamp ) ) == 1 )
				{
					gpfNotice("[Saved] %s", zipfile);
					break;
				}
				gpfError("get data failed retry %d/%d", retry + 1, GPF_SOAP_RETRY);
				sleep( waitSec );
			}
		}
	}
#else
/* In the case of Linux, Create the child process and detect the time-out. */
	{
		pid_t pid = 0;
		if ( (pid = fork()) < 0 )
		{
			gpfSystemError("fork failed");
			exit(-1);
		}
		if ( pid == 0 )
		{
			if ( sendFlag == 1 )
			{
				for ( retry = 0; retry < GPF_SOAP_RETRY; retry ++ )
				{
					rc = gpfReserveSender( config, zipfile );
					if ( rc == 1 )
					{
						if ( ( rc = gpfSendData( config, zipfile ) ) == 1 )
							gpfNotice("[Sended] %s", zipfile);
						break;
					}

					gpfError("send data failed retry %d/%d", retry +1, GPF_SOAP_RETRY);
					if ( waitSec > 0 )
					{
						sleep( waitSec );
					}
				}
			}
			else if ( getFlag == 1 )
			{
				for ( retry = 0; retry < GPF_SOAP_RETRY; retry ++ )
				{
					if ( ( rc = gpfDownloadCertificate( config, timestamp ) ) == 1 )
					{
						gpfNotice("[Saved] %s", zipfile);
						break;
					}
					gpfError("get data failed retry %d/%d", retry + 1, GPF_SOAP_RETRY);
					sleep( waitSec );
				}
			}
			exit( rc );
		}
		else
		{
			int times, status, check;

			for (times = 0; times < GPF_SOAP_CMD_TIMEOUT; times ++)
			{
				sleep(1);
				if ( (check = waitpid( pid, &status, WNOHANG )) < 0 )
				{
					gpfSystemError("waitpid(%d)=%d", pid, check);
					exit(-1);
				}
				if ( check > 0 )
				{
					rc = WEXITSTATUS( status );
					break;
				}
			}
			if ( times >= GPF_SOAP_CMD_TIMEOUT && gpfCheckProcess( pid, "getperfsoap" ))
			{
				gpfKill( pid );
				rc = -1;
			}
		}
	}
#endif

	gpfRemoveDir( config->workDir );

	exit ( ( rc == 1) ? 0 : -1 );
}
