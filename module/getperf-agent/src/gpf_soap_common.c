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
#include "GetperfService.nsmap"
#include "stdsoap2.h"

static int _gpfSoapSSLInitFlag = 0;

/**
 * SSL SOAPの初期化（1回のみで可）
 */
void _gpfSoapSSLInit()
{
	if (!_gpfSoapSSLInitFlag)
	{
		soap_ssl_init();
		_gpfSoapSSLInitFlag = 1;
	}
}

/**
 * SOAPプロパティの設定
 * @param soap SOAP構造体
 * @param schedule スケジュール構造体
 */
void gpfSetSoapProperties(struct soap *soap, GPFSchedule *schedule)
{
	soap->connect_timeout = schedule->soapTimeout;
	soap->send_timeout    = GPF_SOAP_SEND_TIMEOUT;
	soap->recv_timeout    = GPF_SOAP_RECV_TIMEOUT;

	gpfDebug( "[SOAP TIMEOUT] %d, %d, %d", schedule->soapTimeout, GPF_SOAP_SEND_TIMEOUT, GPF_SOAP_RECV_TIMEOUT);
	if ( schedule->proxyEnable )
	{
		soap->proxy_host = schedule->proxyHost;
		soap->proxy_port = schedule->proxyPort;
		gpfDebug( "set soap proxy %s:%d", schedule->proxyHost, schedule->proxyPort );
	}
}

/**
 * SSLコンテキストの初期化
 * @param config エージェント構造体
 * @param soap SOAP構造体
 * @param sslType(GPF_SSL_NONE, GPF_SSL_DEFAULT, GPF_SSL_SERVER, GPF_SSL_CLIENT)
 * @return 合否
 */
int gpfSoapSSLClientContext( GPFConfig *config, struct soap *soap, int sslType)
{
	int rc = 0;
	
	switch (sslType) 
	{
		case GPF_SSL_NOAUTH:
			rc = soap_ssl_client_context(soap, 
				SOAP_SSL_NO_AUTHENTICATION, 
				NULL, NULL, NULL, NULL, NULL);
			gpfDebug( "[INIT SSL_NOAUTH]" );
			break;

		case GPF_SSL_SERVER:
			 rc = soap_ssl_client_context(soap,
				SOAP_SSL_REQUIRE_SERVER_AUTHENTICATION,
				NULL, GPF_SSL_KEY, config->cacertFile, NULL, NULL);
			gpfDebug( "[INIT SSL_SERVER] %s", config->cacertFile );
			break;

		case GPF_SSL_CLIENT:
			 rc = soap_ssl_client_context(soap,
				SOAP_SSL_REQUIRE_SERVER_AUTHENTICATION || SOAP_SSL_REQUIRE_CLIENT_AUTHENTICATION,
				config->clkeyFile, GPF_SSL_KEY, config->cacertFile, NULL, NULL);
			gpfDebug( "[INIT SSL_CLIENT] %s", config->clkeyFile );
			break;
	}

	if ( rc == SOAP_OK )
	{
		return 1;
	}
	else
	{
		if ( config->clkeyFile != NULL )
			gpfError( "client key file : %s", config->clkeyFile );
		if ( config->cacertFile != NULL )
			gpfError( "cacert file : %s", config->cacertFile );
		return 0;
	}
}

/**
 * SOAPインスタンスの初期化
 * @param config エージェント構造体
 * @param sslType(GPF_SSL_NONE, GPF_SSL_DEFAULT, GPF_SSL_SERVER, GPF_SSL_CLIENT)
 * @return SOAP構造体
 */
struct soap *gpfCreateSoap(GPFConfig *config, int sslType)
{
	int rc = SOAP_OK;
	GPFSchedule *schedule = NULL;
	struct soap *soap     = NULL;
	
	schedule = config->schedule;

	if ( sslType != GPF_SSL_DISABLE )
		_gpfSoapSSLInit();

	soap = soap_new();
	soap_init( soap );
	gpfSetSoapProperties( soap, schedule );

	if ( sslType == GPF_SSL_DISABLE )
		return soap;

	if ( gpfSoapSSLClientContext( config, soap, sslType ) )
		return soap;

errata:
	gpfSoapError( soap, "soap_ssl_client_context()" );
	soap_destroy( soap );
	soap_free( soap );
	return NULL;
}

/**
 * SOAPインスタンスの初期化(MIME)
 * @param config エージェント構造体
 * @param sslType(GPF_SSL_NONE, GPF_SSL_DEFAULT, GPF_SSL_SERVER, GPF_SSL_CLIENT)
 * @param zipBuffer ZIPバッファー
 * @param zipSize ZIPサイズ
 * @param filename ZIPファイル名
 * @return SOAP構造体
 */
