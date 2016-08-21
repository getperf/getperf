/* 
** GETPERF
** Copyright (C) 2009-2012 Getperf Ltd.
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
#include "gpf_admin.h"
#include "gpf_agent.h"
#include "ght_hash_table.h"
#include "gpf_soap_common.h"
#include "gpf_soap_admin.h"
// #include "json.h"
// #include "gpf_json.h"
#include "gpf_process.h"

//#include "getperf.h"
#if defined _WINDOWS
#include "gpf_service.h"
#else
#include "gpf_daemon.h"
#endif

char *gpfHelpMessage[] = {
	"Ussage :",
	"getperfctl [-c,--config=<file>]",
	"    [start|stop]",
	"    [install|remove] (Windows only)",
	"    [setup (Web service use only)",
	"        [-u,--user=<user>] [-p,--pass=<pass>] [-k,--key=<sitekey>]",
	"        [-s,--stat=<HW|JVM|...>]]",
	"",
	"Commands:",
	"    start   Run the agent in background.",
	"    stop    Stop the agent under running.",
	"(Windows only):",
	"    install Install Windows service of auto start.",
	"    remove  Remove Windows service.",
	"(Web service only):",
	"    setup   Setup performance command by Web service.",
	"",
	"Options:",
	"    --config </home/ptune/getperf.cfg> It performs by the specified directory.",
	"(Web service only):",
	"    --user   Site administrator user id.",
	"    --pass   Site administrator user password.",
	"    --key    Site key.",
	"    --stat   Metrics(HW,JVM,...)",
	0 /* end of text */
};

#if defined _WINDOWS

int gpfRunInstallService( GPFSetupOption *options )
{
	int rc              = 0;
	GPFConfig *config   = NULL;
	char    *program    = options->program;
	char    *configPath = options->configPath;
	int     mode        = options->mode;

	if ( (rc = gpfInitAgent( &config, program, configPath, mode )) == 0)
	{
		gpfMessage( GPF_MSG002E, GPF_MSG002 );
		exit (-1);
	}
	
	if ( config )
	{
		char *programPath   = NULL;
		char *command       = NULL;
		char *logPath       = config->logConfig->logPath;
		char *parameterFile = config->parameterFile;

		programPath   = gpfCatFile( config->binDir, GPF_GETPERF, NULL );

		command = gpfDsprintf( command, "%s -c %s", programPath, parameterFile );

		rc = gpfCreateService( command );
		gpfFree( command );
		gpfFree( programPath );
	}
	return rc;
}

int gpfRunRemoveService( GPFSetupOption *options )
{
	int rc              = 0;
	GPFConfig *config   = NULL;
	char    *program    = options->program;
	char    *configPath = options->configPath;
	int     mode        = options->mode;

	if ( (rc = gpfInitAgent( &config, program, configPath, mode )) == 0)
	{
		gpfMessage( GPF_MSG002E, GPF_MSG002 );
		exit (-1);
	}
	
	if ( config )
	{
		rc = gpfRemoveService();
	}
	return rc;
}

#endif

int gpfRunStartService( GPFSetupOption *options )
{
	int rc              = 0;
	GPFConfig *config   = NULL;
	char    *program    = options->program;
	char    *configPath = options->configPath;
	int     mode        = options->mode;
	int timeout         = 0;
	pid_t exitPid       = 0;
	int child, exitCode;
	struct stat sb;

	if ( (rc = gpfInitAgent( &config, program, configPath, mode )) == 0)
	{
		gpfMessage( GPF_MSG002E, GPF_MSG002 );
		exit (-1);
	}
	
	/* プログラムが二重起動していたらエラーで終了 */
	if ( gpfCheckServiceExist(config, config->pidFile, &exitPid ) )
	{
		/* "既存のプロセスPID=%dを検出しました" */
		gpfMessage( GPF_MSG007E, GPF_MSG007, exitPid );
		/* "上記プロセスか、_pidファイルの有無を確認して下さい" */
		gpfMessage( GPF_MSG008E, GPF_MSG008 );
		exit( -1 );
	}

#if defined _WINDOWS

	rc = gpfStartService();

#else

	/* デバッグモードでない場合はプロセスをデーモン化 */
	if ( config )
	{
		char *programPath   = NULL;
		char *logPath       = config->logConfig->logPath;
		char *parameterFile = config->parameterFile;
		char *args[4];

		programPath   = gpfCatFile( config->binDir, GPF_GETPERF, NULL );

		args[0] = programPath;
		args[1] = "-c";
		args[2] = parameterFile;
		args[3] = 0;
		
		rc = gpfDaemonStart( programPath, args, logPath );
		gpfFree( programPath );
	}

#endif

	return rc;
}

