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

#ifndef GETPERF_GPF_LOG_H
#define GETPERF_GPF_LOG_H

#include "gpf_config.h"

/**
 * Log level
 */
#define GPF_EMPTY  0
#define GPF_FATAL  1
#define GPF_CRIT   2
#define GPF_ERR	   3
#define GPF_WARN   4
#define GPF_NOTICE 5
#define GPF_INFO   6
#define GPF_DBG	   7

/**
 * Log level label
 */
#define LOG_STR_FATAL	"FATAL"
#define LOG_STR_CRIT	"CRIT"
#define LOG_STR_ERR		"ERR"
#define LOG_STR_WARN	"WARN"
#define LOG_STR_NOTICE	"notice"
#define LOG_STR_INFO	"info"
#define LOG_STR_DEBUG	"dbg"

/**
 * Log output
 */
#define LOG_TYPE_UNDEFINED	0
#define LOG_TYPE_FILE		1
#define LOG_TYPE_CONSOLE	2
#define LOG_TYPE_BOTH		3

/**
 * Error code
 */
typedef enum {
	ETC = 0,
	SYSTEM_ERROR = 1001,
	FILE_NOT_FOUND,
	PATH_NOT_FOUND,
	NO_MORE_FILES,
	FILE_EXISTS,
	DISK_FULL,
	INVALID_NAME,
	BAD_PATHNAME,
	NO_SUCH_USER,
	DOMAIN_LIMIT_EXCEEDED,
	TIMEOUT,
	OUT_OF_RESOURCES,
	STRING_TOO_LONG,
	UNSUPPORTED_AUTHN_LEVEL,
	NO_SITENAME,
	INAPPROPRIATE_AUTH,
	CONFIDENTIALITY_REQUIRED,
	ALLOCATION_ERROR
} gpf_err_codes_t;

/**
 * Log rotation
 */
int gpfLogRotate( char *logPath, int logSize, int logRotation );

/**
 * Open log file
 */
int gpfOpenLog( GPFConfig *config, char *module );

/**
 * Switch log
 */
int gpfSwitchLog( GPFConfig *config, char *module, char *statName );

/**
 * Close log
 */
void gpfCloseLog( GPFConfig *config );

/**
 * Common logging message
 */
#define gpfLog(level, format, ...) \
	_gpfLog(__FILE__, __LINE__, __FUNCTION__, level, format, ##__VA_ARGS__)
int _gpfLog(const char *src, const int lno, const char *func, int level, char *format, ...);

/**
 * Error loggin message
 */
#define gpfLogError(level, systemFlag, exitFlag, format, ...) \
	_gpfLogError(__FILE__, __LINE__, __FUNCTION__, level, systemFlag, exitFlag, format, ##__VA_ARGS__)
int _gpfLogError(const char *src, const int lno, const char *func, int level, int systemFlag, int exitFlag, char *format, ...);

/**
 * Logging message(Debug|Info|Notice|Warn|Error|SystemError|Crit|Fatal|SystemFatal)
 */
#define gpfDebug( format, ...)       gpfLog(GPF_DBG,        format, ##__VA_ARGS__)
#define gpfInfo( format, ...)        gpfLog(GPF_INFO,       format, ##__VA_ARGS__)
#define gpfNotice( format, ...)      gpfLog(GPF_NOTICE,     format, ##__VA_ARGS__)
#define gpfWarn( format, ...)        gpfLog(GPF_WARN,       format, ##__VA_ARGS__)
#define gpfError( format, ...)       gpfLogError(GPF_ERR,   0, 0, format, ##__VA_ARGS__)
#define gpfSystemError( format, ...) gpfLogError(GPF_ERR,   1, 0, format, ##__VA_ARGS__)
#define gpfCrit( format, ...)        gpfLogError(GPF_CRIT,  0, 0, format, ##__VA_ARGS__)
#define gpfFatal( format, ...)       gpfLogError(GPF_FATAL, 0, 1, format, ##__VA_ARGS__)
#define gpfSystemFatal( format, ...) gpfLogError(GPF_FATAL, 1, 1, format, ##__VA_ARGS__)

/**
 * Console logging message
 */
int gpfMessage( char *commonFormat, char *localFormat, ... );

/**
 * Console logging flag (1:OK, 0:NG)
 */
int gpfMessageOKNG( int okng );

/**
 * Console loggin without CR
 */
int gpfMessageCROff( char *commonFormat, char *localFormat, ... );

/**
 * System error message
 */
char *gpfErrorFromSystem();

#endif
