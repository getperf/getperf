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
#include "gpf_param.h"
#include "gpf_log.h"
#include "md5.h"
#include "ght_hash_table.h"
#include "mutexs.h"
#include "gpf_agent.h"

static ZBX_MUTEX taskAccessFlag;
static ZBX_MUTEX gpfSoapAccessFlag;

/**
 * Registration of task management structure.
 * Hash key is the unsigned long type of thread ID, but libght does not 
 * support unsinged long. To manage a value greater than 32bit, 
 * SIGSEGV error, change the hash key to a string in sprintf.
 */ 
int gpfInsertPids( ght_hash_table_t *Pids, void *task, GPFThreadId threadKey )
{
	int rc = 0;
	char *pidkey = NULL;

	pidkey = gpfDsprintf( pidkey, "%lu", threadKey );
	rc = ght_insert( Pids, task, sizeof(char) * strlen(pidkey), pidkey );
	if ( rc == -1 )
		gpfError( "duplicated pids" );
	if ( rc == -2 )
		gpfFatal( "pids buffer overflow" );

	gpfFree( pidkey );
	return ( rc == 0) ? 1 : 0;
}

/**
 * Search of task management structure of thread key
 */ 
void *gpfGetPids( ght_hash_table_t *Pids, GPFThreadId threadKey )
{
	char *pidkey = NULL;
	void *result;

	pidkey = gpfDsprintf( pidkey, "%lu", threadKey );
	result = ght_get( Pids, sizeof(char) * strlen(pidkey), pidkey );

	gpfFree( pidkey );
	return result;
}

/**
 * Deleting a task management structure of thread key.
 * If not exists, return NULL.
 */ 
void *gpfRemovePids( ght_hash_table_t *Pids, GPFThreadId threadKey )
{
	char *pidkey = NULL;
	void *result;

	pidkey = gpfDsprintf( pidkey, "%lu", threadKey );
	result = ght_remove( Pids, sizeof(char) * strlen(pidkey), pidkey );

	gpfFree( pidkey );
	return result;
}

/**
 * Initialization of the agent
 * ExecutePath ( execution path of getperf) is required . If you specify a relative 
 * path , automatically converted to an absolute path . If not specified configFile, 
 * a directory on one level of the execution path is initialized as the home directory , 
 * to load the getperf.ini. If mode is not of GPF_PROCESS_RUN, to initialize the 
 * semaphore for exclusive control .If you do not want to initialize the semaphore,
 * specify the GPF_PROCESS_INIT .
 */
int gpfInitAgent( GPFConfig **_config, char *executePath, char *configFile, int mode )
{
	char cwd[MAXFILENAME], programPath[MAXFILENAME], configPath[MAXFILENAME];
	char hostname[MAX_COMPUTERNAME_LENGTH];
	char *configName, *home  = NULL;
	char *eol                = NULL;
	char *binDir             = NULL;
	int rc = 0;
	GPFConfig     *config    = _config[0];
	GPFSSLConfig  *sslConfig = NULL;
	GPFSchedule   *schedule  = NULL;

	int i;
	for ( i = 0; i < MAX_COMPUTERNAME_LENGTH; i++ ) 
	{
		hostname[i] = '\0';
	}
	if ( !gpfGetHostname( hostname ) )
		gpfFatal( "can't check hostname" );
	
	if (getcwd(cwd, sizeof(cwd)) == NULL)
	{
		gpfSystemError("getcwd failed");
		goto errange;
	}
	if ( rel2abs( executePath, cwd, programPath, MAXFILENAME ) == NULL)
		return gpfError( "rel2abs %s failed", executePath );
	
	binDir = gpfGetParentPathAbs( programPath, 1 );
	
	if ( configFile != NULL)
	{
		if ( rel2abs( configFile, cwd, configPath, MAXFILENAME ) == NULL)
			return gpfError( "rel2abs %s failed", configFile );

		home = gpfGetParentPathAbs( configPath, 1 );
		eol  = strrchr( configFile, GPF_FILE_SEPARATOR );
		if ( eol != NULL ) 
			configName = eol + 1;
		else
			configName = configFile;
	}
	else
	{
		home       = gpfGetParentPathAbs( programPath, 2 );
		configName = "getperf.ini";
		gpfSnprintf( configPath, MAXFILENAME, "%s%s%s", home, GPF_FILE_SEPARATORS, configName );
	}

	if ( home == NULL)
	{
		gpfError( "can't check home" );
		goto errange;
	}

#if !defined(_WINDOWS)
	if ( strstr( home, " ") != NULL)
	{
		/* Unavailable to use the directory include blank for Home directory */
		gpfMessage( GPF_MSG061E, GPF_MSG061 );
		exit(-1);
		goto errange;
	}
#endif	

	if ( config == NULL )
	{
		if ( ( config = gpfCreateConfig( hostname, home, GETPERF_PROC_TITLE, programPath, binDir, 
			configName ) ) == NULL )
		{
			gpfError( "can't initialize config data" );
			goto errange;
		}
		GCON = config;
		_config[0] = config;
	}
	
	if ( config->schedule != NULL )
		gpfFreeSchedule( &(config->schedule) ) ;
	schedule = gpfCreateSchedule();
	if (! gpfLoadConfig( schedule, GPF_CONFIG_TYPE_FILE, configPath, NULL ) )
	{
		goto errange;
	}
	config->schedule = schedule;

	if ( config->sslConfig != NULL )
		gpfFreeSSLConfig( &(config->sslConfig) );
	sslConfig = gpfCreateSSLConfig();

	if ( mode == GPF_PROCESS_RUN )
	{
		if (! gpfLoadSSLLicense( sslConfig, config->licenseFile ) )
		{
			goto errange;
		}
	}
	config->sslConfig = sslConfig;

	gpfMakeDirectory( config->outDir );
	gpfMakeDirectory( config->workDir );
	gpfMakeDirectory( config->archiveDir );
	if ( config->schedule )
		config->localeFlag = config->schedule->logLocalize;
	
	config->managedPid = gpfGetProcessId();
	rc = 1;

	if ( mode == GPF_PROCESS_RUN )
	{
		if(!zbx_mutex_create_force(&taskAccessFlag, ZBX_MUTEX_TASK))
			gpfFatal("Unable to create mutex for task");
		if( !zbx_mutex_create_force( &gpfSoapAccessFlag, ZBX_MUTEX_SOAP ) )
			gpfFatal("Unable to create mutex for soap");
		gpfInfo( "[Lock Create] task = %d, soap =%d", taskAccessFlag, gpfSoapAccessFlag );
	}

errange:
	gpfFree( binDir );
	gpfFree( home );
	return rc;
}

/**
 * Check exit flag file
 */
char *gpfCheckExitFile( GPFConfig *config)
{
	char *exitFlag = config->exitFlag;
	char *buf      = NULL;
	FILE *file     = NULL;
	char line[MAX_BUF_LEN];
	struct stat stats;

	if ( stat( exitFlag, &stats) != 0)
	{
		goto errange;
	}

	if( (file = fopen(exitFlag, "r")) == NULL)
	{
		gpfSystemError("%s", exitFlag);
		goto errange;
	}

	if ( fgets(line, MAX_BUF_LEN, file) != NULL )
	{
		buf = strdup( line );
	}

errange:
	gpf_fclose(file);
	return buf;
}

/**
 * Check hostname
 */
int gpfCheckHostname( char *hostname )
{
	char *p = NULL;
	if ( hostname == NULL)
		return 0;
		
	gpfLRtrim(hostname, GPF_CFG_RTRIM_CHARS);
	p = hostname;
	if ( ( *p >= 'a' && *p <= 'z') || ( *p >= 'A' && *p <= 'Z') || ( *p >= '0' && *p <= '9') )
	{
		if ( strstr( p, GPF_FILE_SEPARATORS ) == NULL )
			return 1;
	}
	gpfError( "wrong host name : %s", hostname );
	return 0;
}

/**
 * Run HA status script, regist service name
 */
int gpfCheckHAStatus( GPFConfig *config)
{
	GPFSchedule *schedule = config->schedule;
	char line[MAX_BUF_LEN];
	char *scriptDir   = config->scriptDir;
	char *workDir     = config->workDir;
	int hanodeEnable  = schedule->hanodeEnable;
	char *hanodeCmd   = schedule->hanodeCmd;
	FILE *file        = NULL;
	char *serviceName = NULL;
	char *cmd         = NULL;
	char *outPath     = NULL;
	char *errPath     = NULL;
	pid_t child       = 0;
	int rc            = 1;

	if ( hanodeEnable == 1)
	{
		gpfNotice("[0] HA service Check =========================");
		if ( hanodeCmd == NULL)
		{
			gpfError( "HANODE_CMD parameter is null" );
		}
		else
		{
			int exitCode;
			cmd     = gpfCatFile( scriptDir, hanodeCmd, NULL );
			outPath = gpfCatFile( workDir, "hanode.txt", NULL );
			errPath = gpfCatFile( workDir, "hanode.err", NULL );

			unlink( outPath );
			unlink( errPath );
			
			if ( ( rc = gpfExecCommand(cmd, GPF_HANODE_CMD_TIMEOUT, 
				outPath, errPath, &child, &exitCode) ) == 0)
			{
				if( (file = fopen(errPath, "r")) != NULL)
				{
					while ( fgets(line, MAX_BUF_LEN, file) != NULL )
						gpfError( line );
					fclose( file );
				}
				goto errange;
			}

			if ( exitCode != 0 )
			{
				rc = 0;
			}
			else
			{
				if ( gpfReadWorkFile( config, "hanode.txt", &serviceName ) == 1 )
				{
					if ( (rc = gpfCheckHostname( serviceName ) ) == 1)
					{
						gpfNotice( "service check ... OK : %s", serviceName );
						gpfFree( config->serviceName );
						config->serviceName = strdup( serviceName );
					}
				}
			}
		}
		errange:

		if ( rc == 0 )
		{
			gpfError( "service check failed. use : %s", config->host);
			gpfFree( config->serviceName );
			config->serviceName = strdup( config->host );
		}

		gpfFree( cmd );
		gpfFree( outPath );
		gpfFree( errPath );
		gpfFree( serviceName );
	}
	return rc;
}

