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

#ifndef GETPERF_GETPERFCTL_H
#define GETPERF_GETPERFCTL_H

#include "gpf_config.h"

#ifdef GPF_DEFAULT_LOG_LEVEL
#undef GPF_DEFAULT_LOG_LEVEL
#define GPF_DEFAULT_LOG_LEVEL GPF_DBG
#endif

#if defined _WINDOWS
int gpfRunInstallService( GPFSetupOption *options );
int gpfRunRemoveService( GPFSetupOption *options );
#endif

int gpfRunStartService( GPFSetupOption *options );
int gpfRunStopService( GPFSetupOption *options );
int main ( int argc, char **argv );

#endif /* GETPERF_GPFCONF_H */
