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

#ifndef GETPERF_GPF_SOAP_ADMIN_H
#define GETPERF_GPF_SOAP_ADMIN_H

/**
 * Check latest version
 */
int gpsetGetLatestVersion( GPFConfig *config, GPFSetupConfig *setup );

/**
 * Check latest build. If not found, it return 0
 */
int gpsetGetLatestBuild( GPFConfig *config );

/**
 * Download update module
 */
int gpfDownloadUpdateModule( GPFConfig *config, int _build, char *moduleFile );

/**
 * License check. Set SITE_ID, amout of LICENSES
 */
int gpsetCheckSiteLicense( GPFConfig *config, GPFSetupConfig *setup );

/**
 * Regist agent
 */
int gpsetRegistAgent( GPFConfig *config, GPFSetupConfig *setup );

/**
 * Check domain. Set SITE_ID, amout of DOMAINS
 */
int gpfCheckDomain( GPFConfig *config, GPFSetupConfig *setup);

/**
 * Get verify commands
 */
int gpfCheckVerifyCommand( GPFConfig *config, GPFSetupConfig *setup);

/**
 * Regis host
 */
int gpfRegistHost( GPFConfig *config, GPFSetupConfig *setup);

/**
 * Check and regist host status
 */
int gpfCheckHostStatus( GPFConfig *config, GPFSetupConfig *setup);

/**
 * Request SSL client cert
 */
int gpfRequestCertifyHost( GPFConfig *config, GPFSetupConfig *setup);

/**
 * Check core module update
 */
int gpfCheckCoreUpdate( GPFConfig *config, char *osname, char *arch );

/**
 * Check collection module update
 */
int gpfCheckStatUpdate( GPFConfig *config, GPFSetupConfig *setup, char *ostag );

/**
 * Send verify results
 */
int gpfSendVerifyResult( GPFConfig *config, GPFSetupConfig *setup, char *filename );

/**
 * Download config file with user password
 */
int gpfDownloadConfigFileCM( GPFConfig *config, GPFSetupConfig *setup, char *configFile);

/**
 * Download module archive to work directory
 */
int getModuleArchive( GPFConfig *config, int majorVer, char *archive);

#endif