/**
 * Read {home}/ssl/License.txt, check license
 */
int gpfAuthLicense( GPFConfig *config, int expiredTime )
{
	_MD5_CTX ctx;
	unsigned char digest[16];
	char currentDate[16];
	int rc                  = 0;
	int i                   = 0;
	char *digestStr         = NULL;
	GPFSSLConfig *sslConfig = NULL;
	GPFSchedule *schedule   = NULL;

	if ( (sslConfig = config->sslConfig) == NULL )
		return 0;
	if ( (schedule = config->schedule) == NULL )
		return 0;
	if ( sslConfig->hostname == NULL || sslConfig->expired == NULL || sslConfig->code == NULL)
		return 0;

	// MD5Init( &ctx );
	// MD5Update( &ctx, (unsigned char *)(sslConfig->hostname), strlen(sslConfig->hostname) );
	// MD5Update( &ctx, (unsigned char *)(sslConfig->expired),  strlen(sslConfig->expired) );
	// MD5Update( &ctx, (unsigned char *)(schedule->siteKey),  strlen(schedule->siteKey) );
	// MD5Final( digest, &ctx );

	// digestStr = gpfDsprintf( digestStr, "%02x", digest[0] );
	// for ( i = 1; i < 16; i++ ) 
	// 	digestStr = gpfDsprintf( digestStr, "%s%02x", digestStr, digest[i] );

	// gpfDebug("digest key=%s", digestStr);
	// if (strcmp(digestStr, sslConfig->code) != 0)
	// {
	// 	gpfError( "License code error" );
	// 	goto errata;
	// }
	if (strcmp( config->host, sslConfig->hostname ) != 0 )
	{
		gpfError( "License host error(%s) : %s", sslConfig->hostname, config->host);
		goto errata;
	}

	gpfGetCurrentTime( -expiredTime, currentDate, GPF_DATE_FORMAT_YYYYMMDD);

	if ( strcmp(currentDate, sslConfig->expired) <= 0 )
		rc = 1;

	if ( expiredTime == 0 ) 
	{
		gpfNotice( "[Check] License[%s, %s] > %s : %s", 
			sslConfig->hostname, sslConfig->expired, currentDate, (rc == 1)?"OK":"NG" );
	}
	
	errata:
	gpfFree( digestStr );
	return rc;
}

/**
 * Extract license file
 */
int gpfUnzipSSLConf( GPFConfig *config )
{
	int rc        = 0;
	char line[MAX_BUF_LEN];
	char *command = NULL;
	char *zipPath, *baseDir, *passwd, *exePath, *outPath, *errPath;
	pid_t child   = 0;
	int exitCode  = 0;
	FILE *file    = NULL;
	
	if ( config->schedule == NULL )
		return 0;

	exePath = gpfCatFile( config->binDir, GPF_GETPERFZIP, NULL );
	zipPath = gpfCatFile( config->workCommonDir, "sslconf.zip", NULL );
	baseDir = strdup( config->home );
	passwd  = strdup( config->schedule->siteKey );
	
#if defined USE_GETPERFZIP_COMMAND

	command = gpfDsprintf( command, "%s -u -b %s %s", exePath, baseDir, zipPath );

	outPath = gpfCatFile( config->workDir, "getperfzip.txt", NULL );
	errPath = gpfCatFile( config->workDir, "getperfzip.err", NULL );

	unlink( outPath );
	unlink( errPath );
	if ( ( rc = gpfExecCommand(command, GPF_ZIP_CMD_TIMEOUT, outPath, errPath, &child, &exitCode) ) == 0)
	{
		if( (file = fopen(outPath, "r")) != NULL)
		{
			while ( fgets(line, MAX_BUF_LEN, file) != NULL )
			{
				gpfNotice( line );
			}
			gpf_fclose( file );
		}

		if( (file = fopen(errPath, "r")) != NULL)
		{
			while ( fgets(line, MAX_BUF_LEN, file) != NULL )
			{
				gpfError( line );
			}
			gpf_fclose( file );
		}
	}
	gpfInfo( "[Exec][RC=%d] %s", rc, command );

#else
	if ( ( rc = unzipDir( zipPath, baseDir, NULL ) ) == 0 )
	{
		gpfError("Unable unzip %s", zipPath );
	}

#endif
	
	gpfFree( exePath );
	gpfFree( zipPath );
	gpfFree( baseDir );
	gpfFree( passwd );

#if defined USE_GETPERFZIP_COMMAND

	gpfFree( command );
	gpfFree( outPath );
	gpfFree( errPath );

#endif
	
	return rc;
}

/**
 * Send SOAP attachement file
 */
int gpfExecSOAPCommandPM( GPFConfig *config, char *option, char *filePath )
{
	int rc        = 0;
	char *line    = NULL;
	char *command = NULL;
	char *exePath, *outPath, *errPath, *param;
	pid_t child   = 0;
	int exitCode  = 0;
	FILE *file    = NULL;
	
	if ( config->schedule == NULL )
		return 0;
	
	line = gpfMalloc( line, MAX_BUF_LEN );
	param = config->parameterFile;
	exePath = gpfCatFile( config->binDir, GPF_GETPERFSOAP, NULL );
	command = gpfDsprintf( command, "%s %s -c %s %s", exePath, option, param, filePath );
	gpfDebug( "[Exec] %s", command );
	outPath = gpfCatFile( config->workDir, "getperfsoap.txt", NULL );
	errPath = gpfCatFile( config->workDir, "getperfsoap.err", NULL );

	if ( config->mode == GPF_PROCESS_RUN )
	{
		gpfDebug( "[S] LOCK SOAP");
		zbx_mutex_lock( &gpfSoapAccessFlag );
	}
	unlink( outPath );
	unlink( errPath );
	gpfNotice( "[Exec]\n%s", command );
	if ( ( rc = gpfExecCommand(command, GPF_SOAP_CMD_TIMEOUT, outPath, errPath, &child, &exitCode) ) == 0)
	{
		if( (file = fopen(outPath, "r")) != NULL)
		{
			while ( fgets(line, MAX_BUF_LEN, file) != NULL )
			{
				gpfNotice( line );
			}
			gpf_fclose( file );
		}

		if( (file = fopen(errPath, "r")) != NULL)
		{
			while ( fgets(line, MAX_BUF_LEN, file) != NULL )
			{
				gpfError( line );
			}
			gpf_fclose( file );
		}
	}
	if ( config->mode == GPF_PROCESS_RUN )
	{
		gpfDebug( "[S] UNLOCK SOAP");
		zbx_mutex_unlock( &gpfSoapAccessFlag );
	}

	gpfFree( line );
	gpfFree( exePath );
	gpfFree( command );
	gpfFree( outPath );
	gpfFree( errPath );

	return rc;
}

/**
 * Run post command
 */
int gpfExecPostCommand( GPFConfig *config, char *filePath )
{
	GPFSchedule *schedule = config->schedule;
	int rc        = 0;
	char *line    = NULL;
	char *command = NULL;
	char *outPath, *errPath;
	pid_t child   = 0;
	int exitCode  = 0;
	FILE *file    = NULL;
	
	if ( config->schedule == NULL )
		return 0;
	
	line = gpfMalloc( line, MAX_BUF_LEN );
	command = gpfStringReplace( schedule->postCmd, "_zip_", filePath );
	
	gpfDebug( "[Exec] %s", command );
	outPath = gpfCatFile( config->workDir, "postcmd.txt", NULL );
	errPath = gpfCatFile( config->workDir, "postcmd.err", NULL );

	if ( config->mode == GPF_PROCESS_RUN )
	{
		gpfDebug( "[S] LOCK SOAP");
		zbx_mutex_lock( &gpfSoapAccessFlag );
	}
	unlink( outPath );
	unlink( errPath );
	if ( ( rc = gpfExecCommand(command, GPF_SOAP_CMD_TIMEOUT, outPath, errPath, &child, &exitCode) ) == 0)
	{
		if( (file = fopen(outPath, "r")) != NULL)
		{
			while ( fgets(line, MAX_BUF_LEN, file) != NULL )
			{
				gpfNotice( line );
			}
			gpf_fclose( file );
		}

		if( (file = fopen(errPath, "r")) != NULL)
		{
			while ( fgets(line, MAX_BUF_LEN, file) != NULL )
			{
				gpfError( line );
			}
			gpf_fclose( file );
		}
	}
	gpfInfo( "[Exec][RC=%d] %s", rc, command );
	if ( config->mode == GPF_PROCESS_RUN )
	{
		gpfDebug( "[S] UNLOCK SOAP");
		zbx_mutex_unlock( &gpfSoapAccessFlag );
	}
	
	gpfFree( line );
	gpfFree( command );
	gpfFree( outPath );
	gpfFree( errPath );

	return rc;
}

