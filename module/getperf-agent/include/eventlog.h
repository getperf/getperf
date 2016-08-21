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
** Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
**/

#ifndef GETPERF_EVENTLOG_H
#define GETPERF_EVENTLOG_H

#include "gpftypes.h"
#include "gpf_logrt.h"

#ifndef _WINDOWS
#	error "This module is only available for Windows OS"
#endif

int	process_eventlog(const char *source, gpf_uint64_t *lastlogsize, char *regexp,
	GPFEventLog **eventLog, int *row, unsigned char skip_old_data);
int gpfSaveEventLogResult(char *outPath, GPFEventLog **res, int *row);
int gpfPutEventLog(GPFEventLog *ev, FILE *out);
int gpfRetrieveWindowsEventLog( GPFConfig *config, char *logid, char *eventname, 
	char *regexp, char *outDir, int _skip_old_data );
	
#endif /* GETPERF_EVENTLOG_H */
