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

#ifndef GETPERF_GPF_SERVICE_H
#define GETPERF_GPF_SERVICE_H

#if !defined(_WINDOWS)
#	error "This module allowed only for Windows OS"
#endif /* _WINDOWS */

void	service_start();

int	gpfCreateService( const char *cmd );
int	gpfRemoveService();
int	gpfStartService();
int	gpfStopService();

void	set_parent_signal_handler();

int	application_status;	/* required for closing application from service */

#define GPF_APP_STOPPED	0
#define GPF_APP_RUNNING	1

#define GPF_IS_RUNNING()	(GPF_APP_RUNNING == application_status)
#define GPF_DO_EXIT()		application_status = GPF_APP_STOPPED

#define GPF_START_MAIN_ENTRY(a)	service_start()

#endif /* GETPERF_GPF_SERVICE_H */