/**
 * Download license file, check license
 */
int gpfCheckLicense( GPFConfig *config, int expiredTime )
{
	struct stat st;
	int  rc     = 0;
	int  retry  = GPF_CHECK_LICENSE_CNT;
	int  authOk = 0;
	char licenseFile[MAXFILENAME];
	GPFSSLConfig *sslConfig = NULL;

	while ( authOk == 0 && retry > 0 )
	{
		authOk = gpfAuthLicense( config, expiredTime );

		if ( authOk == 0)
		{
			gpfError( "Auth error resync License.txt(%d)", retry );

			if (! gpfExecSOAPCommandPM( config, "--get" , "sslconf.zip" ) )
			{
				gpfError( "REMHOST_LICENSE Web Service failed" );
			}
			else if (! gpfUnzipSSLConf( config ) )
			{
				gpfError( "Unzip sslconf.zip failed" );
			}
			else
			{
				sslConfig = gpfCreateSSLConfig();
				if (! gpfLoadSSLLicense( sslConfig, config->licenseFile ) )
				{
					gpfFreeSSLConfig( &sslConfig );
					gpfError( "can't load ssl license" );
				}
				else
				{
					gpfFreeSSLConfig( &(config->sslConfig) );
					config->sslConfig = sslConfig;
					authOk = gpfAuthLicense( config, expiredTime );
					break;
				}
			}
		} 
		if ( retry != GPF_CHECK_LICENSE_CNT )
			sleep(GPF_CHECK_LICENSE_INTERVAL);

		retry --;
	}

	return authOk;
}

/**
 * Check currTime time, set executable schedule, 
 * return executable schedule number
 */
int gpfCheckTimer( GPFConfig *config, time_t currTime )
{
	GPFSchedule  *schedule  = NULL;
	GPFCollector *collector = NULL;
	int interval;
	time_t nextTime;
	int rc = 0;
	
	if ( !( schedule = config->schedule ) )
		return gpfError( "Schedule is null" );

	if ( !( collector = schedule->collectorStart ) )
		return gpfError( "Collector is null" );

	while( collector != NULL )
	{
		interval = collector->statInterval;
		nextTime = collector->nextTimestamp;

		if ( collector->statEnable == 1 && interval > 0 && nextTime <= currTime )
		{
			time_t ajustTime = interval * (time_t)(currTime/interval);
			rc ++;
			gpfDebug( "[S]Collector[%s][%d] READY", collector->statName, interval );
			collector->status        = GPF_PROCESS_WAIT;
			collector->nextTimestamp = currTime + interval;
			gpfGetTimeString( ajustTime, collector->dateDir, GPF_DATE_FORMAT_YYYYMMDD );
			gpfGetTimeString( ajustTime, collector->timeDir, GPF_DATE_FORMAT_HHMISS );
			gpfFree( collector->odir );
			collector->odir = gpfCatFile( config->outDir, collector->statName, 
				collector->dateDir, collector->timeDir, NULL );
		}
		else
		{
			gpfDebug( "[S]Collector[%s] WAIT[%d]", collector->statName, nextTime - currTime );
		}
		collector = collector->next;
	}
	return rc;
}

/**
 * Pre operation of collector execute
 */
int gpfPrepareCollector( GPFConfig *config )
{
	GPFSchedule *schedule = config->schedule;
	
	gpfNotice("[S] CHECK ==================");
	if ( !gpfCheckHAStatus( config ) )
		return gpfError( "Check HA service ... NG" );
	
	if (schedule->remhostEnable == 1 )
	{
		if ( !gpfCheckLicense( config, 0 ) )
			return gpfError( "Check License ... NG" );
	}

	if ( !gpfCheckDiskUtil( config ) )
		return gpfError( "Check Diskfree ... NG" );

	return 1;
}

/**
 * Run scheduler
 * Comment out Windows INIT_CHECK_MEMORY
 */
int gpfRunScheduler( GPFConfig *config )
{
	time_t currentTime, checkTime;
	int rc = 0;
	pid_t child;
	int processCount              = 0;
	time_t *collectorTimeout      = NULL;
	char *exitStatus              = NULL;
	ght_hash_table_t *collectorPids = NULL;
	GPFSchedule *schedule         = NULL;
	GPFCollector *collector       = NULL;
	/*	INIT_CHECK_MEMORY();	*/

	schedule = config->schedule;
	config->mode = GPF_PROCESS_RUN;
	collectorPids = config->collectorPids; // ght_create( GPF_MAX_COLLECTORS );
	checkTime = time(NULL);
	gpfWriteWorkFile( GCON, "_running_flg", "" );

	while ( 1 )
	{
		pid_t child_pid = 0;
		currentTime = time( NULL );
		
		if ( ( exitStatus = gpfCheckExitFile( config ) ) != NULL )
		{
			gpfWarn( "Catch exit signal %s", exitStatus );
			gpfFree( exitStatus );
			config->mode = GPF_PROCESS_END;
			gpfStopProcess( config->managedPid );
			break;
		}

		if ( checkTime <= currentTime ) 
		{
			checkTime = currentTime + GPF_POLLER_INTERVAL;

			if ( gpfCheckTimer( config, currentTime ) > 0 )
			{
				if ( !gpfPrepareCollector( config ) )
				{
					gpfError( "collector pre check ... NG" );
					goto exitLoop;
				}
				
				for ( collector = schedule->collectorStart;
					collector != NULL;
					collector = collector->next )
				{
					if ( collector->status != GPF_PROCESS_WAIT )
						continue;

					collector->status = GPF_PROCESS_RUN;

					child = gpfSpawnCollector( config, collector );
				}
				
				/* 期限切れになる前にライセンスをチェックする */
				if (schedule->postEnable == 1 && schedule->remhostEnable == 1 )
				{
					gpfCheckLicense( config, GPF_CHECK_EXPIRED_TIME );
				}
			}
			processCount  = ght_size( collectorPids );

			gpfInfo( "[S][  RUNNING  ] COLLECTOR ====> %d", processCount );
		}
exitLoop:

#ifndef _WINDOWS

		do {
			int child_ret;
			child_pid = waitpid(-1, &child_ret, WNOHANG);
		} while(child_pid > 0);

#endif

		if ( config->mode == GPF_PROCESS_END )
			break;
		/* CHECK_MEMORY("gpfRunScheduler", "end"); */
		sleep(1);
	}
	return 1;
}

/**
 * Run collector
 */
#if defined(_WINDOWS)
unsigned WINAPI _gpfSpawnCollector( void *lpx )
{
	int i = 0;
	GPFTask *task = (GPFTask *)lpx;

	gpfDebug( "[S]spawn %s", task->collector->statName );
	gpfRunCollector( task );

	_endthreadex( 0 );

//	gpfFreeTask( &task );
	return 0;
}

GPFThreadId gpfSpawnCollector( GPFConfig *config, GPFCollector *collector )
{
	HANDLE hThread;
	GPFThreadId threadId;
	ght_hash_table_t *collectorPids = NULL;
	GPFTask *task                 = NULL;
	int rc                        = 0;
	time_t currentTime            = time(NULL);
	
	collectorPids = config->collectorPids;

	task = gpfCreateTask( config, collector );
	hThread = (HANDLE)_beginthreadex( NULL, 0, _gpfSpawnCollector, task, 0, 
		(unsigned int*)&threadId );

	gpfDebug( "[S]threadid=%lu", threadId );
	CloseHandle( hThread );

	task->threadId = threadId;
	task->timeout  = currentTime + collector->statTimeout;

	
	gpfDebug( "[C] LOCK initialize collector" );
	gpfDebug( "[C] ******** CRITICAL ********* LOCK finalize collector (thread %lu)",  threadId );
	zbx_mutex_lock(&taskAccessFlag);
	gpfDebug("[C] INSERT[%s:%lu]", task->timeDir, threadId );
	if ( gpfInsertPids( collectorPids, task, threadId ) == 0 )
		gpfError("!!!! COLLECTOR HASH ERROR !!!! key=%lu\n", threadId);

	gpfDebug( "[C] ******** CRITICAL ********* UNLOCK finalize collector (thread %lu)",  threadId );
	gpfDebug( "[C] UNLOCK initialize collector" );
	zbx_mutex_unlock(&taskAccessFlag);

	return( threadId );
}

#else

void * _gpfSpawnCollector( void * lpx )
{
	int i = 0;
	GPFTask *task = (GPFTask *)lpx;

	gpfDebug( "spawn %s", task->collector->statName );
	gpfRunCollector( task );

//	gpfFreeTask( &task );
	return 0;
}

GPFThreadId gpfSpawnCollector( GPFConfig *config, GPFCollector *collector )
{
	GPFThreadId threadId;
	ght_hash_table_t *collectorPids = NULL;
	GPFTask *task                 = NULL;
	int rc                        = 0;
	time_t currentTime            = time(NULL);
	
	collectorPids = config->collectorPids;

	task = gpfCreateTask( config, collector );
	pthread_create( &threadId, NULL, &_gpfSpawnCollector, task );
	pthread_detach( threadId );
	
	gpfDebug( "[S]threadid=%lu\n", threadId );

	task->threadId = threadId;
	task->timeout  = currentTime + collector->statTimeout;

	gpfDebug( "[C] LOCK initialize collector(thread %lu)", threadId );
	gpfDebug( "[C] ******** CRITICAL ********* LOCK finalize collector (thread %lu)",  threadId );
	zbx_mutex_lock(&taskAccessFlag);
	gpfDebug("[C] INSERT[%s:%lu]", task->timeDir, threadId );
	if ( gpfInsertPids( collectorPids, task, threadId ) == 0 )
		gpfError("!!!! COLLECTOR HASH ERROR !!!! key=%lu\n", threadId);
	gpfDebug( "[C] UNLOCK initialize collector(thread %lu)", threadId );
	gpfDebug( "[C] ******** CRITICAL ********* UNLOCK finalize collector (thread %lu)",  threadId );
	zbx_mutex_unlock(&taskAccessFlag);

	return( threadId );
}

