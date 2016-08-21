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

#ifndef GETPERF_GPF_REGEXP_H

/* regular expressions */
char    *gpf_regexp_match(const char *string, const char *pattern, int *len);
char    *gpf_iregexp_match(const char *string, const char *pattern, int *len);

#define GETPERF_GPF_REGEXP_H

#endif
