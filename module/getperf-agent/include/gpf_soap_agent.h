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

#ifndef GETPERF_GPF_SOAP_AGENT_H
#define GETPERF_GPF_SOAP_AGENT_H

/**
 * Reserve sender service
 */
int gpfReserveSender( GPFConfig *config, char *filename );

/**
 * Send data
 */
int gpfSendData( GPFConfig *config, char *filename);

/**
 * Download certfile, when it is newer than timestamp
 */
int gpfDownloadCertificate( GPFConfig *config, long timestamp );

/**
 * Send message. Severity(1:Info, 2:Warn, 3:Error, 4:Crit)
 */
int gpfSendMessage( GPFConfig *config, int severity, char *message );

/**
 * Reserve file sender.onOff is "ON" or "OFF". 
 * waitSec is return value, which is the sleep time of next reserve.
 */
int gpfReserveFileSender( GPFConfig *config, char *onOff, int *waitSec );

/**
 * Send zip data
 */
int gpfSendZipData( GPFConfig *config, char *filename);

/**
 * Download config file of client cert
 */
int gpfDownloadConfigFilePM( GPFConfig *config, char *configFile);

#endif