#endif
 
/**
 * Run collector
 */
int gpfRunCollector( GPFTask *task )
{
	int rc = 0;
	GPFConfig    *config    = task->config;		/**< Agent config */
	GPFSchedule *schedule   = config->schedule;
	GPFCollector *collector = task->collector;	/**< Collector config */
	char *dateDir           = task->dateDir;	/**< date dir */
	char *timeDir           = task->timeDir;	/**< time dir */
	char *odir              = task->odir;		/**< output dir */
	int processCount        = 0;
	GPFThreadId threadId;
	
	gpfNotice( "[C][%s] START (%s/%s) ======", collector->statName, dateDir, timeDir );
	
	if ( !gpfMakeDirectory(odir) )
		return gpfError( "make directory failed : %s", odir );

	if (strcmp( collector->statMode, "concurrent" ) == 0 )
	{
		rc = gpfManageWorkerConcurrent( task );
	}
	else if ( strcmp( collector->statMode, "serial" ) == 0 )
	{
		rc = gpfManageWorkerSerial( task );
	}
	task->mode    = GPF_PROCESS_END;
	task->endTime = time( NULL );

	do {
		processCount = gpfCountWorkerPids( task->workerPids );
		gpfNotice("[C] finalize collector. worker count ===> %d", processCount);
		if ( processCount > 0 )
			sleep(1);
	} while (processCount > 0);
	
	gpfNotice( "[C][%s] FINISH (%s/%s) ======", collector->statName, dateDir, timeDir );

	gpfReportCollector( task );

	if ( schedule->postEnable == 1 || schedule->remhostEnable == 1 )
	{
		gpfArchiveData( task );
		gpfSendCollectorDataAll( task );
	}
	
	gpfPurgeData( task );
		
	threadId = task->threadId; // gpfGetThreadId();
	gpfInfo( "[C]finalize (thread %lu) : %s",  threadId, task->odir );
	if ( threadId > 0 )
	{
		ght_hash_table_t *collectorPids = config->collectorPids;

		gpfDebug( "[C] ******** CRITICAL ********* LOCK finalize collector (thread %lu)",  threadId );
		zbx_mutex_lock(&taskAccessFlag);
		if ( gpfRemovePids( collectorPids, threadId ) != NULL )
		{
			gpfDebug("[C] Free LIST[%s:%lu]", task->timeDir, task->threadId );
		}
		gpfDebug( "[C] ******** CRITICAL ********* UNLOCK finalize collector (thread %lu)",  threadId );
		zbx_mutex_unlock(&taskAccessFlag);
	}
	else
	{
		gpfDebug( "[C]remove UnKnown collector task" );
	}
#if defined(_WINDOWS)
/*
	WaitForSingleObject( threadId, 0 );
*/
#else
	pthread_join( threadId, NULL );
#endif
	gpfFreeTask( &task );
	
	return rc;
}

/**
 * Manage worker concurrent
 */
int gpfManageWorkerConcurrent( GPFTask *task )
{
	int rc = 0;
	GPFConfig    *config    = task->config;		/**< Agent config */
	GPFCollector *collector = task->collector;	/**< Collector config */
	GPFJob *job             = NULL;
	time_t currTime         = 0;
	time_t checkTime        = 0;
	time_t endTime          = 0;
	ght_hash_table_t *workerPids = NULL;

	currTime  = time( NULL );
	checkTime = currTime + GPF_POLLER_INTERVAL;
	endTime   = currTime + collector->statTimeout;

	task->mode = GPF_PROCESS_RUN;
	workerPids = task->workerPids; // ght_create( GPF_MAX_WORKERS );
	
	if ( collector->jobStart != NULL )
	{
		int seq                 = 0;

		for ( job = collector->jobStart, seq = 1 ;
			job != NULL;
			job = job->next, seq ++ )
		{
			GPFTaskJob *taskJob  = NULL;
			GPFThreadId threadId = 0;
			
			taskJob = gpfCreateTaskJob( task, job, seq );

			gpfDebug( "[C][%s][%d][Exec] %s", collector->statName, seq, job->cmd );
			threadId = gpfSpawnWorker( taskJob );

			taskJob->threadId = threadId;
			taskJob->timeout  = endTime;

			gpfDebug( "[C] LOCK initialize worker" );
			zbx_mutex_lock(&taskAccessFlag);
			if (gpfInsertPids( workerPids, taskJob, threadId ) == 0 )
				gpfError("!!!! WORKER HASH ERROR !!!! key=%lu\n", threadId);
			
			gpfDebug( "[C] UNLOCK initialize worker" );
			zbx_mutex_unlock(&taskAccessFlag);
		}
	}

	while ( 1 )
	{
		char *exitStatus = NULL;
		currTime = time( NULL );

//		if ( ( exitStatus = gpfCheckExitFile( config ) ) != NULL )
//		{
//			gpfWarn( "[C]Catch exit signal %s", exitStatus );
//			gpfReapTimeoutWorkers( workerPids, 0, 1 );
//			break;
//		}
		if ( currTime > endTime )
		{
			task->mode = GPF_PROCESS_TIMEOUT;
			gpfNotice( "[C][%s][Timeout] Terminate", collector->statName );
			gpfReapTimeoutWorkers( workerPids, 0, 1 );
			break;
		}
		else if ( currTime >= checkTime )
		{
			int processCount = 0;

			gpfDebug( "[C][%s][Collector Check]", collector->statName );
			checkTime += GPF_POLLER_INTERVAL;
			gpfReapTimeoutWorkers( workerPids, 1, 0 );
			processCount = gpfCountWorkerPids( workerPids );
			
			if ( processCount == 0 )
				break;
		}
		sleep(1);
	}

	return 1;
}

/**
 * Manager worker serial
 */
int gpfManageWorkerSerial( GPFTask *task )
{
	int rc = 0;
	GPFConfig    *config    = task->config;		/**< Agent config */
	GPFCollector *collector = task->collector;	/**< Collector config */
	GPFJob *job             = NULL;
	char *dateDir           = task->dateDir;	/**< Date dir */
	char *timeDir           = task->timeDir;	/**< Time dir */
	int  timeoutFlag        = 0;
	time_t currTime         = 0;
	time_t checkTime        = 0;
	time_t endTime          = 0;
	ght_hash_table_t *workerPids = NULL;
	int seq   = 0;

	currTime  = time( NULL );
	checkTime = currTime + GPF_POLLER_INTERVAL;
	endTime   = currTime + collector->statTimeout;
	workerPids = task->workerPids; // ght_create( GPF_MAX_WORKERS );
	task->mode = GPF_PROCESS_RUN;

	if ( collector->jobStart == NULL )
		return gpfError( "[C]collector null" );

	for ( job = collector->jobStart, seq = 1 ;
		job != NULL && currTime < endTime ;
		job = job->next, seq++ )
	{
		GPFTaskJob *taskJob = NULL;
		GPFThreadId threadId = 0;

		gpfInfo( "[C][%s][%d][Exec] %s", collector->statName, seq, job->cmd );
		
		taskJob = gpfCreateTaskJob( task, job, seq );
		threadId = gpfSpawnWorker( taskJob );
		gpfDebug("threadId=%d\n", threadId );

//		threadId         = seq;
//		taskJob->pid     = threadId;
		taskJob->threadId = threadId;
		taskJob->timeout = endTime;

		gpfDebug( "[C] LOCK initialize worker" );
		zbx_mutex_lock(&taskAccessFlag);
		if ( gpfInsertPids( workerPids, taskJob, seq ) == 0 )
			gpfError("!!!! WORKER HASH ERROR !!!! key=%lu\n", seq);

		gpfDebug( "[C] UNLOCK initialize worker" );
		zbx_mutex_unlock(&taskAccessFlag);			

		while ( 1 )
		{
			char *exitStatus = NULL;
			currTime = time( NULL );
//			if ( ( exitStatus = gpfCheckExitFile( config ) ) != NULL )
//			{
//				gpfWarn( "[C]Catch exit signal %s", exitStatus );
//				gpfReapTimeoutWorkers( workerPids, 0, 1 );
//				break;
//			}
			if ( currTime > endTime )
			{
				task->mode = GPF_PROCESS_TIMEOUT;
				gpfNotice( "[C][%s][Timeout] Terminate", collector->statName );
				gpfReapTimeoutWorkers( workerPids, 0, 1 );
				break;
			}
			else if ( currTime > checkTime )
			{
				int processCount = 0;
				processCount = gpfCountWorkerPids( workerPids );
			
				checkTime += GPF_POLLER_INTERVAL;
				gpfReapTimeoutWorkers( workerPids, 1, 0 );
				processCount = gpfCountWorkerPids( workerPids );
				gpfDebug( "[C][%s][Collector Check] count=%d", collector->statName, processCount );
				
				if ( processCount == 0 )
					break;
			}
			sleep(1);
		}
	}
	return 1;
}

/**
 * Run worker, multithread model
 */
#if defined(_WINDOWS)

