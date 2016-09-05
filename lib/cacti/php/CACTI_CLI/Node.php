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

class Node {

	public $domain_name;
	public $node_name;
	public $node_path;
	public $options = array();
	public $infos   = array();
	public $metrics = array();

	function __construct( $domain, $node, $options ) {
		$this->domain_name = $domain;
		$this->node_name   = $node;
		$this->options     = $options;
	}

	function read_node_info() {
		$node_home = Config::getInstance()->node_home;

		extract(get_object_vars($this));
		$paths = array( $node_home, $domain_name, $node_name, "info" );
		$node_info_dir = implode( "/", $paths );

		$node_infos = array();
		if ( is_dir( $node_info_dir ) ) {
			if ( $node_info_files = scandir( $node_info_dir ) ) {
				foreach ( $node_info_files as $node_info_file ) {
					if ( preg_match( "/^(.+)\.json$/", $node_info_file, $matches ) ) {
						$node_info_name = $matches[1];
						$node_info_file = "$node_info_dir/$node_info_file";
						$node_info = \CACTI_CLI\Utils\read_json( $node_info_file );

						// ノード情報のnode_pathが、"/(...)/{node}" の場合は "/{node}" より前の文字列をnode_pathとして登録する
						if (isset( $node_info["node_path"] )) {
							$node_path = $node_info["node_path"];
							if ( preg_match("/^(.+)\/$node_name$/", $node_path, $matchs) == 1) {
								$this->node_path = $matchs[1];
							}
						}
						$node_infos = array_merge_recursive($node_infos, $node_info);
					}
				}
			}
		}
		if ($options["node_path_dir"]) {
			$this->node_path = $options["node_path_dir"];
		}
		$this->infos = $node_infos;
		return true;
	}

	function add_metric( $title, $metric ) {
		$this->metrics[$title] = $metric;
		return true;
	}

	function add_all_metrics() {
		$node_home = Config::getInstance()->node_home;
		extract(get_object_vars($this));
		foreach( array(null, "device") as $postfix) {
			$paths = array( $node_home, $domain_name, $node_name, $postfix );
			$metric_info_dir = implode( "/", $paths );
			if ( is_dir( $metric_info_dir ) ) {
				if ( $metric_info_files = scandir( $metric_info_dir ) ) {
					foreach ( $metric_info_files as $metric_info_file ) {
						if ( preg_match( "/^(.+\.json)$/", $metric_info_file, $matches ) ) {
							$metric_name = $matches[1];
							if ($postfix === "device") 
								$metric_name = "device/$metric_name";

							$metric = new Metric( $domain_name, $node_name, $metric_name );
							$metric->read_metric();
							$this->add_metric( $metric_name, $metric );
						}
					}
				}
			}
		}
		return true;		
	}

}

