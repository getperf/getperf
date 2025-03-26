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
use CACTI_CLI\GraphConfig;

class GraphConfigManager {

	public $config_home;
	public $graph_configs = array();

	function __construct( $config_home = null ) {
		if ( !$config_home ) {
			$config_home = Config::getInstance()->graph_config_home;
		}

		$this->config_home = $config_home;
	}

	function retrieve( $path ) {
		$node_home = $this->config_home;

		if ( $path === '/' ) {
			return $this->read_all_graph_config();
		} else if ( preg_match("/^\/(.+?)$/", $path, $matches ) ) {
			$node_paths = explode("/", $matches[1], 3 );
			$domain_info = null;
			switch ( count($node_paths) ) {
				case 1:
			    	list ($domain) = $node_paths;
					return $this->read_domain_graph_config( $domain );
					break;
			    case 2:
			    	list ($domain, $node) = $node_paths;
					return $this->read_domain_graph_config( $domain );
					break;
			    case 3:
			    	list ($domain, $node, $metric_path) = $node_paths;
					$metric = $metric_path;
					$metric = preg_replace ( "/(.+?)\.json$/", "$1", $metric );
					$metric = preg_replace ( "/.+\/(.+?)$/", "$1", $metric );
					return $this->read_metric_graph_config( $domain, $metric );
					break;
			}
		}
		return false;
	}

	function get_prioritys() {
		$prioritys = array();
		foreach ($this->graph_configs as $domain_metric => $graph_config) {
			$prioritys[$domain_metric] = $graph_config->priority;
		}
		return $prioritys;
	}

	function read_all_graph_config() {
		$graph_config_domains = scandir( $this->config_home );

		foreach ($graph_config_domains as $domain) {
			if ($domain === "." || $domain === ".." || $domain === 'color')
				continue;
			if (! $this->read_domain_graph_config( $domain ) )
				return false;
		}
		return true;
	}

	function read_domain_graph_config( $domain ) {
		$graph_config_dir = $this->config_home . '/' . $domain;
		if (! is_dir($graph_config_dir) ) {
			echo "ERROR : Graph config directory not found : $graph_config_dir\n";
			exit -1;
		}
		$graph_config_files = scandir( $graph_config_dir );
		foreach ( $graph_config_files as $graph_config_file ) {
			if ( ! preg_match( "/^(.+)\.json$/", $graph_config_file, $matches ) )
				continue;
			$metric = $matches[1];
			if ( ! $this->read_metric_graph_config( $domain, $metric) )
				return false;
		}
		return true;
	}

	function read_metric_graph_config( $domain, $metric ) {
		$graph_config_dir = $this->config_home;
		$graph_config_file = "$domain/$metric.json";

		$graph_config_path = "$graph_config_dir/$graph_config_file";
		if ( ! $graph_config_json = \CACTI_CLI\Utils\read_json( $graph_config_path ) )
			return false;
		if (! $graph_config = new GraphConfig( $graph_config_json ) )
		 	return false;
		$this->graph_configs["$domain/$metric"] = $graph_config;
		return true;
	}

	function get( $domain_name, $metric_name ) {
		$domain_metric = $domain_name . "/" . $metric_name;
		if ( array_key_exists($domain_metric , $this->graph_configs) ) {
			return 	$this->graph_configs[ $domain_metric ];
		} else {
			echo "Graph config key $domain_metric not found, Skip.\n";
			return false;
		}
	}
}

