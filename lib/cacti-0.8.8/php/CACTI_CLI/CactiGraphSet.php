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
use CACTI_CLI\NodeManager;
use CACTI_CLI\GraphConfigManager;
use CACTI_CLI\CactiGraph;

class CactiGraphSet {

	public $cacti_host_id;
	public $node_configs;
	public $graph_configs;

	public $options            = array();
	public $cacti_host_ids     = array();
	public $cacti_graph_ids    = array();
	public $cacti_tree_ids     = array();
	public $data_source_ids    = array();
	public $data_source_rrds   = array();
	public $data_source_titles = array();

	function __construct( $options = array() ) {
		$this->options       = $options;
		$this->node_configs  = new NodeManager($options);
		$this->graph_configs = new GraphConfigManager();
	}

	function retrieve_configs( $path ) {
		extract(get_object_vars($this));
	    $path = preg_replace ( "/^(.+?)\/$/", "$1", $path );
		$graph_configs->retrieve( $path );
		$node_configs->retrieve( $path );
		$prioritys = $graph_configs->get_prioritys();
		$node_configs->generate_metric_keys( $prioritys, $options );
	}

	function report_nodes( ) {
		extract(get_object_vars($this));
		$reports = array();
		$node_configs->reset_metric_pointer();
		while ($metric_set = $node_configs->find_next_metric_set()) {
			extract($metric_set);
			$domain_name = $domain->domain_name;
			$node_name   = $node->node_name;
			$metric_name = $metric->metric_name;
			$node_infos  = $node->infos;
			$reports[$domain_name][$node_name]['node_path'] = $node->node_path;
			foreach ($node_infos as $info_key => $info_value) {
				$reports[$domain_name][$node_name][$info_key] = $info_value;
			}	
		}
		$json = json_encode($reports);
		print $json . "\n";
		return true;
	}

	function make_graphs( ) {
		extract(get_object_vars($this));
		$metric_keyword = $options["grep"];
		extract(get_object_vars($this));
		$node_configs->reset_metric_pointer();
		while ($metric_set = $node_configs->find_next_metric_set()) {
			extract($metric_set);
			$domain_name = $domain->domain_name;
			$node_path   = $node->node_path;
			$node_name   = $node->node_name;
			$metric_name = $metric->metric_name;
			$node_infos  = $node->infos;
			$node_alias  = (array_key_exists('node_alias', $node_infos)) ?
						   $node_infos['node_alias'] : $node_name;
			if ( $metric_keyword !== NULL ) {
				if ( preg_match("/$metric_keyword/", $metric_name, $matchs) !== 1) {
					continue;
				}
			}

			// if ($node_infos && array_key_exists('node_path', $node_infos)) {
			// 	$node_path = $node_infos['node_path'];
			// }
			// $node_path = str_replace ( "/$node_name",  "", $node_path );
			// if ($node_path === $node_name) {
			// 	$node_path = "";
			// }

			$metric_infos = compact('domain_name', 'node_path', 'node_name', 'node_alias', 'metric_name', 'node_infos');
			$metric_infos = array_merge($metric_infos, $options);
			if ($graph_host_config = $graph_configs->get($domain_name, $metric_name)) {
				foreach ($graph_host_config->graphs as $graph_infos) {
					$graph_template = $graph_infos['graph_template'];
					echo "Generate Graph : $domain_name, $node_name, $graph_template\n";
					$graph = new CactiGraph($this, $graph_host_config, $graph_infos, $metric, $metric_infos);
					$is_ok = ($graph->make_graph( $options )) ? 'OK' : 'NG';
					echo "\t$is_ok\n";
				}
			}
		}
		return true;
	}
 
}

