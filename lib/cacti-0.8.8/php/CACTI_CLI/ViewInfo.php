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

class ViewInfo {

	private static $instance;
	public $nodes = array();

	function __construct( ) {
		$view_home = Config::getInstance()->view_home;
		$tenants = scandir( $view_home );
		foreach ($tenants as $tenant) {
			if ($tenant === "." || $tenant === "..")
				continue;
			$tenant_dir = $view_home . "/" . $tenant;
			$domain_dirs = scandir( $tenant_dir );
			foreach ($domain_dirs as $domain) {
				$domain_dir = $tenant_dir . "/" . $domain;
				if ($domain === "." || $domain === ".." || !is_dir($domain_dir))
					continue;
				$node_dirs = scandir( $domain_dir );
				foreach ($node_dirs as $node_file) {
					if ( ! preg_match( "/^(.+)\.json$/", $node_file, $matches ) )
						continue;
					$node = $matches[1];
					$node_config_path = $domain_dir . "/" . $node_file;
					$node_config_json = \CACTI_CLI\Utils\read_json( $node_config_path );
					
					$this->nodes[$tenant][$domain][$node] = array(
						'json' => $node_config_json, 'timestamp' => filectime($node_config_path)
					);
				}
			}
		}
	}
				
	public static function getInstance( ) {
		if (!self::$instance) self::$instance = new ViewInfo( );
		return self::$instance;
	}

	function get_nodes( $domain, $tenant = '_default' ) {
		return $this->nodes[$tenant][$domain];
	}

	function get_node_orders( $domain, $tenant = '_default', $order_by = 'timestamp' ) {
		$views = array_keys($this->nodes[$tenant][$domain]);
		if ( $order_by === 'timestamp') {
			$keys  = array();
			foreach ($this->nodes[$tenant][$domain] as $key => $arr) {
				$keys[] = $arr['timestamp'];
			}
			array_multisort($keys, SORT_ASC, SORT_NUMERIC, $views);

		} else {
			$keys  = array_keys($this->nodes[$tenant][$domain]);
			if ($order_by === 'natural') {
				array_multisort($keys, SORT_NATURAL, $views);

			} elseif ($order_by === 'natural-reverse') {
				array_multisort($keys, SORT_NATURAL, SORT_DESC, $views);

			} elseif ($order_by === 'normal') {
				array_multisort($keys, SORT_STRING, $views);

			} elseif ($order_by === 'normal-reverse') {
				array_multisort($keys, SORT_STRING, SORT_DESC, $views);

			}
		}
		return array_flip( $views );
	}

}

