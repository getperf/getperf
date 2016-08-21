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


/**
 * Check the latest build number. It becomes zero when there is no relevant module
 */
int gpsetGetLatestBuild( GPFConfig *config )
{
	int rc                = 0;
	char *result          = NULL;
	GPFSchedule *schedule = NULL;
	struct soap *soap     = NULL;
	char *module_tag      = strdup(GPF_MODULE_TAG);
	int major_ver         = GPF_MAJOR_VER;
	int build             = 0;

	schedule = config->schedule;
	if ( (soap = gpfCreateSoap( config, GPF_SSL_SERVER )) == NULL )
		return gpfError("soap initialize failed");

	if ( soap_call_ns2__getLatestBuild(
		soap, schedule->urlCM, "", module_tag, &major_ver, &result) != SOAP_OK )
	{
		gpfSoapError(soap, "soap getLatestBuild() failed");
		goto errata;
	}

	gpfInfo( "Result : %s", result );
	if ( (build = atoi(result)) > 0 ) {
		rc = 1;
	} else {
		gpfError("Invalid build number");
	}

errata:
	gpfFree( result );
	gpfFree( module_tag );
	soap_free_temp( soap );
	soap_free( soap ) ;

	return build;
}

/**
 * Regist agent
 */
int gpsetRegistAgent( GPFConfig *config, GPFSetupConfig *setup )
{
	int rc                = 0;
	char *result          = NULL;
	GPFSchedule *schedule = NULL;
	struct soap *soap     = NULL;
	int build             = 0;

	schedule = config->schedule;
	setup->configZip = strdup("sslconfig.zip");

	if ( (soap = gpfCreateSoap( config, GPF_SSL_SERVER )) == NULL )
		return gpfError("soap initialize failed");

	if ( soap_call_ns2__registAgent(
		soap, schedule->urlCM, "", setup->siteKey, config->host, setup->password, &result) != SOAP_OK )
	{
		gpfSoapError(soap, "soap checkAgent() failed");
		goto errata;
	}

	gpfInfo( "Result : %s", result );
	if ( strcmp( result, "OK") == 0 )
		rc = 1;
	else if ( strcmp( result, "Site config not found.") == 0 )
		gpfError( "Site not found %s ... NG", setup->siteKey );
	else if ( strcmp( result, "HSite accessKey check error.") == 0 )
		gpfError( "Invarid key %s ... NG", setup->password );
	else
		gpfError( "Regist agent ... NG" );

	if ( rc == 1 )
	{
		if ( (rc = gpfGetFileFromMIME( config, soap, setup->configZip )) == 0 )
		{
			gpfError( "get MIME attachement error" );
			goto errata;
		}
	}
errata:
	gpfFree( result );
	soap_free_temp( soap );
	soap_free( soap ) ;

	return rc;
}

/**
 * Douwnload update module
 */
int gpfDownloadUpdateModule( GPFConfig *config, int _build, char *moduleFile)
{
	GPFSchedule *schedule = NULL;
	struct soap *soap     = NULL;
	char *result          = NULL;
	char *module_tag      = strdup(GPF_MODULE_TAG);
	int major_ver         = GPF_MAJOR_VER;
	int build             = _build;
	int rc                = 0;

	schedule = config->schedule;

	if ( (soap = gpfCreateSoap( config, GPF_SSL_SERVER )) == NULL )
		return gpfError("soap initialize failed");

	if (soap_call_ns2__downloadUpdateModule(
		soap, schedule->urlCM, "", module_tag, &major_ver, &build,
		&result) != SOAP_OK )
	{
		gpfSoapError( soap, "soap downloadUpdateModule() failed" );
		goto errata;
	}

	gpfInfo( "Result : %s", result);
	if ( strcmp(result, "OK") == 0 )
	{
		if ( (rc = gpfGetFileFromMIME( config, soap, moduleFile )) == 0 )
		{
			gpfError( "get MIME attachement error" );
			goto errata;
		}
	}

errata:
	gpfFree( result );
	gpfFree( module_tag );
	soap_free_temp( soap );
	soap_free( soap ) ;

	return rc;
}

/**
 * Check and regist host status
 */
int gpfCheckHostStatus( GPFConfig *config, GPFSetupConfig *setup)
{
	int rc                = 0;
	char *result          = NULL;
	GPFSchedule *schedule = NULL;
	struct soap *soap     = NULL;

	schedule = config->schedule;
	if ( (soap = gpfCreateSoap( config, GPF_SSL_SERVER )) == NULL )
		return gpfError("soap initialize failed");

	if ( soap_call_ns2__checkAgent(
		soap, schedule->urlCM, "", setup->siteKey, config->host, setup->password,
		&result) != SOAP_OK )
	{
		gpfSoapError(soap, "soap checkAgent() failed");
		goto errata;
	}

	gpfInfo( "Result : %s", result );
	if ( strcmp( result, "OK") == 0 )
	{
		rc = 1;
	}
	else if ( strcmp( result, "Site not found") == 0 )
	{
		gpfError( "Invarid site %s ... NG", setup->siteKey );
	}
	else if ( strcmp( result, "Site auth error") == 0 )
	{
		gpfError( "Site auth %s ... NG", setup->siteKey );
	}
	else if ( strcmp( result, "Host not found") == 0 )
	{
		rc = -1;
	}
	else
	{
		gpfError( "Check Host %s(%s) ... NG", config->host, setup->siteKey );
	}

errata:
	gpfFree( result );
	soap_free_temp( soap );
	soap_free( soap ) ;

	return rc;
}
