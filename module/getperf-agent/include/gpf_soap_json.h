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

#ifndef GETPERF_GPF_GSOAP_JSON_H
#define GETPERF_GPF_GSOAP_JSON_H

#include "gpf_config.h"

/**
 * GetperfCMService License
 * eg ： [{"site_id" : 1,"amount" : { "ORACLE" : 4,"HW" : 9}}]
 */
int gpsetParseLicense(GPFSetupConfig *setup, char *data);

/**
 * GetperfCMService Domain
 * eg: [{"site_id" : 1,"domain" : [ {"ID" : 1, "NAME" : "d11"},{"ID" : 20, "NAME" : "  DB"},
 *      {"ID" : 23, "NAME" : "  HUB"},{"ID" : 21, "NAME" : "  APL"},{"ID" : 22, "NAME" : "    Web"},
 *      {"ID" : 24, "NAME" : "d12"}]}]
 */
int gpsetParseDomain(GPFSetupConfig *setup, char *data);

/**
 * GetperfCMService support OS
 * eg ： [{"STAT" : "HW", "OS" : "Linux"},{"STAT" : "HW", "OS" : "Windows"}]
 */
int gpsetParseSupportOS(GPFSetupConfig *setup, char *data);

/**
 * GetperfCMService Verify command
 * eg : [ {"METRIC" : "CPU", "METRIC_ID" : 1, "PRIORITY" : 1, "FILENAME" : "vmstat", 
 *  "CMD" : "vmstat", "PRIORITY_PATH" : "/usr/bin", "TEST_CMD_OPT" : "-n __sec__ __cnt__", 
 *  "VER_OPT" : "-V"},...]
 */
int gpsetParseVerifyCommands(GPFSetupConfig *setup, char *data);

/**
 * GetperfCMService Host
 */
int gpsetParseHostStatus(GPFSetupConfig *setup, char *data);

#endif
