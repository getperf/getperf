<?php
/**
 * cacti-cli
 * Copyright (C) 2014-2016, Minoru Furusawa, Toshiba corporation.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

if (php_sapi_name() != 'cli') {
	die('Must run from command line');
}

error_reporting(E_ALL | E_STRICT);
ini_set('display_errors', 1);
ini_set('log_errors', 0);
ini_set('html_errors', 0);

require_once __DIR__ . '/../vendor/autoload.php';

include_once CACTI_CLI_ROOT . '/php/utils.php';
include_once CACTI_CLI_ROOT . '/php/CACTI_CLI/Config.php';
include_once CACTI_CLI_ROOT . '/php/CACTI_CLI/NodeManager.php';
include_once CACTI_CLI_ROOT . '/php/CACTI_CLI/Domain.php';
include_once CACTI_CLI_ROOT . '/php/CACTI_CLI/Node.php';
include_once CACTI_CLI_ROOT . '/php/CACTI_CLI/Metric.php';
include_once CACTI_CLI_ROOT . '/php/CACTI_CLI/SiteInfo.php';
include_once CACTI_CLI_ROOT . '/php/CACTI_CLI/ViewInfo.php';
include_once CACTI_CLI_ROOT . '/php/CACTI_CLI/GraphConfigManager.php';
include_once CACTI_CLI_ROOT . '/php/CACTI_CLI/GraphConfig.php';
include_once CACTI_CLI_ROOT . '/php/CACTI_CLI/CactiGraphSet.php';
include_once CACTI_CLI_ROOT . '/php/CACTI_CLI/CactiGraph.php';
include_once CACTI_CLI_ROOT . '/php/CACTI_CLI/CactiDomainTemplate.php';
include_once CACTI_CLI_ROOT . '/php/CACTI_CLI/CactiModelTemplate.php';
include_once CACTI_CLI_ROOT . '/php/CACTI_CLI/CactiGraphTemplate.php';
include_once CACTI_CLI_ROOT . '/php/CACTI_CLI/CactiDatabase.php';