unsigned WINAPI _gpfSpawnWorker( void *lpx )
{
	GPFTaskJob *taskJob = (GPFTaskJob *)lpx;

	gpfRunWorker( taskJob );
	return 0;
}

GPFThreadId gpfSpawnWorker( GPFTaskJob *taskJob )
{
	HANDLE hThread;
	GPFThreadId threadId;

	hThread = (HANDLE)_beginthreadex( NULL, 0, _gpfSpawnWorker, taskJob, 0, (unsigned int*)&threadId );

	taskJob->threadId = threadId;
	
	return( threadId );
}

#else

void * _gpfSpawnWorker( void * lpx )
{
	GPFTaskJob *taskJob = (GPFTaskJob *)lpx;

	gpfRunWorker( taskJob );
}

GPFThreadId gpfSpawnWorker( GPFTaskJob *taskJob )
{
	GPFThreadId threadId;

	pthread_create( &threadId, NULL, &_gpfSpawnWorker, taskJob );
	pthread_detach( threadId );
	
	return( threadId );
}

#endif

/**
 * Run worker
 */
pid_t gpfRunWorker( GPFTaskJob *taskJob )
{
	int rc = 0;
	GPFTask *task           = NULL;	/**< Task config */
	GPFConfig    *config    = NULL;	/**< Agent config */
	GPFCollector *collector = NULL;	/**< Collect config */
	GPFJob *job             = NULL;	/**< Job config */
	char *dateDir           = NULL;	/**< Date dir */
	char *timeDir           = NULL;	/**< Time dir */
	char *odir              = NULL;	/**< Output dir */
	char *workDir           = NULL;
	char *statName          = NULL;
	char *command           = NULL;
	char *newCommand        = NULL;
	char *newCommand2       = NULL;
	char *tempStr           = NULL;
	char *jobkey            = NULL;
	char *outFile           = NULL;
	char *outPath           = NULL;
	char *errFile           = NULL;
	char *errPath           = NULL;
	pid_t *pid_p            = NULL;
	int *exitCode_p         = NULL;
	int statTimeout         = 0;
	int seq;
	
	task        = taskJob->task;
	config      = task->config;
	collector   = task->collector;
	job         = taskJob->job;
	dateDir     = task->dateDir;
	timeDir     = task->timeDir;
	odir        = task->odir;
	workDir     = config->workDir;
	statName    = strdup(collector->statName);
	seq         = taskJob->seq;
	pid_p       = &(taskJob->pid);
	exitCode_p  = &(taskJob->exitCode);
	statTimeout = collector->statTimeout;
	
	command = strdup( job->cmd );
	newCommand  = gpfStringReplace( command, "_odir_", odir );
	gpfFree( command );
	newCommand2 = gpfStringReplace( newCommand, "_script_", config->scriptDir );
	gpfFree( newCommand );
	
	gpfNotice( "[W][%s][%d][Exec] %s", statName, seq, newCommand2 );

	jobkey  = gpfDsprintf( jobkey, "%s_%s_%s_%d", dateDir, timeDir, statName, seq);
	gpfDebug( "[W][jobkey] %s", jobkey );
	if ( job->ofile == NULL)
	{
		outFile = gpfDsprintf(outFile, "stdout_w_%s", jobkey );
		outPath = gpfCatFile( workDir, outFile, NULL );
		gpfFree( outFile );
	}
	else
	{

		int pos;
		char *outDir = NULL;
		char *postfix = strdup( job->ofile );
		for (pos = strlen(postfix) - 1; pos > 0; pos --) {
			if ( *(postfix + pos) == '/' || *(postfix + pos) == '\\' ) {
				*(postfix + pos) = '\0';
				outDir = gpfCatFile( odir, postfix, NULL );
				gpfMakeDirectory( outDir );
				break;
			}
		}
		gpfFree( postfix );
		gpfFree( outDir );	

		outPath = gpfCatFile( odir, job->ofile, NULL );
	}
	
	gpfDebug( "[W][out] %s", outPath );

	errFile = gpfDsprintf( errFile, "stderr_w_%s", jobkey );
	errPath = gpfCatFile( workDir, errFile, NULL );
	gpfFree( errFile );
	gpfDebug( "[W][err] %s", errPath );
	
	unlink( outPath );
	unlink( errPath );

	gpfDebug("[W]gpfExecCommand %s", newCommand2);
	if ( chdir( config->scriptDir ) != 0)
	{
		gpfSystemError("chdir failed");
		return 0;
	}
	taskJob->status = GPF_PROCESS_RUN;
	if ( job->cycle == 0 )
	{
		rc = gpfExecCommand(newCommand2, statTimeout, outPath, errPath, pid_p, exitCode_p );
	} 
	else
	{
		time_t startTime, nextTime, currTime;
		int elapse    = 0;
		int loopCount = 0;
		startTime     = time( NULL );
		nextTime      = startTime + job->cycle;

		while ( 1 )
		{
			currTime = time( NULL );
			elapse = currTime - startTime;
			if (task->mode != GPF_PROCESS_RUN)
				break;
			if ( elapse > statTimeout )
				break;
			if ( currTime >= nextTime ) 
			{
				rc = gpfExecCommand(newCommand2, statTimeout - elapse, outPath, errPath, pid_p, exitCode_p );
				if ( rc == 0 )
					break;
				loopCount ++;
				taskJob->loopCount = loopCount;
				if ( job->step > 0 && loopCount >= job->step )
					break;
				nextTime = currTime + job->cycle;
			}
			sleep( 1 );
		}
	}
	taskJob->endTime = time( NULL );
	if (chdir( config->pwd ) != 0)
	{
		gpfSystemError("chdir failed");
		return 0;
	}
	
	gpfNotice( "[W][%s][End][pid=%d][RC=%d]", jobkey, *pid_p, *exitCode_p );
	gpfDebug( "[%s][%s][%s][%s]", jobkey, newCommand2, outPath, errPath );

	gpfFree( statName );
	gpfFree( jobkey );
	gpfFree( newCommand2 );
	gpfFree( outPath );
	gpfFree( errPath );
	gpfDebug( "[W][End] gpfRunWorker" );
	taskJob->status = ( *exitCode_p == 0 ) ? GPF_PROCESS_END : GPF_PROCESS_ERROR;

	return *pid_p;
}

/**
 * Count running worker process
 */

int gpfCountWorkerPids( ght_hash_table_t *workerPids )
{
	GPFTaskJob *taskJob = NULL;
	int count = 0;
//	GPFThreadId *threadId = NULL;
	const void *threadId;
	ght_iterator_t iterator;

	gpfDebug( "[C] LOCK count worker" );
	zbx_mutex_lock( &taskAccessFlag );
	for ( taskJob = (GPFTaskJob *) ght_first( workerPids, &iterator, &threadId );
	      taskJob ;
	      taskJob = (GPFTaskJob *) ght_next( workerPids, &iterator, &threadId ) )
	{
		if ( taskJob->status == GPF_PROCESS_RUN || taskJob->status == GPF_PROCESS_INIT )
		{
			gpfDebug("JOB [%d] pid=%d", taskJob->seq, taskJob->pid );
			count ++;
		}
	}
	gpfDebug( "[C] UNLOCK count worker" );
	zbx_mutex_unlock( &taskAccessFlag );

	return( count );
}

/**
 * Reap timeout or finished worker process
 */
int gpfReapTimeoutWorkers( ght_hash_table_t *workerPids, int nowait, int killAll )
{
	GPFTaskJob *taskJob = NULL;
	int childStatus = 0;
	int processCount;
	time_t currentTime, elapse;
//	GPFThreadId *threadId = NULL;
	const void *threadId;
	ght_iterator_t iterator;
	int limitTime = 0;
	
	currentTime = time( NULL );

	processCount  = gpfCountWorkerPids( workerPids );
	if ( processCount > 0 )
		gpfInfo( "[C]running worker : %d", processCount );

	
//	threadId = gpfMalloc( threadId, sizeof(GPFThreadId) );
//	timeout = gpfMalloc( timeout, sizeof(time_t) );
	
//#ifndef _WINDOWS
//	threadId  = gpfMalloc( threadId, sizeof(GPFThreadId) );
//	while ( ( *pidKey = waitpid(-1, &childStatus, WNOHANG)) > 0 )
//	{
//		taskJob = (GPFTaskJob *)ght_get( workerPids, sizeof(pid_t), pidKey );
//		if ( taskJob != NULL )
//		{
//			gpfDebug("end worker (%d)\n", *pidKey);
//			taskJob->endTime = time(NULL);
//		}
//	}
//	gpfFree( pidKey );
//#endif

	gpfDebug( "[C] LOCK reap worker" );
	zbx_mutex_lock( &taskAccessFlag );
	for ( taskJob = (GPFTaskJob *) ght_first( workerPids, &iterator, &threadId );
	      taskJob ;
	      taskJob = (GPFTaskJob *) ght_next( workerPids, &iterator, &threadId ) )
	{
		GPFJob *job = NULL;
		int alive  = 0;
		pid_t pid  = 0;
 		int status = 0;

		job    = taskJob -> job;
		elapse = currentTime - taskJob->timeout;
		pid    = taskJob->pid;
		status = taskJob->status;
		
		if (job->cycle > 0) {
			int cycle = job->cycle;
			int step  = job->step;
			alive = ( taskJob->loopCount < step ) ? 1 : 0;
		}
		else if ( status <= GPF_PROCESS_RUN && pid > 0 )
		{
			alive = gpfCheckProcess( pid, NULL );
		}
		gpfDebug("[C]pid=%d, alive=%d, status=%d, limitTime=%d, endTime=%d", 
			pid, alive, status, limitTime , taskJob->endTime );

		if ( taskJob->endTime != 0 )
			continue;

		if ( killAll == 1 && alive == 1 )
		{
			gpfInfo("[C][timeout] kill child pid=%d", pid );
			if ( !gpfKill( pid ) )
			{
				gpfError( "[C]Reap timeout worker : kill %d", pid );
			}
		}
		if ( alive == 0 )
		{
			gpfInfo( "[C][Finish] pid=%d", pid );
			taskJob->status  = GPF_PROCESS_END;
			taskJob->endTime = time(NULL);
		}
//		gpfWaitForThread( taskJob->threadId );
	}
	gpfDebug( "[C] UNLOCK reap worker" );
	zbx_mutex_unlock( &taskAccessFlag );
//	sleep(1);
//	gpfFree( threadId );

	return 1;
}