int gpfRunStopService( GPFSetupOption *options )
{
	int rc              = 0;
	GPFConfig *config   = NULL;
	char    *program    = options->program;
	char    *configPath = options->configPath;
	int     mode        = options->mode;
	int timeout         = 0;
	pid_t exitPid       = 0;
	struct stat sb;
	
	if ( (rc = gpfInitAgent( &config, program, configPath, mode )) == 0)
	{
		gpfMessage( GPF_MSG002E, GPF_MSG002 );
		exit (-1);
	}

	if ( gpfCheckServiceExist( config, config->pidFile, &exitPid ) ) 
	{
		/* "既存のプロセスPID=%dを検出しました" */
		gpfMessage( GPF_MSG003E, GPF_MSG003, exitPid );

		/* 該当プロセスのローカルワークディレクトリに終了フラグファイルを立てる */
		if ( gpfWriteWorkFile( config, "_exitFlag", "STOP" ) == 0 )
		{
			gpfFatal( "Can't open %s", config->exitFlag );
		}

		/* 終了フラグファイルが消滅するまで待つ */
		gpfMessage( GPF_MSG004E, GPF_MSG004, EXIT_TIMEOUT_SCHEDULER );
		timeout = EXIT_TIMEOUT_SCHEDULER;
		while ( ( timeout-- ) > 0 ) 
		{
			if ( stat( config->exitFlag, &sb ) == 0 )
				break;
			sleep ( 1 );
		}

		/* タイムアウトしたらkillで強制終了する */
		if ( timeout == 0 && gpfCheckProcess( exitPid, NULL ) ) 
		{
			gpfKill( exitPid );
			/* "起動中のプロセス(%d)を強制停止しました" */
			gpfMessage( GPF_MSG005E, GPF_MSG005, exitPid );
		}
		rc = 1;
	} 
	else 
	{
		/* "起動中のプロセスは存在しません" */
		gpfMessage( GPF_MSG006E, GPF_MSG006 );
	}

#if defined _WINDOWS
	rc = gpfStopService();
#endif

	return rc;
}

int main ( int argc, char **argv )
{
	int rc = -1;
	int option;
	struct stat	  sb;
	int mode                = GPF_CMD_NONE;
	pid_t exitPid           = 0;
	int timeout             = 0;
	char *configFile        = NULL;
	char *statName          = NULL;
	GPFConfig *config       = NULL;
	char *cmd               = NULL;
	GPFSetupConfig *setup   = gpfCreateSetupConfig();
	GPFSetupOption *options = gpfCreateSetupOption();
	
	if ( argc >= 2 )
	{
		options->program = strdup ( argv[0] );
		cmd              = strdup( argv[1] );
		options->cmd     = cmd;
	}
	else
	{
		gpfUsage ( gpfHelpMessage );
		goto errata;
	}
	
	if ( argc >= 3 )
	{
		while (1)
		{
			static struct gpf_option longOptions[] =
			{
				{ "config", gpf_required_argument, 0, 'c' },
				{ "home",   gpf_required_argument, 0, 'h' },
				{ "user",   gpf_required_argument, 0, 'u' },
				{ "pass",   gpf_required_argument, 0, 'p' },
				{ "key",    gpf_required_argument, 0, 'k' },
				{ "stat",   gpf_required_argument, 0, 's' },
				{0, 0, 0, 0}
			};
			int optionIndex = 0;
			option = gpf_getopt_long (argc, argv, "c:h:u:p:k:s:", longOptions, &optionIndex);
	
			if ( option == -1 )
				break;

			switch ( option )
			{
			case 'c':
				options->configPath = strdup( gpf_optarg );
				break;

			case 'h':
				options->home = strdup( gpf_optarg );
				break;

			case 'u':
				options->userName = strdup( gpf_optarg );
				break;

			case 'p':
				options->password = strdup( gpf_optarg );
				break;

			case 'k':
				options->siteKey = strdup( gpf_optarg );
				break;

			case 's':
				options->statName = strdup( gpf_optarg );
				break;

			case '?':
			default:
				gpfUsage ( gpfHelpMessage );
				goto errata;
			}
		}
	}

	if ( strcmp( cmd, "start" ) == 0 )
	{
		options->mode = GPF_CMD_START;
		rc = gpfRunStartService( options );
	} 
	else if ( strcmp( cmd, "stop" ) == 0 )
	{
		options->mode = GPF_CMD_STOP;
		rc = gpfRunStopService( options );
	} 
	else if ( strcmp( cmd, "install" ) == 0 )
	{
		options->mode = GPF_CMD_INSTALL;
		#if defined _WINDOWS
			rc = gpfRunInstallService( options );
		#else
			/* Windows環境のみで利用するコマンドです。詳細は Install.txt を参照して下さい */
			gpfMessage( GPF_MSG029E, GPF_MSG029 );
			rc = -1;
		#endif
	} 
	else if ( strcmp( cmd, "remove" ) == 0 )
	{
		options->mode = GPF_CMD_REMOVE;
		#if defined _WINDOWS
			rc = gpfRunRemoveService( options );
		#else
			/* Windows環境のみで利用するコマンドです。詳細は Install.txt を参照して下さい */
			gpfMessage( GPF_MSG029E, GPF_MSG029 );
			rc = -1;
		#endif
	} 
	else if ( strcmp( cmd, "setup" ) == 0 )
	{
		options->mode = GPF_CMD_SETUP;
		rc = gpfRunSetup( options );
	} 
	else
	{
		gpfUsage ( gpfHelpMessage );
		goto errata;
	}

	errata:
	gpfFreeSetupConfig( &setup );
	gpfFreeSetupOption( &options );
	
	exit( rc );
}
