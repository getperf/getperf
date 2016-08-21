/* 
** GETPERF
** Copyright (C) 2015-2016, Minoru Furusawa, Toshiba corporation.
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

#ifndef GETPERF_GPF_GSOAP_COMMON_H
#define GETPERF_GPF_GSOAP_COMMON_H

#include "gpf_config.h"
#include "gpf_common.h"

#include	"soapH.h"
#include	"stdsoap2.h"

#define GPF_SSL_DISABLE 0
#define GPF_SSL_NOAUTH  1
#define GPF_SSL_SERVER  2
#define GPF_SSL_CLIENT  3

/* #define GPF_SSL_KEY "goliath1" */
#define GPF_SSL_KEY "getperf"

/**
 * SSL SOAP Initialize
 */

void _gpfSoapSSLInit();

/**
 * Setter of SOAP properties
 */
void gpfSetSoapProperties(struct soap *soap, GPFSchedule *schedule);


/**
 * Initialize SSL contexist.
 * sslType is GPF_SSL_NONE, GPF_SSL_DEFAULT, GPF_SSL_SERVER, GPF_SSL_CLIENT
 */
int gpfSoapSSLClientContext( GPFConfig *config, struct soap *soap, int sslType);

/**
 * Initialize SOAP instance.
 * sslType is GPF_SSL_NONE, GPF_SSL_DEFAULT, GPF_SSL_SERVER, GPF_SSL_CLIENT
 */
struct soap *gpfCreateSoap(GPFConfig *config, int sslType);

/**
 * Initialize SOAP instance with MIME.
 * sslType is GPF_SSL_NONE, GPF_SSL_DEFAULT, GPF_SSL_SERVER, GPF_SSL_CLIENT
 */
struct soap *gpfCreateSoapWithMime(
	GPFConfig *config, int sslType, char *zipBuffer, size_t zipSize, char *filename );


/**
 * Get SOAP error message
 */
void gpfSoapError(struct soap *soap, char *msg);

/**
 * Read ZIP file
 */
char *gpfReadZipFile( GPFConfig *config, const char *zipPath, size_t *_zipSize);

/**
 * Save SOAP MIME file
 */
int gpfGetFileFromMIME( GPFConfig *config, struct soap *soap, char *filename );

#endif
