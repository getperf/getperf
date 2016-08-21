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
#include "gpf_soap_agent.h"

/**
 * ファイル送信サービスの予約
 * @param config エージェント構造体
 * @param filename 転送ファイル
 * @return 合否
 */
int gpfReserveSender( GPFConfig *config, char *filename )
{
	int rc                = 0;
	int value             = 0;
	int fileSize          = 0;
	char *zipPath         = NULL;	
	char *result          = NULL;
	char *invalidValue    = NULL;
	GPFSchedule *schedule = NULL;
	struct soap *soap     = NULL;
	struct stat zipStat;
	
	zipPath = gpfCatFile( config->archiveDir, filename, NULL);
	if ( stat( zipPath, &zipStat ) == 0 )  
	{
		fileSize = zipStat.st_size;
	} 
	else 
	{
		gpfSystemError( "%s", zipPath );
		goto errata2;
	}
	schedule = config->schedule;
/*
	if ( (soap = gpfCreateSoap( config, GPF_SSL_NOAUTH )) == NULL)
		return gpfError("soap initialize failed");
*/
	if ( (soap = gpfCreateSoap( config, GPF_SSL_CLIENT )) == NULL)
		return gpfError("soap initialize failed");

	gpfDebug("SOAP request gpfReserveSender()" );
	gpfDebug("URL      = %s", schedule->urlPM );
	gpfDebug("siteKey  = %s", schedule->siteKey );
	gpfDebug("filename = %s", filename );
	gpfDebug("fileSize = %d", fileSize );

	if ( soap_call_ns1__reserveSender(
		soap, schedule->urlPM, "", schedule->siteKey, filename, &fileSize, &result) != SOAP_OK)
	{
		gpfSoapError(soap, "soap gpfReserveSender() failed");
		goto errata;
	}

	if (strcmp(result, "OK") == 0 ) 
	{
		rc = 1;		
	} 
	else 
	{
		gpfError("Result : %s", result);
	}
	
errata:
	gpfFree( result );
	soap_free_temp( soap );
	soap_free( soap ) ;
errata2:
	gpfFree( zipPath );
	
	return rc;
}

/**
 * リモートホストにデータ送信
 * @param config エージェント構造体
 * @param filename ファイル名
 * @return 合否
 */
int gpfSendData( GPFConfig *config, char *filename)
{
	int         rc         = 0;
	int         cnt        = 0;
	char        *zipPath   = NULL;	
	char        *zipBuffer = NULL;	
	char        *result    = NULL;
	GPFSchedule *schedule  = NULL;
	struct soap *soap      = NULL;
	size_t      zipSize;

	schedule = config->schedule;
	zipPath = gpfCatFile( config->archiveDir, filename, NULL);

	if ( ( zipBuffer = gpfReadZipFile( config, zipPath, &zipSize ) ) == NULL )
		goto errata2;

	if ( (soap = gpfCreateSoapWithMime( config, GPF_SSL_CLIENT, zipBuffer, zipSize, filename )) == NULL)
	{
		gpfError( "soap initialize failed" );
		goto errata;
	}
	
	if ( soap_call_ns1__sendData(
		soap, schedule->urlPM, "", schedule->siteKey, filename, &result) != SOAP_OK )
	{
		gpfSoapError( soap, "soap sendData() failed" );
		goto errata;
	}

	if ( strcmp( result, "OK" ) == 0 ) 
	{
		rc = 1;
	} 
	else
	{
		gpfError( "Result : %s", result );
	} 
		
errata:
	gpfFree( zipBuffer );
	gpfFree( result );
	soap_free_temp( soap );
	soap_free( soap ) ;

errata2:
	gpfFree( zipPath );

	return rc;
}

/**
 * 構成ファイルのダウンロード(PM用、クライアント認証使用)
 * @param config エージェント構造体
 * @param severity 警告レベル(1:情報,2:警告,3:エラー,4:致命的)
 * @param message メッセージ
 * @return 合否
 */
int gpfSendMessage( GPFConfig *config, int severity, char *message )
{
	GPFSchedule *schedule = NULL;
	struct soap *soap     = NULL;
	char *result          = NULL;
	int rc                = 0;
	
	schedule = config->schedule;

	if ( (soap = gpfCreateSoap( config, GPF_SSL_CLIENT )) == NULL )
		return gpfError("soap initialize failed");
	
	if (soap_call_ns1__sendMessage(
		soap, schedule->urlPM, "", schedule->siteKey, config->host, &severity, message, 
		&result) != SOAP_OK )
	{
		gpfSoapError( soap, "soap_call_ns1__sendMessage()" );
		goto errata;
	}

	gpfInfo( "Result : %s", result);
	if ( strcmp(result, "OK") == 0 )
	{
		rc = 1;
	}

errata:
	gpfFree( result );
	soap_free_temp( soap );
	soap_free( soap ) ;
	
	return rc;
}

/**
 * 構成ファイルのダウンロード(PM用、クライアント認証使用)
 * @param config エージェント構造体
 * @param timestamp 前回更新のエポックタイム[ミリ秒]。ファイル更新日時より古い場合のみダウンロード
 * @return 合否
 */
