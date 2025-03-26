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
use CACTI_CLI\Domain;
use CACTI_CLI\Node;
use CACTI_CLI\Metric;
use CACTI_CLI\ViewInfo;

const MAX_NODE     = 10000;
const MAX_METRIC   = 10000;
const MAX_PRIORITY = 100;

class NodeManager {

	public $options     = array();
	public $domains     = array();
	public $metric_keys = array();

	function __construct( $options = array() ) {
		$this->options = $options;
	}

	function reset_metric_pointer() {
		reset($this->metric_keys);
		return true;
	}

	function find_next_metric_set() {
// 		if ( $metric_key = each($this->metric_keys) ) {
// 			list($key, $set) = $metric_key;
// print_r($set);
// 			return $set;
// 		}
// 		return null;
		$set = current($this->metric_keys);
		next($this->metric_keys);
// print_r($set);
		return $set;
	}

	// 現在は名前順(ディレクトリのリスト順)のみだが、登録日付順、更新日付順にソートできる様に機能拡張
	// ノード以降のソートでソートオプションを選択できるようにする
	function generate_metric_keys( $prioritys = array()) {
		extract(get_object_vars($this));
 		$metric_keys = array();
		$tenant = (isset($options["tenant"])) ? $options["tenant"] : '_default';
		$view_info = ViewInfo::getInstance();
		if (!$view_info->nodes[$tenant]) {
			echo "ERROR: view config not found '/view/$tenant'\n";
			exit -1;
		}
		$domain_cnt = 1;
		$metric_cnt = 1;
		foreach ($this->domains as $domain_name => $domain ) {
			$domain_idx = $domain_cnt * MAX_NODE * MAX_METRIC;
			$node_orders = $view_info->get_node_orders($domain_name, $tenant, $options['view_sort']);
			foreach ($domain->nodes as $node_name => $node ) {
				if (!isset($node_orders[$node_name])) {
					continue;
				}
				$node_order = isset($node_orders[$node_name]) ? $node_orders[$node_name] : MAX_NODE;
				foreach ($node->metrics as $metric_name => $metric ) {
					$domain_metric = $domain_name . "/" . $metric->metric_name;
					$priority = array_key_exists($domain_metric, $prioritys) ? $prioritys[$domain_metric] : 99;
					$idx = $domain_idx + $node_order * MAX_METRIC + $priority * MAX_PRIORITY + $metric_cnt;
					$metric_keys[$idx] = array('domain' => $domain, 'node' => $node, 'metric' => $metric);
					$metric_cnt ++;
				}
			}
			$domain_cnt ++;
		}
		ksort($metric_keys);
		$this->metric_keys = $metric_keys;
		return true;
	}

	function retrieve( $path ) {
		extract(get_object_vars($this));
		$node_home = Config::getInstance()->node_home;

		fputs(STDERR, "Retrieve node '$path'.\n");
		if ( $path === '/' ) {
			$this->domains = $this->read_all_domains();
		} else if ( preg_match("/^\/(.+?)$/", $path, $matches ) ) {
			$node_paths = explode("/", $matches[1], 3 );
			$domain_info = null;
			switch ( count($node_paths) ) {
				case 1:
			    	list ($domain) = $node_paths;
					$domain_info = $this->retrieve_domain( $domain );
					break;
			    case 2:
			    	list ($domain, $node) = $node_paths;
					$domain_info = $this->retrieve_node( $domain, $node );
					break;
			    case 3:
			    	list ($domain, $node, $metric_path) = $node_paths;
					$domain_info = $this->retrieve_metric( $domain, $node, $metric_path );
					break;
			}
			if ($domain_info)
				$this->domains[$domain_info->domain_name] = $domain_info;
		}
		if (($node_count = count($this->domains)) > 0) {
			return true;
		} else {
			echo "ERROR : Invalid node path : $path\n";
			return false;
		}
	}

	function read_all_domains() {
		extract(get_object_vars($this));
		$node_home = Config::getInstance()->node_home;

		$domain_infos = array();
		if ( is_dir( $node_home ) ) {
			if ( $domains = scandir( $node_home ) ) {
				foreach ( $domains as $domain ) {
					if ($domain === "." || $domain === "..")
						continue;
					$domain_infos[$domain] = $this->retrieve_domain( $domain );
				}
			}
		}
		return $domain_infos;
	}

	function retrieve_domain( $domain ) {
		extract(get_object_vars($this));
		$node_home = Config::getInstance()->node_home;

		$domain_info = new Domain( $domain, $options );
		$domain_info->add_all_nodes();

		return $domain_info;
	}

	function retrieve_node( $domain, $node ) {
		extract(get_object_vars($this));
		$node_home = Config::getInstance()->node_home;

		$node_info = new Node( $domain, $node, $options );
		$node_info->read_node_info();
		$node_info->add_all_metrics();
		$domain_info = new Domain( $domain, $options );
		$domain_info->add_node( $node, $node_info );

		return $domain_info;
	}

	function retrieve_metric( $domain, $node, $metric ) {
		extract(get_object_vars($this));
		$node_home = Config::getInstance()->node_home;
    	$metric_info = new Metric( $domain, $node, $metric, $options ); 
		$metric_info->read_metric();

		$node_info   = new Node( $domain, $node, $options );
		$node_info->read_node_info();
		$node_info->add_metric( $metric, $metric_info );

		$domain_info = new Domain( $domain, $options );
		$domain_info->add_node( $node, $node_info );

		$this->metric_keys[][] = array($domain, $node, $metric);

		return $domain_info;
	}
}