/**
 * Purge collection data
 */
 
#if defined _WINDOWS

int gpfPurgeData( GPFTask *task )
{
	GPFConfig *config = task->config;
	GPFCollector *collector = task->collector;
	GPFSchedule *schedule = NULL;
	char *outDir      = NULL;
	char *statName    = NULL;
	char *lastDate    = NULL;
	char *lastTime    = NULL;
	char *dateDirBase = NULL;
	char *timeDirBase = NULL;
	char *targetPath  = NULL;
	int saveHour      = GPF_DEFAULT_SAVE_HOUR;
	time_t purgeTime  = 0;
	int rc            = 0;
	int cnt           = 0;
	HANDLE	dir       = NULL;
	
	schedule = config->schedule;
	outDir   = config->outDir;
	saveHour = schedule->saveHour;
	statName = collector->statName;

	lastDate = gpfMalloc( lastDate, MAX_STRING_LEN );
	lastTime = gpfMalloc( lastTime, MAX_STRING_LEN );
	purgeTime = task->startTime - saveHour * 3600;
	
	if ( gpfGetTimeString( purgeTime, lastDate, GPF_DATE_FORMAT_YYYYMMDD ) &&
		 gpfGetTimeString( purgeTime, lastTime, GPF_DATE_FORMAT_HHMISS ) )
	{
		struct stat	  sb;
		WIN32_FIND_DATA fd;
		char *searchPath = NULL;
		cnt = 0;

		dateDirBase = gpfCatFile( outDir, statName, NULL );
		gpfDebug( "dateDirBase = %s", dateDirBase);
		searchPath = gpfCatFile(dateDirBase, "*", NULL);
		dir = FindFirstFileEx( searchPath, FindExInfoStandard, &fd, FindExSearchNameMatch, NULL, 0);
		gpfFree( searchPath );
	    if ( INVALID_HANDLE_VALUE == dir )
		{
			gpfSystemError( "%s", dateDirBase );
			goto errata;
		}
		
		while ( FindNextFile( dir, &fd ) )
		{
			char *targetDir = fd.cFileName;

			gpfDebug( "Check [%s][< %s]", targetDir, lastDate );
			if ( strchr( targetDir, '.' ) != NULL )
				continue;

			if ( strcmp( targetDir, lastDate ) >= 0 )
				continue;
			
			targetPath = gpfCatFile( dateDirBase, targetDir, NULL );
			if ( !gpfRemoveDir( targetPath ) )
			{
				gpfError( "rmdir %d failed", targetPath );
				goto errata;
			}
			cnt ++;
			gpfFree( targetPath );
		}
	    FindClose( dir );

		if ( cnt > 0 )
			gpfInfo("Purge data1 [%s][%s] : %d", statName, lastDate, cnt);

		cnt = 0;
		timeDirBase = gpfCatFile( dateDirBase, lastDate, NULL );
		searchPath = gpfCatFile(timeDirBase, "*", NULL);
		dir = FindFirstFileEx( searchPath, FindExInfoStandard, &fd, FindExSearchNameMatch, NULL, 0);
		gpfFree( searchPath );
	    if ( INVALID_HANDLE_VALUE != dir )
		{
			while ( FindNextFile( dir, &fd ) )
			{
				char *targetPath = NULL;
				char *targetDir = fd.cFileName;

				if ( strchr( targetDir, '.' ) != NULL )
					continue;

				gpfDebug( "Check [%s][%s][< %s]", lastDate, targetDir, lastTime );
				if ( strcmp( targetDir, lastTime ) >= 0 )
					continue;
				
				targetPath = gpfCatFile( timeDirBase, targetDir, NULL );
				if ( !gpfRemoveDir( targetPath ) )
				{
					gpfError( "rmdir %s failed", targetPath );
					goto errata;
				}
				cnt ++;
				gpfFree( targetPath );
			}
		}
	    FindClose( dir );
		dir = NULL;

		gpfFree( dateDirBase );
		gpfFree( timeDirBase );

		if ( cnt > 0 )
			gpfInfo("Purge data2 [%s][%s/%s] : %d", statName, lastDate, lastTime, cnt);
	}
	rc = 1;
	
	errata:
	if ( dir )	{ FindClose( dir );	dir = NULL; }

	errata2:
	gpfFree( lastDate );
	gpfFree( lastTime );
	gpfFree( dateDirBase );
	gpfFree( timeDirBase );
	gpfFree( targetPath );

	return rc;
}

#else

int gpfPurgeData( GPFTask *task )
{
	GPFConfig *config = task->config;
	GPFCollector *collector = task->collector;
	GPFSchedule *schedule = NULL;
	char *outDir      = NULL;
	char *statName    = NULL;
	char *lastDate    = NULL;
	char *lastTime    = NULL;
	char *dateDirBase = NULL;
	char *timeDirBase = NULL;
	char *targetPath  = NULL;
	int saveHour      = GPF_DEFAULT_SAVE_HOUR;
	time_t purgeTime  = 0;
	int rc            = 0;
	int cnt           = 0;

	DIR *dir          = NULL;
	
	schedule = config->schedule;
	outDir   = config->outDir;
	saveHour = schedule->saveHour;
	statName = collector->statName;

	gpfNotice( "[C][5] Delete Log =============================" );

	lastDate = gpfMalloc( lastDate, MAX_STRING_LEN );
	lastTime = gpfMalloc( lastTime, MAX_STRING_LEN );
	purgeTime = task->startTime - saveHour * 3600;

	if ( gpfGetTimeString( purgeTime, lastDate, GPF_DATE_FORMAT_YYYYMMDD ) &&
		 gpfGetTimeString( purgeTime, lastTime, GPF_DATE_FORMAT_HHMISS ) )
	{
		struct stat	  sb;
		struct dirent *d;
		cnt = 0;

		dateDirBase = gpfCatFile( outDir, statName, NULL );

		if ( ( dir = opendir(dateDirBase) ) == NULL ) 
		{
			gpfSystemError( "%s", dateDirBase );
			goto errata;
		}
		
		while ( ( d = readdir(dir) ) != NULL ) 
		{
			char *targetDir = d->d_name;

			if ( strchr( targetDir, '.' ) != NULL )
				continue;

			gpfDebug( "Check [%s][< %s]", targetDir, lastDate );
			if ( strcmp( targetDir, lastDate ) >= 0 )
				continue;
			
			targetPath = gpfCatFile( dateDirBase, targetDir, NULL );
			if ( !gpfRemoveDir( targetPath ) )
			{
				gpfError( "rmdir %d failed", targetPath );
				goto errata;
			}
			cnt ++;
			gpfFree( targetPath );
		}
		if ( closedir(dir) == -1 ) 
		{
			gpfSystemError( "%s", dateDirBase );
			goto errata2;
		}

		if ( cnt > 0 )
			gpfInfo("Purge data1 [%s][%s] : %d", statName, lastDate, cnt);

		cnt = 0;
		timeDirBase = gpfCatFile( dateDirBase, lastDate, NULL );
		gpfDebug("check %s", timeDirBase);
		if ( ( dir = opendir(timeDirBase) ) == NULL ) 
		{
			gpfNotice( "no purge data" );
			rc = 1;
			goto errata;
		}
		while ( ( d = readdir(dir) ) != NULL ) 
		{
			char *targetPath = NULL;
			char *targetDir = d->d_name;

			if ( strchr( targetDir, '.' ) != NULL )
				continue;

			gpfDebug( "Check [%s][%s][< %s]", lastDate, targetDir, lastTime );
			if ( strcmp( targetDir, lastTime ) >= 0 )
				continue;
			
			targetPath = gpfCatFile( timeDirBase, targetDir, NULL );
			if ( !gpfRemoveDir( targetPath ) )
			{
				gpfError( "rmdir %d failed", targetPath );
				goto errata;
			}
			cnt ++;
			gpfFree( targetPath );
		}
		if ( closedir(dir) == -1 ) 
		{
			gpfSystemError( "%s", timeDirBase );
			goto errata2;
		}
		dir = NULL;

		gpfFree( dateDirBase );
		gpfFree( timeDirBase );

		if ( cnt > 0 )
			gpfInfo("Purge data2 [%s][%s/%s] : %d", statName, lastDate, lastTime, cnt);
	}
	rc = 1;
	
	errata:
	if ( dir ) 
		closedir(dir); 

	errata2:
	gpfFree( lastDate );
	gpfFree( lastTime );
	gpfFree( dateDirBase );
	gpfFree( timeDirBase );
	gpfFree( targetPath );

	return rc;
}
#endif

