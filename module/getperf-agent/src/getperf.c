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
#include "gpf_process.h"
#include "getperf.h"

char *gpfHelpMessage[] = {
	"getperf [-c, --config=<file>]",
	"        [-s, --stat=<HW|JVM|...>]",
	"        [-b, --background]",
	"Options:",
	"  --config </home/ptune/getperf.cfg> It performs by the specified directory.",
	"  --statid <HW|JVM|...>  Agent run the specified category once.",
	"  --background  [Windows only] Agent run as background service.",
	0 /* end of text */
};

int main ( int argc, char **argv )
{
	int rc = 0;
	int option;
	struct stat	  sb;
	int mode                = GPF_PROCESS_RUN;
	pid_t exitPid           = 0;
	int timeout             = 0;
	int backgroundFlag      = 0;
	char *configFile        = NULL;
	char *statName          = NULL;
	GPFConfig *config       = NULL;
	GPFSchedule *schedule   = NULL;
	GPFCollector *collector = NULL;

	GCON = NULL;

	while (1)
	{
		static struct gpf_option longOptions[] =
		{
			{ "config",    gpf_required_argument, 0, 'c' },
			{ "stat",      gpf_required_argument, 0, 's' },
			{ "background",gpf_no_argument,       0, 'b' },
			{0, 0, 0, 0}
		};
		int optionIndex = 0;
		option = gpf_getopt_long (argc, argv, "c:s:b", longOptions, &optionIndex);

		if ( option == -1 )
			break;

		switch ( option )
		{
		case 'c':
			configFile = gpf_optarg;
			break;

		case 's':
			statName = gpf_optarg;
			break;

		case 'b':
			backgroundFlag = 1;
			break;

		case '?':
		case 'h':
		default:
			gpfUsage ( gpfHelpMessage );
			exit(-1);
		}
	}
	mode = GPF_PROCESS_RUN;

	if ( (rc = gpfInitAgent( &config, argv[0], configFile, mode )) == 0)
	{
		gpfMessage( GPF_MSG002E, GPF_MSG002 );
		exit (-1);
	}
	schedule = config->schedule;

	/* If PROXY_ENABLE is true and PROXY_HOST is if blank (NULL), Proxy settings to apply environment variable; HTTP_PROXY. */
	/* It PROXY_ENABLE is false, Proxy setting is disable even if an environment variable has been set. */
	if (schedule->proxyEnable == 1 && strcmp(schedule->proxyHost, "") == 0) {
		gpfCheckHttpProxyEnv( &schedule );
	}

	if ( schedule->collectorStart == NULL )
	{
		gpfMessage( GPF_MSG002E, GPF_MSG002 );
		exit (-1);
	}

	GCON = config;
	if ( ( rc = gpfOpenLog( config, config->programName ) ) == 0 )
		exit (-1);
	gpfWarn("Start %s v%s (build %d)", APPLICATION_NAME, GPF_VERSION, GPF_BUILD);
	gpfSetSignal();

#if defined _WINDOWS
	if ( backgroundFlag == 1)
	{
		service_start();
		exit(0);
	}
#endif

	if ( statName != NULL )
	{
		time_t currentTime = 0;
		GPFTask *task                 = NULL;
		config->module = 'C';

		config->mode = GPF_PROCESS_RUN;
		if ( !gpfCheckServiceExist( config, config->pidFile, &exitPid ) )
		{
			if ( !gpfPrepareCollector( config ) )
			{
				gpfFatal( "collector pre check ... NG" );
			}
			config->mode = GPF_PROCESS_RUN;
		}

		currentTime = time( NULL );
		if ( gpfCheckTimer( config, currentTime ) == 0 )
		{
			gpfFatal( "runnable collector not exist" );
		}

		if ( ( collector = gpfFindCollector( schedule, statName) ) != NULL )
		{
			GPFThreadId child = 0;
			ght_hash_table_t *collectorPids = config->collectorPids;

			if ( collector->odir == NULL )
			{
				gpfFatal( "collector %s isn't runnable", collector->statName );
			}

			task = gpfCreateTask( config, collector );
			gpfShowTask( task );
			child = gpfGetThreadId();
			rc = gpfInsertPids( collectorPids, task, child );

			if ( !gpfRunCollector( task ) )
			{
				gpfFatal( "run collector ... NG" );
			}
		}
		else
		{
			gpfFatal( "unkown statid : %s", statName );
		}

	}
	else
	{
		int timeout = 0;
		if ( gpfCheckServiceExist(config, config->pidFile, &exitPid ) )
		{
			/* Process pid=%d is running */
			gpfMessage( GPF_MSG003E, GPF_MSG003, exitPid );
			/* Stop the process or check {GETPERF_HOME}/_wk/_pid file */
			gpfMessage( GPF_MSG008E, GPF_MSG008 );
			exit( -1 );
		}

		schedule->pid = getpid();
		gpfDebug("write _pid_getperf[%d]", schedule->pid );
		gpfWriteWorkFileNumber(config, "_pid_getperf", schedule->pid );

		gpfDebug( "run scheduler" );
		config->daemonFlag = 1;

		gpfRunScheduler( config );

		do
		{
			if ( timeout++ > EXIT_TIMEOUT_SCHEDULER)
				break;
			sleep(1);
		}
		while ( gpfCheckServiceExist(config, config->pidFile, &exitPid ) );
	}
	gpfRemoveWorkDir( config );

	exit (0);
}

