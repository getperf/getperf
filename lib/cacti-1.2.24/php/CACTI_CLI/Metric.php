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

class Metric {

	public $domain_name;
	public $node_name;
	public $node_path;
	public $metric_path;
	public $metric_name;
	public $rrdpath;
	public $devices      = array();
	public $device_texts = array();
	public $options      = array();

	function __construct( $domain, $node, $metric ) {
		$this->domain_name = $domain;
		$this->node_name   = $node;
		$this->metric_path = $metric;

		$metric_name = $metric;
		$metric_name = preg_replace ( "/(.+?)\.json$/", "$1", $metric_name );
		$metric_name = preg_replace ( "/.+\/(.+?)$/", "$1", $metric_name );
		$this->metric_name = $metric_name;
	}

	function read_metric() {
		$node_home = Config::getInstance()->node_home;
		extract(get_object_vars($this));
		$paths = array( $node_home, $domain_name, $node_name, $metric_path );
		$metric_file = implode( "/", $paths );
		if ( $metric_info = \CACTI_CLI\Utils\read_json( $metric_file ) ) {
			extract( $metric_info );
			$this->rrdpath = (isset( $rrd )) ? $rrd : "";
			$this->node_path = (isset( $node_path )) ? $node_path : "";
			$this->devices   = (isset( $devices )) ? $devices : null;
			$this->device_texts = (isset( $device_texts )) ? $device_texts : null;
			return true;
		}
		return false;
	}

	function sort_device($method = 'none') {
		if ($method === 'none') {
			// do nothing

		} elseif ($method === 'natural') {
			array_multisort($this->devices, SORT_NATURAL, $this->device_texts);

		} elseif ($method === 'natural-reverse') {
			array_multisort($this->devices, SORT_NATURAL, SORT_DESC, $this->device_texts);

		} elseif ($method === 'normal') {
			array_multisort($this->devices, SORT_STRING, $this->device_texts);

		} elseif ($method === 'normal-reverse') {
			array_multisort($this->devices, SORT_STRING, SORT_DESC, $this->device_texts);

		} else {
			echo "ERROR : Unkown sort method : $method\n";
			exit -1;
		}
		return true;
	}
}