/**
 * Report collector execute
 */
int gpfReportCollector( GPFTask *task )
{
	int rc = 1;
	GPFConfig    *config    = task->config;		/**< Agent config */
	GPFCollector *collector = task->collector;	/**< Collector config */
	GPFSchedule *schedule   = NULL;
	GPFTaskJob *taskJob     = NULL;
	GPFJob *job             = NULL;
	char *workDir           = NULL;
	char *statName          = NULL;
	char *dateDir           = task->dateDir;	/**< Date dir */
	char *timeDir           = task->timeDir;	/**< Time dir */
	char *timeStr           = NULL;
	char *reportFile        = NULL;
	char *reportPath        = NULL;
	char *odir              = NULL;
	char *line              = NULL;
	char *buff              = NULL;
	const void *threadId;
	ght_hash_table_t *workerPids = NULL;
	ght_iterator_t iterator;
	int maxErrorLog         = GPF_DEFAULT_MAX_ERROR_LOG;
	int seq   = 1;

	schedule    = config->schedule;
	workDir     = config->workDir;
	maxErrorLog = schedule->maxErrorLog;
	statName    = collector->statName;
	line        = gpfMalloc( line, MAX_STRING_LEN );
	timeStr     = gpfMalloc( timeStr, MAX_STRING_LEN );
	workerPids  = task->workerPids; // ght_create( GPF_MAX_WORKERS );
	odir        = task->odir;

	if ( maxErrorLog == 0 )
		maxErrorLog = GPF_LIMIT_MAX_ERROR_LOG;

	// $res  = "schedule:\n";
	gpfSnprintf(line, MAX_STRING_LEN, "schedule:\n" );
	buff = gpfStrdcat( buff, line );

	// $res .= "  start: $startDateString\n";
	gpfGetTimeString( task->startTime, timeStr, GPF_DATE_FORMAT_DEFAULT );
	gpfSnprintf(line, MAX_STRING_LEN, "  start: %s\n", timeStr );
	buff = gpfStrdcat( buff, line );

	// $res .= "  end: $endDateString\n";
	gpfGetTimeString( task->endTime, timeStr, GPF_DATE_FORMAT_DEFAULT );
	gpfSnprintf(line, MAX_STRING_LEN, "  end: %s\n", timeStr );
	buff = gpfStrdcat( buff, line );

	// $res .= "  servicename: $serviceName\n";
	if ( config->serviceName )
	{
		gpfSnprintf(line, MAX_STRING_LEN, "  servicename: %s\n", config->serviceName );
		buff = gpfStrdcat( buff, line );
	}
	// $res .= "jobs:\n";
	gpfSnprintf(line, MAX_STRING_LEN, "jobs:\n" );
	buff = gpfStrdcat( buff, line );

	gpfDebug( "[C] LOCK report collector" );
	zbx_mutex_lock( &taskAccessFlag );
	for ( taskJob = (GPFTaskJob *) ght_first( workerPids, &iterator, &threadId ), seq = 1;
	      taskJob ;
	      taskJob = (GPFTaskJob *) ght_next( workerPids, &iterator, &threadId ), seq++ )
	{
		GPFJob *job   = NULL;
		char *jobkey  = NULL;
		char *errFile = NULL;
		char *errFile2 = NULL;
		char *errPath = NULL;
		char *outFile = NULL;
		char *outPath = NULL;
		char *message = NULL;
		char **lines  = NULL;
		int rown      = 0;
		int readFlg   = 0;
		struct stat sb;

		job = taskJob->job;
		jobkey = gpfDsprintf(jobkey, "%s_%s_%s_%d", dateDir, timeDir, statName, seq );
		gpfDebug( "jobkey=[%s]", jobkey );

		// $res .= "  - id: $seq\n";
		gpfSnprintf(line, MAX_STRING_LEN, "  - id: %d\n", seq );
		buff = gpfStrdcat( buff, line );

		// $res .= "    out: $out\n";
		gpfSnprintf(line, MAX_STRING_LEN, "    out: %s\n", job->ofile );
		buff = gpfStrdcat( buff, line );

		// $res .= "    cmd: $cmd\n";
		gpfSnprintf(line, MAX_STRING_LEN, "    cmd: %s\n", job->cmd );
		buff = gpfStrdcat( buff, line );

		// $res .= "    start: $stat\n";
		gpfGetTimeString( taskJob->startTime, timeStr, GPF_DATE_FORMAT_DEFAULT );
		gpfSnprintf(line, MAX_STRING_LEN, "    start: %s\n", timeStr );
		buff = gpfStrdcat( buff, line );

		// $res .= "    end: $end\n";
		gpfGetTimeString( taskJob->endTime, timeStr, GPF_DATE_FORMAT_DEFAULT );
		gpfSnprintf(line, MAX_STRING_LEN, "    end: %s\n", timeStr );
		buff = gpfStrdcat( buff, line );
		
		// $res .= "    pid: $pid\n";
		gpfSnprintf(line, MAX_STRING_LEN, "    pid: %d\n", taskJob->pid );
		buff = gpfStrdcat( buff, line );

		// $res .= "    rc: $rc\n";
		gpfSnprintf(line, MAX_STRING_LEN, "    rc: %d\n", taskJob->exitCode );
		buff = gpfStrdcat( buff, line );

		errFile = gpfDsprintf( errFile, "stderr_w_%s", jobkey );
		errPath = gpfCatFile( workDir, errFile, NULL );
		gpfDebug( "errFile =%s, errPath=%s", errFile, errPath );

		if ( ( readFlg = gpfReadWorkFileHead( config, errFile, &message, maxErrorLog ) ) == 1)
		{
			int row = 0;
			char **lines = NULL;
			if ( message != NULL )
			{
				// $res .= "    errormsg: |\n";
				buff = gpfStrdcat( buff, "    errormsg: |\n" );

				lines = gpfSplit( &rown, GPF_LINE_SEPARATORS, message );
				for ( row = 0; row < rown; row ++ )
				{
					// $res .= '      ' . $line;
					gpfSnprintf(line, MAX_STRING_LEN, "      %s\n", lines[ row ] );
					buff = gpfStrdcat( buff, line );
				}
				gpfFree( lines );
				gpfFree( message );
			}
		}
		
		if ( unlink( errPath ) != 0 ) {
			gpfSystemError( "unlink error %s", errPath );
		}
		
		gpfFree( errPath );
		gpfFree( errFile );

		if ( job->ofile != NULL )
			goto loopEnd;

		outFile = gpfDsprintf( outFile, "stdout_w_%s", jobkey );
		outPath = gpfCatFile( workDir, outFile, NULL );
		gpfDebug( "outPath=%s, outPath=%s", outFile, outPath );

		if ( ( readFlg = gpfReadWorkFile( config, outFile, &message ) ) == 1)
		{
			int row = 0;
			char **lines = NULL;

			lines = gpfSplit( &rown, GPF_LINE_SEPARATORS, message );
			for ( row = 0; row < rown; row ++ )
			{
				gpfInfo( "[%s:%d][stdout] %s", statName, seq, lines[ row ] );
			}
			gpfFree( lines );
			gpfFree( message );
		}

		if ( unlink( outPath ) != 0 ) {
			gpfSystemError( "unlink error %s", outPath );
		}

		gpfDebug( "END" );
		
loopEnd:
		gpfFree( outPath );
		gpfFree( outFile );
		gpfFree( jobkey );
	}
	gpfDebug( "[C] UNLOCK report collector" );
	zbx_mutex_unlock( &taskAccessFlag );

	if ( rc == 1)
	{
		FILE *file = NULL;
		gpfDebug( "[Report]\n%s", buff );
		reportFile = gpfDsprintf( reportFile, "stat_%s.log", statName );
		reportPath = gpfCatFile( odir, reportFile, NULL );
		
		if( (file = fopen(reportPath, "w")) == NULL) 
		{
			gpfSystemError("%s", reportPath);
		}
		else
		{
			fputs( buff, file );
			fclose(file);
			gpfInfo( "[Write] %s", reportFile );
		}
		gpfFree( reportPath );
		gpfFree( reportFile );
	}
	else
	{
		gpfError( "report error\n%s", buff );
	}
	
	gpfFree( timeStr );
	gpfFree( line );
	gpfFree( buff );
	
	return rc;
}

/**
 * Archive arc_{ホスト}__{CAT}_{YYYYMMDD}_{HHMISS}.zip 
 * from log/{CAT}/YYYYMMDD/HHMISS directory
 */
int gpfArchiveData( GPFTask *task )
{
	int rc = 1;
	GPFConfig *config       = task->config;
	GPFCollector *collector = task->collector;
	char *odir              = task->odir;
	char *dateDir           = task->dateDir;
	char *timeDir           = task->timeDir;
	char *statName          = NULL;
	char *outPath           = NULL;
	char *zipFile           = NULL;
	char *zipPath           = NULL;
	double startTime        = 0;
	double elapse           = 0;
	
	startTime = gpfTime();
	statName = collector->statName;
	zipFile = gpfDsprintf( zipFile, "arc_%s__%s_%s_%s.zip", 
		config->host, collector->statName, dateDir, timeDir );
	zipPath = gpfCatFile( config->archiveDir, zipFile, NULL );
	outPath = gpfDsprintf( outPath, "%s/%s/%s", statName, dateDir, timeDir );

	rc = zipDir(zipPath, config->outDir, outPath, NULL);
	elapse = gpfTime() - startTime;
	gpfNotice( "[C][%s] Archive %s %s", statName, zipFile, (rc == 1)?"OK":"NG" );

	gpfFree( outPath );
	gpfFree( zipPath );
	gpfFree( zipFile );
	
	return rc;
}

