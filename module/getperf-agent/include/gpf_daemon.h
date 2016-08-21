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

#ifndef GETPERF_GPF_DAEMON_H
#define GETPERF_GPF_DAEMON_H

#include "gpf_config.h"
#include "gpf_common.h"
#include "gpf_log.h"

#if !defined(_WINDOWS)

/**
 * Daemon signal handler
 */
void gpfChildSignalHandler(int sig);

/**
 * Redirection of stdout. If logPath is NULL then output /dev/null
 */
void gpfRedirectStd(const char *logPath);

/**
 * Daemonize. argv is run arguments, The last element is required to be null
 */
int	gpfDaemonStart( char *exePath, char *argv[], char *logPath );

#endif
#endif