int gpfDownloadCertificate( GPFConfig *config, long timestamp )
{
	GPFSchedule *schedule = NULL;
	struct soap *soap     = NULL;
	char *result          = NULL;
	int rc                = 0;
	
	schedule = config->schedule;

	if ( (soap = gpfCreateSoap( config, GPF_SSL_CLIENT )) == NULL )
		return gpfError("soap initialize failed");
	
	if (soap_call_ns1__downloadCertificate(
		soap, schedule->urlPM, "", schedule->siteKey, config->host, &timestamp, &result) != SOAP_OK )
	{
		gpfSoapError( soap, "soap_call_ns1__downloadCertificate()" );
		goto errata;
	}

	gpfInfo( "Result : %s", result);
	if ( strcmp(result, "OK") == 0 )
	{
		if ( (rc = gpfGetFileFromMIME( config, soap, "sslconf.zip" )) == 0 )
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
 * ファイル送信サービスの予約
 * @param config エージェント構造体
 * @param onOff "ON" or "OFF"
 * @param waitSec 待ち時間(秒)
 * @return 合否
 */
int gpfReserveFileSender( GPFConfig *config, char *onOff, int *waitSec )
{
	int rc                = 0;
	int value             = 0;
	char *result          = NULL;
	char *invalidValue    = NULL;
	GPFSchedule *schedule = NULL;
	struct soap *soap     = NULL;
	
	if (strcmp(onOff, "ON") != 0 && strcmp(onOff, "OFF") != 0 )
		return gpfError("onOff parameter must be 'ON' or 'OFF'");

	schedule = config->schedule;
/*
	if ( (soap = gpfCreateSoap( config, GPF_SSL_NOAUTH )) == NULL)
		return gpfError("soap initialize failed");
*/
	if ( (soap = gpfCreateSoap( config, GPF_SSL_CLIENT )) == NULL)
		return gpfError("soap initialize failed");

	gpfDebug("SOAP request reserveSendPerfData()" );
	gpfDebug("URL     = %s", schedule->urlPM );
	gpfDebug("siteKey = %s", schedule->siteKey );
	gpfDebug("host    = %s", config->host );
	gpfDebug("onOff   = %s", onOff );

	if ( soap_call_ns1__reserveSendPerfData(
		soap, schedule->urlPM, "", schedule->siteKey, config->host, onOff, &result) != SOAP_OK)
	{
		gpfSoapError(soap, "soap reserveSendPerfData() failed");
		goto errata;
	}

	gpfInfo("Result : %s", result);
	if (strcmp(result, "0") == 0 || strcmp(result, "Ok") == 0 )
	{
		rc = 1;
		*waitSec = 0;
	}
	else
	{
		invalidValue = result;
		value = strtol(result, &invalidValue, 10);  
		if (*invalidValue != '\0')
			gpfError("parse error '%s'", result );
		else
		{
			rc = 1;
			*waitSec = value;
		}
	}
	
errata:
	gpfFree( result );
	soap_free_temp( soap );
	soap_free( soap ) ;
	
	return rc;
}

/**
 * リモートホストにデータ送信
 * @param config エージェント構造体
 * @param filename ファイル名
 * @return 合否
 */
int gpfSendZipData( GPFConfig *config, char *filename)
{
	int         rc         = 0;
	int         cnt        = 0;
	char        *zipPath   = NULL;	
	char        *zipBuffer = NULL;	
	char        *result    = NULL;
	GPFSchedule *schedule  = NULL;
	struct soap *soap      = NULL;
	size_t      zipSize;

	schedule = config->schedule;
	zipPath = gpfCatFile( config->archiveDir, filename, NULL);

	if ( ( zipBuffer = gpfReadZipFile( config, zipPath, &zipSize ) ) == NULL )
		goto errata2;

	if ( (soap = gpfCreateSoapWithMime( config, GPF_SSL_CLIENT, zipBuffer, zipSize, filename )) == NULL)
	{
		gpfError( "soap initialize failed" );
		goto errata;
	}
	
	if ( soap_call_ns1__sendPerfData(
		soap, schedule->urlPM, "", schedule->siteKey, config->host, filename, &result) != SOAP_OK )
	{
		gpfSoapError( soap, "soap sendPerfData() failed" );
		goto errata;
	}

	gpfInfo( "Result : %s", result );
	if ( strcmp( result, "Ok" ) == 0 )
		rc = 1;
		
errata:
	gpfFree( zipBuffer );
	gpfFree( result );
	soap_free_temp( soap );
	soap_free( soap ) ;

errata2:
	gpfFree( zipPath );

	return rc;
}

/**
 * 構成ファイルのダウンロード(PM用、クライアント認証使用)
 * @param config エージェント構造体
 * @param configFile 構成ファイル
 * @return 合否
 */
int gpfDownloadConfigFilePM( GPFConfig *config, char *filename )
{
	GPFSchedule *schedule = NULL;
	struct soap *soap     = NULL;
	char *result          = NULL;
	int rc                = 0;
	int cnt               = 1;
	
	schedule = config->schedule;

	if ( (soap = gpfCreateSoap( config, GPF_SSL_CLIENT )) == NULL )
		return gpfError("soap initialize failed");
	
	if (soap_call_ns1__getPerfConfigFile(
		soap, schedule->urlPM, "", schedule->siteKey, config->host, filename, 
		&result) != SOAP_OK )
	{
		gpfSoapError( soap, "soap_call_ns1__getPerfConfigFile()" );
		goto errata;
	}

	gpfInfo( "Result : %s", result);
	if ( strcmp(result, "Ok") == 0 )
	{
		if ( (rc = gpfGetFileFromMIME( config, soap, filename )) == 0 )
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