/**
 * Check zip log filename foward match
 */
int gpfCheckZipLogFormat( GPFTask *task, char *zipFile )
{
	int rc = 0;
	GPFConfig *config = task->config;
	GPFCollector *collector = task->collector;
	char *zipHead = NULL;
	zipHead = gpfDsprintf( zipHead, "arc_%s__%s", config->host, collector->statName );
	rc = ( strstr( zipFile, zipHead ) != NULL ) ? 1 : 0;
	gpfDebug( "compare %s,%s : %d", zipFile, zipHead, rc );
	gpfFree( zipHead );

	return ( rc );
}

/**
 * Check date format directory name
 */
int gpfCheckLogDateFormat( char *dirname )
{
	int rc = 1;
	int i;

	for (i = 0; i < MAXFILENAME && dirname[i] != '\0'; i++)
	{
		if (dirname[i] < '0' || dirname[i] > '9')
		{
			rc = 0;
			break;
		}
	}
	return ( rc );
}

/**
 * Transfer all unsent data 
 */
int gpfSendCollectorDataAll( GPFTask *task )
{
	int rc                  = 1;
	GPFConfig *config       = task->config;
	GPFCollector *collector = task->collector;
	GPFSchedule *schedule   = NULL;
	char *statName          = NULL;
	char *zipPath           = NULL;
	char *oldestZipFile     = NULL;
	char *oldestZipDateStr  = NULL;
	GPFStrings *zips        = NULL;
	char *timeStr           = NULL;
	double startTime        = 0;
	time_t oldestTime       = 0;

#if defined _WINDOWS
	char *searchPath        = NULL;
	WIN32_FIND_DATA fd;
	HANDLE h;
#else
	struct dirent *entp;
	DIR *dp;
#endif

	statName  = collector->statName;
	zips      = gpfCreateStrings();
	timeStr   = gpfMalloc( timeStr, MAX_STRING_LEN );
	schedule  = config->schedule;
	startTime = gpfTime();

	/* set oldest zip file name */
	oldestTime = task->startTime - 3600 * schedule->recoveryHour;

	gpfGetTimeString( oldestTime, timeStr, GPF_DATE_FORMAT_YYYYMMDD_HHMISS );
	oldestZipFile = gpfDsprintf( oldestZipFile, "arc_%s__%s_%s.zip", 
		config->host, collector->statName, timeStr );
	gpfFree( timeStr );

	/* list zip files */
#if defined _WINDOWS

	gpfDebug( "archive : %s", config->archiveDir );
	searchPath = gpfCatFile(config->archiveDir, "*", NULL);
    h = FindFirstFileEx(searchPath, FindExInfoStandard, &fd, FindExSearchNameMatch, NULL, 0);
	gpfFree(searchPath);
	
    if ( INVALID_HANDLE_VALUE == h )
		return gpfSystemError( "FindFirstFileEx %s", config->archiveDir );

	while ( FindNextFile( h, &fd ) )
	{
		if ( gpfCheckZipLogFormat( task, fd.cFileName ) == 0 ) 
		{
			continue;
		}
		if (! gpfInsertStrings(zips, strdup(fd.cFileName)) )
		{
			gpfError( "gpfInsertStrings : %s", fd.cFileName );
			break;
		}

	}
    FindClose( h );

#else

	if ( ( dp = opendir( config->archiveDir ) ) == NULL ) 
	{
		gpfSystemError( "opendir %s", config->archiveDir );
		goto errata;
	} 
	while ( ( entp = readdir( dp ) ) != NULL) 
	{
		if ( gpfCheckZipLogFormat( task, entp->d_name ) == 0 ) 
		{
			continue;
		}
		if (! gpfInsertStrings(zips, strdup(entp->d_name)) )
		{
			gpfError( "gpfInsertStrings : %s", entp->d_name );
			break;
		}
	}
	closedir(dp);

#endif
	
	if (zips != NULL && zips->size > 0 )
	{
		int i = 0;

		qsort( zips->strings, zips->size, sizeof(char *), gpfCompareString );
		for ( i = 0; i < zips->size; i++ )
		{
			int unlinkOk = 0;
			char *target = zips->strings[i];
			gpfDebug( "check %s", target );
			
			zipPath = gpfCatFile( config->archiveDir, target, NULL );
			
			if ( strcmp( target, oldestZipFile ) <= 0 && i != (zips->size - 1) )
			{
				if (i == 0)
				{
					gpfInfo( "[C][%s][Delete older zip] %s", statName, oldestZipFile );
				}
				gpfInfo( "[C][%s][Delete] %s", statName, target );

				if ( unlink( zipPath ) )
				{
					rc =gpfSystemError( "delete error %s", zipPath );
					gpfFree( zipPath );
					break;
				}
			}
			else
			{
				if ( ( rc = gpfSendCollectorData( task, target ) ) == 0 )
				{
					gpfError( "gpfSendCollectorData : %s", target );
					gpfFree( zipPath );
					break;
				}

				if ( unlink( zipPath ) )
				{
					rc =gpfSystemError( "delete error %s", zipPath );
					gpfFree( zipPath );
					break;
				}
			}
			gpfFree( zipPath );
		}
	}
	
	errata:
	gpfFree(oldestZipFile);
	gpfFreeStrings( zips );

	if ( config->mode == GPF_PROCESS_RUN ) 
	{
		gpfInfo( "[C][%s][Send All Data] %s, Elapse = %-04.2f", 
			statName, (rc == 1)?"OK":"NG", gpfTime() - startTime );
	}
	else
	{
		gpfInfo( "[C][%s][Send All Data] %s", 
			statName, (rc == 1)?"OK":"NG" );
	}
	
	return rc;
}

/**
 * Transfer unsent data 
 */
int gpfSendCollectorData( GPFTask *task, char *zipFile )
{
	int rc = 0;
	GPFConfig *config = task->config;
	GPFSchedule *schedule = NULL;
	GPFCollector *collector = task->collector;
	char *statName   = NULL;
	char *zipPath    = NULL;
	double startTime = 0;
	
	schedule  = config->schedule;
	statName  = collector->statName;
	zipPath   = gpfCatFile( config->archiveDir, zipFile, NULL );
	startTime = gpfTime();
	
	if ( schedule->postEnable )
	{
		gpfDebug( "post data : %s", zipFile );
		rc = gpfExecPostCommand( config, zipPath ) ;
	}
	else
	{
		gpfDebug( "gpfSendCollectorData : %s", zipFile );
		rc = gpfExecSOAPCommandPM( config, "--send", zipFile ) ;
	}

	if ( config->mode == GPF_PROCESS_RUN ) 
	{
		gpfNotice( "[C][%s] Send %s %s, Elapse = %-04.2f", 
			statName, zipFile, (rc == 1)?"OK":"NG", gpfTime() - startTime );
	}
	else
	{
		gpfNotice( "[C][%s][Send %s] %s", 
			statName, zipFile, (rc == 1)?"OK":"NG" );
	}
	gpfFree( zipPath );
	
	return rc;
}

/**
 * Run exist process
 */
void gpfRunExit()
{
	GPFConfig *config = GCON;
	int i;
	
	gpfDebug("Exiting process : %s", ( config ) ? "OK":"NG" );
	if ( config )
	{
		ght_hash_table_t *collectorPids = config->collectorPids;
		ght_iterator_t iterator;
		GPFTask *task      = NULL;
		const void *pidKey = NULL;
		char *statName     = NULL;
		int processCount   = 0;
		
		for ( task = (GPFTask *) ght_first( collectorPids, &iterator, &pidKey );
			task ;
			task = (GPFTask *) ght_next( collectorPids, &iterator, &pidKey ) )
		{
			ght_hash_table_t *workerPids = task->workerPids;
			statName = task->collector->statName;
			gpfNotice("kill Collector's workers [ %s ]", statName);
			task->mode = GPF_PROCESS_END;
			gpfReapTimeoutWorkers( workerPids, 0, 1 );
//			sleep( 1 );
		}
//		gpfDebug("[S] Wait collector running ");

/*
		do {
			processCount  = ght_size( collectorPids );
			gpfDebug("Running Collector : %d", processCount );
			sleep( 1 );
		} while ( processCount > 0);
		
		gpfNotice("[S] END SCHEDULER");
*/
		zbx_mutex_destroy( &taskAccessFlag );

		gpfRemoveWorkFile( config, "_running_flg" );
		unlink( config->exitFlag );
		gpfRemoveWorkDir( config );
		gpfCloseLog( config );
	}
}

#if defined _WINDOWS
void gpfServiceMain()
{ 
	pid_t exitPid           = 0;
	GPFConfig *config       = NULL;
	GPFSchedule *schedule   = NULL;
	GPFCollector *collector = NULL;
	
	config = GCON;
	if ( config != NULL )
	{
		schedule = config->schedule;

		if ( gpfCheckServiceExist(config, config->pidFile, &exitPid ) )
		{
			exit( -1 );
		}

		schedule->pid = getpid();
		gpfDebug("write _pid_getperf[%d]", schedule->pid );
		gpfWriteWorkFileNumber(config, "_pid_getperf", schedule->pid );
	
		gpfDebug( "run scheduler" );
		config->daemonFlag = 1;

		gpfRunScheduler( config );
		gpfRemoveWorkDir( config );
	}
}
#endif

