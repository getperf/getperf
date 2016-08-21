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

#ifndef GETPERF_SYSINC_H
#define GETPERF_SYSINC_H

#if defined(_WINDOWS)

# pragma warning ( disable : 4819 )
# pragma warning ( disable : 4996 ) 
/* warning C4996: <function> was declared deprecated */

#define _WIN32_WINNT 0x0400
# include <WinSock2.h>
# include <windows.h>
# include <conio.h>
# include <stdio.h>
# include <stdlib.h>
# include <stddef.h>
# include <string.h>
# include <time.h>
# include <tchar.h>
# include <process.h>
# include <direct.h>
# include <io.h>
# include <errno.h>
# include <signal.h>
# include <sys/types.h>
# include <sys/stat.h>
# include <sys/timeb.h>
# include <tlhelp32.h>
# include <assert.h>

# ifndef S_ISDIR
#  define S_ISDIR(mode)  (((mode) & S_IFMT) == S_IFDIR)
# endif

# ifndef S_ISREG
#  define S_ISREG(mode)  (((mode) & S_IFMT) == S_IFREG)
# endif

# ifndef sleep
#  define sleep(sec)  Sleep( 1000 * sec)
# endif

typedef DWORD pid_t;

# ifndef stat 
#  ifdef _stat 
#   define stat _stat
/*
#   define stat(a,b) _stat(a,b) 
*/
#  endif
# endif

# define unlink(a) _unlink(a) 
# define mkdir(a, b) _mkdir(a) 

#else

# include <stdio.h>
 #include "config.h"

#endif /* _WINDOWS */

#if defined(__FreeBSD__)
#include <sys/signal.h>
#endif

/* va_copy */
#ifndef va_copy 
# ifdef __va_copy 
#  define va_copy(a,b) __va_copy(a,b) 
# else /* !__va_copy */ 
#  define va_copy(a,b) ((a)=(b)) 
# endif /* __va_copy */ 
#endif /* va_copy */

#ifndef _WINDOWS

#if defined(__FreeBSD__)
#include <sys/signal.h>
#endif

#ifdef HAVE_STDLIB_H
#	include <stdlib.h>
#endif

#ifdef HAVE_STRING_H
#	include <string.h>
#endif

#ifdef HAVE_TERMIOS_H
#	include <termios.h>
#endif

#ifdef HAVE_ASSERT_H
#	include <assert.h>
#endif

#ifdef HAVE_ERRNO_H
#	include <errno.h>
#endif

#ifdef HAVE_WINSOCK2_H
#	include <winsock2.h>
#endif

#ifdef HAVE_WS2TCPIP_H
#	include <ws2tcpip.h>
#endif

#ifdef HAVE_WSPIAPI_H
#	include "Wspiapi.h"
#endif

#ifdef HAVE_WINDOWS_H
#	include <windows.h>
#endif

#ifdef HAVE_PROCESS_H
#	include <process.h>
#endif

#ifdef HAVE_STDARG_H
#	include <stdarg.h>
#endif

#ifdef HAVE_CTYPE_H
#	include <ctype.h>
#endif

#ifdef HAVE_GRP_H
#	include <grp.h>
#endif

#ifdef HAVE_REGEX_H
#	include <regex.h>
#endif

#ifdef HAVE_SYS_TYPES_H
#	include <sys/types.h>
#endif

#ifdef HAVE_SYS_TIME_H
#	include <sys/time.h>
#endif

#ifdef HAVE_SYS_SEM_H
#	include <sys/sem.h>
#endif


#ifdef HAVE_UTIME_H
#	include <utime.h>
#endif

#ifdef HAVE_DIRENT_H
#	include <dirent.h>
#endif

#ifdef HAVE_DEVSTAT_H
#	include <devstat.h>
#endif

#ifdef HAVE_SYS_WAIT_H
#	include <sys/wait.h>
#endif

#ifdef HAVE_PWD_H
#	include <pwd.h>
#endif

#ifdef HAVE_SIGNAL_H
#	include <signal.h>
#	include <sys/signal.h>
#endif

#ifdef HAVE_STDINT_H
#	include <stdint.h>
#endif

#ifdef HAVE_SYS_PROC_H
#	include <sys/proc.h>
#endif

#ifdef HAVE_SYS_SOCKET_H
#	include <sys/socket.h>
#endif

#ifdef HAVE_SYS_STAT_H
#	include <sys/stat.h>
#endif

#ifdef HAVE_SYS_STATVFS_H
#	include <sys/statvfs.h>
#endif

#ifdef HAVE_SYS_SWAP_H
#	include <sys/swap.h>
#endif

#ifdef HAVE_SYS_SYSCALL_H
#	include <sys/syscall.h>
#endif

#ifdef HAVE_SYS_SYSCTL_H
#	include <sys/sysctl.h>
#endif

#ifdef HAVE_SYS_SYSINFO_H
#	include <sys/sysinfo.h>
#endif

#ifdef HAVE_SYS_SYSMACROS_H
#	include <sys/sysmacros.h>
#endif

#ifdef HAVE_TIME_H
#	include <time.h>
#endif

#ifdef HAVE_UNISTD_H
#	include <unistd.h>
#endif

#ifdef HAVE_SYS_FILE_H
#	include <sys/file.h>
#endif

#ifdef HAVE_FCNTL_H
#	include <sys/fcntl.h>
#endif

#ifdef HAVE_SYS_IOCTL_H
#	include <sys/ioctl.h>
#endif

#ifdef HAVE_MATH_H
#	include <math.h>
#endif

#ifdef HAVE_SYS_TIMEB_H
#	include <sys/timeb.h>
#endif

#ifdef HAVE_PROCINFO_H
#	undef T_NULL /* to solve definition conflict */
#	include <procinfo.h>
#endif

#ifdef HAVE_SYS_PRCTL_H
#	include <sys/prctl.h>
#endif

#endif /* ndef _WINDOWS */

#endif
