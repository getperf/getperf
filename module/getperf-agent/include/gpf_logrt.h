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

#ifndef GETPERF_GPF_LOGRT_H
#define GETPERF_GPF_LOGRT_H

#include "gpf_config.h"

#ifdef _WINDOWS
#include "gpftypes.h"
#endif

#define GPF_LOG_SCAN_LIMIT_KB   5000
#define GPF_LOG_SCAN_LIMIT_ROW  1000
#define GPF_LOG_SCAN_FIRST_KB   10

#define GPF_WINDOWS_EVENT_SCAN_LIMIT_SIZE 2000
#define GPF_WINDOWS_EVENT_SCAN_LIMIT_ROW  1000
#define GPF_WINDOWS_EVENT_SCAN_FIRST_SITE 10

/**
  * Log extraction
  */

typedef struct GPFLogStat_t
{
	char  *fname; 			/**< Log path */
	unsigned long   inode;	/**< i node */
#ifdef _WINDOWS
    gpf_uint64_t    fsize;	/**< File size */
#else
    unsigned long   fsize;	/**< File size */
#endif
	time_t upd;				/**< Last update timestamp */
} GPFLogStat;

#ifdef _WINDOWS

/**
  * Windows event log extraction
  */
typedef struct GPFEventLog_t
{
	unsigned long timestamp;	/**< Last update timestamp */
	char *source;				/**< Event source */
	char *severeLabel;			/**< Log level */
	char *message; 				/**< Event text */
	unsigned long	eventid;	/**< Event ID */
} GPFEventLog;

GPFEventLog *gpfCreateEventLog(unsigned long timestamp, char *source, 
	char *severeLabel, char *message, unsigned long	eventid);
void gpfFreeEventLog( GPFEventLog **_eventLog );

#endif

GPFLogStat *gpfCreateLogStat(char *logPath, long inode, long fsize, time_t upd);
GPFLogStat *gpfCheckLogStat(char *logPath);
void gpfFreeLogStat( GPFLogStat **_offset );
GPFLogStat *gpfLoadLogOffset( GPFConfig *config, char *logid, char *logname );
int gpfSaveLogOffset( GPFConfig *config, GPFLogStat *offset, char *logid, char *logname );
int gpfRetrieveLog( GPFConfig *config, char *logdir, char *logname, char *logid, 
	char *regexp, char *outPath );
GPFLogStat *gpfCheckRotatedLogFile( char *logdir, char *logname );
long gpfLogTail(char *logPath, long pos, char *regexp, char **res, int *row);
int gpfSaveTailResult(char *outPath, char **res, int *row);
int split_string(const char *str, const char *del, char **part1, char **part2);
int gpfSplitFilename(const char *filename, char **directory, char **format);

#endif
