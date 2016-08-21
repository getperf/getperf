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

#define __POSIX_VISIBLE (1)
#include "gpf_config.h"
#include "gpf_common.h"
#include "gpf_log.h"
#include <sys/signal.h>

#if !defined(_WINDOWS)

/**
 * 標準入出力のリダイレクション(UNIX限定)
 * @param logPath ログパス名（NULLの場合は "/dev/null" を指定）
 */
void gpfRedirectStd(const char *logPath)
{
	int fd;
	const char defaultFile[] = "/dev/null";
	const char *outFile = defaultFile;
	int openFlags = O_WRONLY;

	close(fileno(stdin));
	open(defaultFile, O_RDWR);

	if( logPath && *logPath)
	{
		outFile = logPath;
		openFlags |= O_CREAT | O_APPEND;
	}

	if ( (fd = open(outFile, openFlags, 0666)) != -1 )
	{
		if( dup2(fd, fileno(stderr)) == -1 )
			gpfSystemError("%s", outFile);

		if( dup2(fd, fileno(stdout)) == -1 )
			gpfSystemError("%s", outFile);
		close(fd);
	}
	else
	{
		gpfSystemError("%s", outFile);
		exit( -1 );
	}
}

/**
 * デーモン化(UNIX限定)
 * @param exePath コマンド名
 * @param argv 利用可能な引き数リスト。終端は必ず NULL で終わらなければならない。 
 * @param logPath ログパス名
 * @return 合否
 */
int	gpfDaemonStart( char *exePath, char *argv[], char *logPath )
{
	pid_t   		 pid;

	signal( SIGHUP, SIG_IGN );
    signal( SIGALRM, SIG_IGN );
    signal( SIGPIPE, SIG_IGN );
    signal( SIGTERM, SIG_IGN );

	if( (pid = fork()) != 0 )
		exit( 0 );

	setsid();
	
	if ( chdir("/") == -1 )
		return gpfSystemError( "chdir /" );

	umask(0002);

	gpfRedirectStd( logPath );

	if ( ( pid = fork() ) == 0 )
	{
	    execv( exePath, argv );
	}
	return ( pid > 0 ) ? 1 : 0;
}

#endif