struct soap *gpfCreateSoapWithMime(
	GPFConfig *config, int sslType, char *zipBuffer, size_t zipSize, char *filename )
{
	int rc = SOAP_OK;
	GPFSchedule *schedule = NULL;
	struct soap *soap     = NULL;
	
	schedule = config->schedule;

	if ( sslType != GPF_SSL_DISABLE )
		_gpfSoapSSLInit();

	soap = soap_new();
	soap_init( soap );
	gpfSetSoapProperties( soap, schedule );

	soap_set_mime( soap, NULL, NULL );
	soap_set_mime_attachment( soap, zipBuffer, zipSize, SOAP_MIME_BINARY, 
		"zip", filename, NULL, NULL );
	
	gpfDebug("[MIME] file=%s, size=%d", filename, zipSize );
	if ( sslType == GPF_SSL_DISABLE )
		return soap;

	if ( gpfSoapSSLClientContext( config, soap, sslType ) )
		return soap;

errata:
	gpfSoapError( soap, "soap_ssl_client_context()" );
	soap_destroy( soap );
	soap_free( soap );
	return NULL;
}

/**
 * SOAPエラーメッセージ出力
 * @param soap SOAP構造体
 * @param msg メッセージ
 */
void gpfSoapError(struct soap *soap, char *msg)
{
	const char *pFaultCode = NULL, *pFaultSubCode = NULL, *pFalutString, **iFaultCode;
	if (msg)
		gpfError( "%s", msg );

	pFalutString = *soap_faultstring( soap );
	iFaultCode = soap_faultdetail( soap );
	gpfError("%s%d[%s][%s][%s][%s]", 
		soap->version ? "SOAP 1." : "Error ", 
		soap->version ? (int)soap->version : soap->error, 
		pFaultCode ? pFaultCode : "", 
		pFaultSubCode ? pFaultSubCode : "", 
		pFalutString ? pFalutString : "", 
		iFaultCode && *iFaultCode ? *iFaultCode : "");	
}

/**
 * ZIPファイル読込み
 * @param config エージェント構造体
 * @param zipPath ZIPファイルパス
 * @param _zipSize 読込んだZIPファイルサイズ
 * @return 読み込みバッファー
 */
char *gpfReadZipFile( GPFConfig *config, const char *zipPath, size_t *_zipSize)
{
	char        *zipBuffer  = NULL;
	FILE        *zipFile    = NULL;
	size_t      zipSize     = 0;
	size_t      zipReadSize = 0;
	struct stat zipStat;

	if ( !gpfCheckPathInHome( config, zipPath ) )
		return NULL;
	
	if ( stat( zipPath, &zipStat ) == 0 )  
	{
		zipSize = zipStat.st_size;
	} 
	else 
	{
		gpfSystemError( "%s", zipPath );
		goto errata;
	}

	if ( !S_ISREG( zipStat.st_mode ) )
	{
		gpfError( "%s is not file", zipPath );
		goto errata;
	}

	if ( (zipFile = fopen(zipPath, "rb")) == NULL) 
	{
		gpfSystemError( "%s", zipPath );
		goto errata;
	}
	
	zipBuffer = (char *) malloc( zipSize + 1 );	
	zipReadSize = fread( zipBuffer, 1, zipSize, zipFile );
	
	fclose( zipFile );	
	zipBuffer[ zipReadSize ] = '\0';
	*_zipSize = zipReadSize + 1;

	gpfDebug("[Read zip] file:%s,size:%d", zipPath, zipReadSize );
	return zipBuffer;

errata:
	gpfFree( zipBuffer );
	gpf_fclose( zipFile );	
	return NULL;
}

/**
 * SOAP MIME添付データの保存
 * @param config エージェント構造体
 * @param soap SOAP構造体
 * @param zipPath ZIPファイルパス
 * @return 合否
 */
int gpfGetFileFromMIME( GPFConfig *config, struct soap *soap, char *filename)
{
	GPFSchedule *schedule     = NULL;
	struct soap_multipart *at = NULL;
	int rc                    = 0;
	char *outPath             = NULL;
	FILE *file                = NULL;
	int cnt                   = 1;
	
	schedule = config->schedule;

	for ( at = soap->mime.list; at; at = at->next ) 
	{ 
		gpfDebug( "=== MIME attachment (%d) ===", cnt ); 
		gpfDebug( "Memory=%p",      at->ptr ); 
		gpfDebug( "Size=%d",        at->size ); 
		gpfDebug( "Encoding=%d",    (int)(at->encoding) ); 
		gpfDebug( "Type=%s",        at->type?at->type:"null" ); 
		gpfDebug( "ID=%s",          at->id?at->id:"null" ); 
		gpfDebug( "Location=%s",    at->location?at->location:"null" ); 
		gpfDebug( "Description=%s", at->description?at->description:"null" ); 

		if ( at->size > 0 )
		{
			outPath = gpfCatFile( config->workCommonDir, filename, NULL );
			gpfInfo( "[Write] %s", outPath );
			if ( !( file = fopen(outPath, "wb") ) )
			{
				gpfSystemError( "%s", outPath );
				goto errata;
			}
			if ( fwrite( at->ptr, 1 , at->size, file) != at->size )
			{
				gpfSystemError( "%s", outPath );
				goto errata;
			}

			gpfFree( outPath );
			gpf_fclose( file );
			rc = 1;
			break;
		}
		cnt ++;
	}

errata:
	gpf_fclose( file );
	gpfFree( outPath );
	
	return rc;
}
