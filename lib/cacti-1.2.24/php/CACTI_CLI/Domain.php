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

class Domain {

	public $domain_name;
	public $options = array();
	public $nodes   = array();

	private $domain_key, $node_key, $metric_key;

	function __construct( $domain_name, $options ) {
		$this->domain_name = $domain_name;
		$this->options     = $options;
	}

	function check_domain_exists() {
		$node_home = Config::getInstance()->node_home;
		extract(get_object_vars($this));
		$domain_info_dir = "$node_home/$domain_name";
		return is_dir( $domain_info_dir );
	}

	function add_node( $title, $node ) {
		$this->nodes[$title] = $node;
		return true;
	}

	function add_all_nodes() {
		$node_home = Config::getInstance()->node_home;
		extract(get_object_vars($this));
		$domain_info_dir = "$node_home/$domain_name";
		if ( is_dir( $domain_info_dir ) ) {
			if ( $nodes = scandir( $domain_info_dir ) ) {
				foreach ( $nodes as $node ) {
					if ($node === "." || $node === "..")
						continue;
					$node_info = new Node( $domain_name, $node, $options );
					$node_info->read_node_info();
					if (! $node_info->add_all_metrics() )
						return false;
					$this->add_node( $node, $node_info);
				}
			}
		}
		return true;		
	}

	function find_first_metric() {
		foreach ($this->nodes as $node_name => $node) {
			foreach ( $node->metrics as $metric_name => $metric ) {
				return implode("/", array($this->domain_name, $node_name, $metric_name) );
			}
		}
		return false;
	}
}

