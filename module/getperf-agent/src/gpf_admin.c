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
#include "gpf_soap_common.h"
#include "gpf_soap_admin.h"
#include "gpf_admin.h"

/**
 * Input user authentication
 */
int gpfSetUserInfo( GPFSetupOption *options )
{
	// if ( !options->siteKey )
	// {
		/* Enter site key */
		gpfGetLine( GPF_MSG032E, GPF_MSG032, &(options->siteKey) );
	// }

	// if ( !options->password )
	// {
		/* Enter password */
		gpfGetLine( GPF_MSG031E, GPF_MSG031, &(options->password) );
	// }

	return 1;
}


/**
 * Update module from archive file
 */
int gpfUpdateModule( GPFConfig *config, int build, char *archive, int forkFlag )
{
	int rc = 0;

	if ( gpfDownloadUpdateModule( config, build, archive) == 0 )
	{
		gpfError("getModuleArchive() failed");
	}
	else
	{
		char *modulePath = gpfCatFile( config->workCommonDir, archive, NULL);

		/* \n%s\n is new update module. Extract this zipfile and rerun setup.\n\ncd %s\nunzip %s */
		gpfMessage(GPF_MSG077E, GPF_MSG077, modulePath, config->home, modulePath);
		rc = 1;
	}

	return rc;
}

/**
 * Check core module build number
 */
int gpfRunCheckCoreUpdate( GPFConfig *config )
{
	int rc        = 1;
	int newBuild  = 0;
	int use_fork  = 1;
	char *archive = NULL;
  	char *yesno   = NULL;

	if ( (newBuild = gpsetGetLatestBuild( config )) == 0 )
	{
		/* %s core module check failed　*/
		gpfMessage( GPF_MSG079E, GPF_MSG079, GPF_MODULE_TAG );
	}
	else if ( GPF_BUILD < newBuild )
	{
		/* Getperf module [build: %d < %d] is Not the latest. Please update. */
		gpfMessage( GPF_MSG015E, GPF_MSG015, GPF_BUILD, newBuild );
		/* Update module (y/n) ? */
		gpfGetLine( GPF_MSG038E, GPF_MSG038, &yesno );
		if ( strcmp( yesno, "y" ) == 0 )
		{
			/* getperf-bin-CentOS6-x86_64-4.zip */
			archive = gpfDsprintf( archive, "getperf-bin-%s-%d.zip", GPF_MODULE_TAG, newBuild );

			if ( ( rc = gpfUpdateModule( config, newBuild, archive, use_fork) ) == 0 )
			{
				gpfError("GetLatestVersion ... NG : %s", archive);
			} else {
				exit(0);
			}
		}
	}

	gpfFree( archive );
	gpfFree( yesno );

	return rc;
}

/**
 * Regist host
 */
int gpfEntryHost( GPFConfig *config, GPFSetupConfig *setup )
{
	int rc        = 0;
	char *message = NULL;
	char *line    = NULL;

	line = gpfDsprintf( line, "SITEKEY : %s\n", setup->siteKey );
	message = gpfStrdcat( message, line );
	// line = gpfDsprintf( line, "DOMAIN  : %s\n", setup->domainName );
	// message = gpfStrdcat( message, line );
	line = gpfDsprintf( line, "HOST    : %s\n", config->host );
	message = gpfStrdcat( message, line );
	line = gpfDsprintf( line, "OSNAME  : %s\n", setup->osType );
	message = gpfStrdcat( message, line );
	// line = gpfDsprintf( line, "STAT    : %s\n", setup->statName );
	// message = gpfStrdcat( message, line );

	/* Transmit to register the following host information on '%s'\n%s */
	gpfMessage( GPF_MSG018E, GPF_MSG018, config->schedule->urlCM, message );

	while ( rc == 0)
	{
	  	char *yesno   = NULL;

		/* Regist host (y/n) ? */
		gpfGetLine( GPF_MSG040E, GPF_MSG040, &yesno );
		if ( strcmp( yesno, "n") == 0 )
		{
			gpfNotice( "exit setup" );
			exit( 0 );
		}
		else if ( strcmp( yesno, "y" ) == 0 )
		{
			rc = 1;
		}
		gpfFree( yesno );
	}

	return gpsetRegistAgent( config, setup );
}

/**
 * Run setup
 */
