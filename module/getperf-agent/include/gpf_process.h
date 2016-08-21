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

#ifndef GETPERF_GPF_PROCESS_H
#define GETPERF_GPF_PROCESS_H

#include "gpf_config.h"

/**
 * Check service exist. return 1 if exists
 */
int gpfCheckServiceExist( GPFConfig *config, char *pidFile, pid_t *pid );

/**
 * CHeck process. keyword is command name of search process. If null, nothing to do
 */
int gpfCheckProcess( pid_t pid, char *keyword );

/**
 * Get thread id
 */
GPFThreadId gpfGetThreadId( );

/**
 * Get process id
 */
pid_t gpfGetProcessId( );


/**
 * Kill process
 */
int gpfKill( pid_t pid);

/**
 * Execute command and set process id, If timeout is 0 then it return 1 with no wait
 */
int gpfExecCommand(char *execCommand, int timeout, char *outPath, char *errPath, pid_t *child, int *exitCode ) ;

/**
 * Execute command interactive
 */
int gpfExecCommandInteractive(char *execCommand, int *exitCode );

/**
 * Signal handler. It set SIGTERM only. SIGTERM signal run gpfStopProcess()
 */
#if defined(_WINDOWS)
BOOL WINAPI HandlerRoutine(DWORD dwCtrlType);
#endif

void	gpfChildSignalHandler(int sig);

/**
 * Signal hander of stop process
 */
int gpfStopProcess( );

/**
 * Signal setter
 */
void	gpfSetSignal( void );

#endif
