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

if ( 'cli' !== PHP_SAPI ) {
	echo "Only CLI access.\n";
	die(-1);
}

if ( version_compare( PHP_VERSION, '5.3.0', '<' ) ) {
	printf( "Error: CACTI-CLI requires PHP %s or newer. You are running version %s.\n", '5.3.0', PHP_VERSION );
	die(-1);
}

define( 'CACTI_CLI_ROOT', dirname( __DIR__ ) );

include CACTI_CLI_ROOT . '/php/cacti-cli.php';

function cli_autoload( $className ) {
	$className = ltrim($className, '\\');
	$fileName  = '';
	$namespace = '';
	if ($lastNsPos = strrpos($className, '\\')) {
		$namespace = substr($className, 0, $lastNsPos);
		$className = substr($className, $lastNsPos + 1);
		$fileName  = str_replace('\\', DIRECTORY_SEPARATOR, $namespace) . DIRECTORY_SEPARATOR;
	}
	$fileName .= str_replace('_', DIRECTORY_SEPARATOR, $className) . '.php';

	if ( 'CACTI_CLI' !== substr( $fileName, 0, 9 ) ) {
		return;
	}

	require dirname( dirname( __FILE__ ) ) . '/php/' . $fileName;
}

spl_autoload_register( 'cli_autoload' );
