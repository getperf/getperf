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

class GraphConfig {

	public $host_template;
	public $host_title;
	public $graph_composite;
	public $priority = 99;
	public $graphs = array();

	function __construct( $set ) {
		try {
			$this->host_template   = $this->retrieve_data("host_template", $set, true);
			$this->host_title      = $this->retrieve_data("host_title", $set, true);
			$this->graph_composite = $this->retrieve_data("graph_composite", $set, false);
			$this->priority        = $this->retrieve_data("priority", $set, false);
			$this->graphs          = $this->retrieve_data("graphs", $set, true);

		} catch (Exception $e) {
 		   echo '!!!!! Graph config error : ',  $e->getMessage(), "\n";
		}
	}

	private function retrieve_data( $key, $set, $not_null ) {
		if ( ! array_key_exists( $key, $set ) && $not_null ) 
			// return;
			throw new \Exception("$key not found");
		return ( array_key_exists( $key, $set ) ) ? $set[ $key ] : null;
	}
}

