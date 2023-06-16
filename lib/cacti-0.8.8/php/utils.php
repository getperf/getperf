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

// Utilities that depend on Cacti code.

namespace CACTI_CLI\Utils;

function get_site_home() {
	$site_home = getcwd();
	while ( ! file_exists ( "$site_home/.git" ) ) {
		if ( preg_match("/^(.+)\/(.+?)$/", $site_home, $matchs) == 1) {
			$site_home = $matchs[1];
		} else {
			break;
		}
	}
	return ( file_exists( "$site_home/html/cacti") ) ? $site_home : null;
}

function get_cacti_cli_home($site_home) {
	$cacti_cli_home = realpath("$site_home/html/cacti/cli");
	return file_exists( $cacti_cli_home ) ? $cacti_cli_home : null;
}


function read_json( $json_file ) {
	$json_info = array();
	try {
		ob_start();
		$json = file_get_contents( $json_file );
		$json = mb_convert_encoding($json, 'UTF8', 'ASCII,JIS,UTF-8,EUC-JP,SJIS-WIN');
		$json_info = json_decode($json, true);
	    $warning = ob_get_contents();
	    ob_end_clean();
	    if (strlen($warning) > 0 || $json_info === NULL) {
	        throw new \Exception($warning);
	    }			
	} catch (\Exception $e) {
	    echo 'JSON parse error : ' . $e->getMessage() . ' in ' . $json_file;
	    echo $e->getTraceAsString();
	    exit;
	}		 
	return $json_info;
}

function time_elapsed()
{
    static $last = null;

    $now = microtime(true);
    if ($last != null) {
        echo 'Elapse : ' . ($now - $last) . "\n";
    }

    $last = $now;
}
