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

namespace CACTI_CLI;

use CACTI_CLI\Config;

class CactiDatabase {

	public $db_config;

	function __construct($db_config) {
		$this->db_config = $db_config;
	}

	function backup() {
		extract($this->db_config);

		$backup  = $site_home . "/lib/cacti/cacti-${cacti_version}.dmp";
	    echo "[DUMP] $backup\n";
		$command = "mysqldump -u${database_username} -p${database_password} ${database_default} > ${backup}";

	    exec($command, $messages, $retval);
	    if ($retval !== 0) {
	    	echo "[Error] $command\n\n";
	    	exit (-1);
	    }
	}

	function restore() {
		extract($this->db_config);

		$backup  = $site_home . "/lib/cacti/cacti-${cacti_version}.dmp";
		if (!file_exists($backup)) {
			echo "[Error] File not found : ${backup}\n";
			exit (-1);
		}
	    echo "[RESTORE] $backup\n";
		$command = "mysql -u${database_username} -p${database_password} ${database_default} < ${backup}";

	    exec($command, $messages, $retval);
	    if ($retval !== 0) {
	    	echo "[Error] $command\n\n";
	    	exit (-1);
	    }
	}

}

