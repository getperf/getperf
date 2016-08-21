/**  
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

#ifndef GETPERF_UNICODE_H

#ifdef _WINDOWS
#include <windows.h>
LPTSTR	gpf_acp_to_unicode(LPCSTR acp_string);
int	gpf_acp_to_unicode_static(LPCSTR acp_string, LPTSTR wide_string, int wide_size);
LPTSTR	gpf_utf8_to_unicode(LPCSTR utf8_string);
LPSTR	gpf_unicode_to_utf8(LPCTSTR wide_string);
LPSTR	gpf_unicode_to_utf8_static(LPCTSTR wide_string, LPSTR utf8_string, int utf8_size);
int	_wis_uint(LPCTSTR wide_string);
#endif

#define GETPERF_UNICODE_H

#endif
