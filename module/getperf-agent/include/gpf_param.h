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

#ifndef GETPERF_GPF_PARAM_H
#define GETPERF_GPF_PARAM_H

#include "gpf_config.h"
#include "gpf_common.h"
#include "gpf_param.h"

#define GPF_MAX_INCLUDE_LEVEL 10

/**
 * Parameter code 
 */

enum {
	TYPE_INT = 1, /**< Integer */
	TYPE_STRING,  /**< String */
	TYPE_BOOL     /**< True/False */
};

enum {
	PARM_OPT = 1, /**< Option */
	PARM_MAND     /**< Required */
};

enum {
	GPF_CONFIG_TYPE_FILE = 1, /**< Read from a file */
	GPF_CONFIG_TYPE_BUFFER    /**< Read from a buffer */
};

/**
 * Parameter difinition  
 */

typedef struct GPFConfigParam_t
{
	char	*parameter; /**< Parameter name */
	void	*variable;  /**< Parameter valiable */
	int	(*function)();  /**< Parameter setter */
	int	type;           /**< Parameter type */
	int	mandatory;      /**< Parameter mandatory */
	int	min;            /**< Minimum */
	int	max;            /**< Maximum */
} GPFConfigParam;


/**
 * Read parameter from file, configType selectors is file or buffer.
 */
int gpfLoadConfig(GPFSchedule *schedule, int configType, char *paramPath, char *paramBuffer);

/**
 * Configure proxy setting from http_proxy env.
 */
void gpfCheckHttpProxyEnv(GPFSchedule **_schedule);

/**
 * Parse config file
 */
int	gpfParseConfigFile(char *paramPath, GPFConfigParam *cfg, int level);


/**
 * Parse config directory
 */
int	gpfParseConfigDirectory(char *paramPath, GPFConfigParam *cfg, int level);

/**
 * Parse config live buffer
 */
int	gpfParseConfigLine(char *line, GPFConfigParam *cfg, int level);

/**
 * Collector parameter setter, stat is metric status(HW,...)
 */
int gpfSetCollector (GPFSchedule *schedule, char *param, char *stat, char *str, int val);

/**
 * Job parameter setter, stat is metric status(HW,...)
 */
int gpfSetJob (GPFSchedule *schedule, char *param, char *stat, char *str, int val);

/**
 * Parameter validation
 */
int gpfCheckSchedule (GPFSchedule *schedule);

/**
 * Read SSL license file
 */
int gpfLoadSSLLicense( GPFSSLConfig *sslConfig, char *paramPath);

#endif