int gpfRunSetup( GPFSetupOption *options )
{
	int rc                = 0;
	GPFConfig *config     = NULL;
	GPFSetupConfig *setup = NULL;
	GPFSchedule *schedule = NULL;
	char    *program      = options->program;
	char    *configPath   = options->configPath;
	int     mode          = options->mode;
	int auth_rc           = 0;
	pid_t exitPid         = 0;
	char *configFile      = NULL;

	if ( (rc = gpfInitAgent( &config, program, configPath, mode )) == 0)
	{
		/* Load Error. Check the error message or run 'getperfctl.exe setup' */
		gpfMessage( GPF_MSG002E, GPF_MSG002 );
		exit (-1);
	}

	schedule = config->schedule;
	if (schedule->proxyEnable == 1 && strcmp(schedule->proxyHost, "") == 0) {
		gpfCheckHttpProxyEnv( &(config->schedule) );
	}

	if ( options->adminWebService ) {
		char *url = strdup(options->adminWebService);
		gpfRtrim(url, "/");
		url = gpfStrdcat( url, GPF_SOAP_URL_SUFFIX );
		gpfFree(schedule->urlCM);
		schedule->urlCM = url;
		printf("url=%s\n", schedule->urlCM);
	}

	GCON = config;

	if ( ( rc = gpfOpenLog( config, config->programName ) ) == 0 )
		exit (-1);

	if ( gpfCheckServiceExist( config, config->pidFile, &exitPid ) )
	{
		/* Process pid=%d is running */
		gpfMessage( GPF_MSG003E, GPF_MSG003, exitPid );

		/* Enter '%s stop' command, if you stop Agent. */
		gpfMessage( GPF_MSG044E, GPF_MSG044, GPF_GETPERFCTL );

		exit( -1 );
	}

	if (! gpfRunCheckCoreUpdate( config ) ) {
		/* Management Web service connection failed: %s */
		gpfMessage( GPF_MSG076E, GPF_MSG076, config->schedule->urlCM );
		exit (-1);
	}

	if ( gpfLoadSSLLicense( config->sslConfig, config->licenseFile ) == 0)
	{
		/* Initialize SSL license file */
		gpfMessage( GPF_MSG060E, GPF_MSG060 );
	}
	else
	{
		if (options->siteKey == NULL)
		{
			options->siteKey  = strdup(config->schedule->siteKey);
		}
		if (options->password == NULL)
		{
			options->password = strdup(config->sslConfig->code);
		}
	}

	setup = gpfCreateSetupConfig();
	gpfSetUserInfo( options );
	gpfSetSetupConfig( setup, options );

	auth_rc = gpfCheckHostStatus( config, setup );

	if ( auth_rc == 0 )
	{
		/* Login failed. Please enter the correct ID or Password or republish your ID on the portal site. */
		gpfMessage( GPF_MSG045E, GPF_MSG045 );
		goto errata;
	}
	else if ( auth_rc == -1 )
	{
		/* Unable to find the host info. Register your host site. */
		gpfMessage( GPF_MSG011E, GPF_MSG011 );
		if ( gpfEntryHost( config, setup ) == 0 )
		{
			gpfMessage( GPF_MSG046E, GPF_MSG046 );
			goto errata;
		}
	}
	else if ( auth_rc == 1 )
	{
		char dateStr[MAX_STRING_LEN];
		char *expired = config->sslConfig->expired;

		gpfGetCurrentTime( 0, dateStr, GPF_DATE_FORMAT_YYYYMMDD );
		if ( !expired || strcmp( dateStr, expired ) > 0 )
		 {
		 	if ( expired ) {
				/* License expired : %s, Regist new license. */
				gpfMessage( GPF_MSG047E, GPF_MSG047, expired );
		 	} else {
		 		/* Invarid license file, Regist new license. */
				gpfMessage( GPF_MSG080E, GPF_MSG080 );
		 	}
			if ( gpfEntryHost( config, setup ) == 0 )
			{
				gpfMessage( GPF_MSG046E, GPF_MSG046 );
				goto errata;
			}
		} else {
			/* The host already registed */
			gpfMessage( GPF_MSG081E, GPF_MSG081 );
		}
	}

	if ( setup->configZip ) {
		if (!gpfDeployConfigFile( config, NULL, setup->configZip )) {
			gpfError( "deploy % failed", setup->configZip );
			goto errata;
		}
	}

	gpfWriteWorkFile( config, "_setup_flg", "" );
	rc = 1;

errata:
	gpfRemoveWorkDir( config ) ;

	return rc;
}

/**
 * Expand the configuration file . If perfconf.zip expand the whole configuration file , otherwize expand th only SSL.
 */
int gpfDeployConfigFile( GPFConfig *config, char *pass, char *configFile)
{
	int rc           = 0;
	char *home       = config->home;
	char *archiveDir = config->archiveDir;
	char *zipPath    = NULL;
	char *workDir    = NULL;
	int perfconfFlag = 0;

	workDir = gpfCatFile( config->workDir, "conf", NULL );
	perfconfFlag = ( strcmp( configFile, "perfconf.zip" ) == 0 ) ? 1 : 0;

	if ( perfconfFlag )
	{
		gpfBackupConfig( home, archiveDir, "getperf.ini" );
		gpfBackupConfig( home, archiveDir, "conf" );
	}
	gpfBackupConfig( home, archiveDir, "network" );

	/* Backup configuration files under %s to %s. */
	gpfMessage( GPF_MSG057E, GPF_MSG057,  home, archiveDir );

	if ( gpfCheckDirectory( workDir ) == 1 )
	{
		if ( gpfRemoveDir( workDir ) == 0 )
		{
			gpfSystemError("Unable rmdir %s", workDir );
			goto errata;
		}
	}
	if ( gpfMakeDirectory( workDir ) == 0 )
	{
		gpfSystemError("Unable mkdir %s", workDir );
		goto errata;
	}

	zipPath = gpfCatFile( config->workCommonDir, configFile, NULL );
	if ( unzipDir( zipPath, workDir, pass ) == 0 )
	{
		gpfError("Unable unzip %s", zipPath );
		goto errata;
	}

	if ( perfconfFlag )
	{
		/* Update command list */
		gpfMessage( GPF_MSG067E, GPF_MSG067 );
		gpfBackupConfig( workDir, home, "conf" );
		/* Update %s configuration files */
		gpfMessage( GPF_MSG058E, GPF_MSG058,  "conf" );
	}

	/* Update %s configuration files */
	gpfBackupConfig( workDir, home, "network" );
	gpfMessage( GPF_MSG058E, GPF_MSG058,  "network" );

	rc = 1;
	errata:
	gpfFree( workDir );
	gpfFree( zipPath );

	return rc;
}

