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
use CACTI_CLI\CactiGraphTemplate;

class CactiModelTemplate {

	public $domain;
	public $metric;

	public $graph_configs;
	public $host_template_id;

	function __construct($domain, $metric) {

		$graph_configs = new GraphConfigManager();
		$graph_configs->read_metric_graph_config( $domain, $metric );

		$this->domain        = $domain;
		$this->metric        = $metric;
		$this->graph_configs = $graph_configs->graph_configs["$domain/$metric"];
	}

	static function fetch_id_by_name($table, $name, $column = 'name') {
		$sql = "select id from $table where $column='$name'";
		$id = db_fetch_cell($sql, 'id');
		return $id;
	}

	/* Get host_template id. If not found, create new entry: host_template */
	function check_or_create_host_template($host_template_title) {

		$host_template_id = $this->fetch_id_by_name('host_template', $host_template_title);
		if (empty($host_template_id)) {
			echo "Create Host template '$host_template_title'\n";
			$save["id"] = 0;
			$save["hash"] = get_hash_host_template(0);
			$save["name"] = $host_template_title;
			$host_template_id = sql_save($save, "host_template");
		}
		return $host_template_id;
	}

	/* Get host_template id. If not found, create new entry: host_template */
	function check_or_create_data_template($data_template_title, $data_sources) {
		$data_template_source_id = $this->fetch_id_by_name('data_template', '__root__');
		if (empty($data_template_source_id)) {
			echo "Error: Base of data template '__root__' not found\n";
			exit;
		}
		$data_template_id = $this->fetch_id_by_name('data_template',  $data_template_title);
		if (empty($data_template_id)) {
			duplicate_data_source(0, $data_template_source_id, $data_template_title);
			$data_template_id = $this->fetch_id_by_name('data_template', $data_template_title);
			echo "Create data template[$data_template_id] : $data_template_title\n";
		}

		$data_template_rrds = array();
		foreach ($data_sources as $data_source) {
			$sql = "select id from data_template_rrd where data_template_id=$data_template_id and local_data_id = 0 and data_source_name='$data_source'";
			$rrd_id = db_fetch_cell($sql, 'id');
			if (empty($rrd_id)) {
				$hash = get_hash_data_template(0, "data_template_item");
				$sql = "insert into data_template_rrd (hash,data_template_id,rrd_maximum,rrd_minimum,rrd_heartbeat,data_source_type_id,
					data_source_name) values ('$hash'," . $data_template_id . ",100,0,600,1,'" . $data_source . "')";
				db_execute($sql);
				$rrd_id = db_fetch_insert_id();
				echo "Create data template rrd [$rrd_id] : $data_source\n";
			}
			$data_template_rrds[] = compact('rrd_id', 'data_source');
		}
		return ($data_template_rrds);
	}

	function delete_data_template($title) {
		$data_template_ids = db_fetch_assoc("SELECT id FROM data_template WHERE name = '$title' OR name like '$title/%'");

		if (sizeof($data_template_ids) > 0) {
			$ids = array_map(function($r){return $r['id'];}, $data_template_ids);

			$data_template_datas = db_fetch_assoc("select id from data_template_data where " . array_to_sql_or($ids, "data_template_id") . " and local_data_id=0");

			if (sizeof($data_template_datas) > 0) {
				foreach ($data_template_datas as $data_template_data) {
					db_execute("delete from data_template_data_rra where data_template_data_id=" . $data_template_data["id"]);
				}
			}
			db_execute("delete from data_template_data where " . array_to_sql_or($ids, "data_template_id") . " and local_data_id=0");
			db_execute("delete from data_template_rrd where " . array_to_sql_or($ids, "data_template_id") . " and local_data_id=0");
			db_execute("delete from snmp_query_graph_rrd where " . array_to_sql_or($ids, "data_template_id"));
			db_execute("delete from snmp_query_graph_rrd_sv where " . array_to_sql_or($ids, "data_template_id"));
			db_execute("delete from data_template where " . array_to_sql_or($ids, "id"));

			/* "undo" any graph that is currently using this template */
			db_execute("update data_template_data set local_data_template_data_id=0,data_template_id=0 where " . array_to_sql_or($ids, "data_template_id"));
			db_execute("update data_template_rrd set local_data_template_rrd_id=0,data_template_id=0 where " . array_to_sql_or($ids, "data_template_id"));
			db_execute("update data_local set data_template_id=0 where " . array_to_sql_or($ids, "data_template_id"));
		}
	}

	function delete_graph_template($title) {
		$title = str_replace("<devn>", "%", $title, $count);
		$conditions = ($count > 0) ? "name like '$title'" : "name = '$title'";
		$graph_template_ids = db_fetch_assoc("SELECT id FROM graph_templates WHERE $conditions");

		if (sizeof($graph_template_ids) > 0) {
			$ids = array_map(function($r){return $r['id'];}, $graph_template_ids);

			db_execute("delete from graph_templates where " . array_to_sql_or($ids, "id"));

			$graph_template_input = db_fetch_assoc("select id from graph_template_input where " . array_to_sql_or($ids, "graph_template_id"));

			if (sizeof($graph_template_input) > 0) {
			foreach ($graph_template_input as $item) {
				db_execute("delete from graph_template_input_defs where graph_template_input_id=" . $item["id"]);
			}
			}

			db_execute("delete from graph_template_input where " . array_to_sql_or($ids, "graph_template_id"));
			db_execute("delete from graph_templates_graph where " . array_to_sql_or($ids, "graph_template_id") . " and local_graph_id=0");
			db_execute("delete from graph_templates_item where " . array_to_sql_or($ids, "graph_template_id") . " and local_graph_id=0");
			db_execute("delete from host_template_graph where " . array_to_sql_or($ids, "graph_template_id"));

			/* "undo" any graph that is currently using this template */
			db_execute("update graph_templates_graph set local_graph_template_graph_id=0,graph_template_id=0 where " . array_to_sql_or($ids, "graph_template_id"));
			db_execute("update graph_templates_item set local_graph_template_item_id=0,graph_template_id=0 where " . array_to_sql_or($ids, "graph_template_id"));
			db_execute("update graph_local set graph_template_id=0 where " . array_to_sql_or($ids, "graph_template_id"));
		}
	}

	function delete_template($options) {
		extract(get_object_vars($this));
		$this->delete_data_template("$domain/$metric");

		$graphs = $graph_configs->graphs;
		foreach ($graphs as $graph) {
			$graph_template_title = $graph['graph_template'];
			$this->delete_graph_template($graph_template_title);
		}
	}

	function generate($options) {
		extract(get_object_vars($this));

		$host_template = $graph_configs->host_template;
		if (empty($host_template)) {
			echo "ERROR : Host template 'host_template' not found\n";
			exit;
		}
		$host_template_id = $this->check_or_create_host_template($host_template);
		if (empty($host_template_id)) {
			echo "ERROR : Host template '$host_template' create\n";
			exit;
		}

		$grep = $options['graph_template_name'];
		$graphs = $graph_configs->graphs;
		$graph_template_ids = array();
		foreach ($graphs as $graph) {
			if (!array_key_exists("graph_template", $graph)) {
				echo "ERROR : graph_template not found in graph rule file\n";
				exit;
			}
			$graph_template_title = $graph['graph_template'];
			if ($grep) {
				if (!preg_match("/$grep/i", $graph_template_title)) {
					continue;
				}
			}
			$data_template_name = "$domain/$metric";
			$graph_type         = "single";
			$chart_style        = "line1";
			$legend_max         = 1;
			$graph_items        = array();

			if (array_key_exists("graph_items", $graph)) {
				$graph_items = $graph["graph_items"];
			} else {
				echo "ERROR : 'graph_items' not found in $graph_template_title\n";
				exit;
			}
			if (array_key_exists("chart_style", $graph)) {
				$chart_style = $graph["chart_style"];
			}
			if (array_key_exists("graph_type", $graph) && $graph['graph_type'] === "multi") {
				if (array_key_exists("legend_max", $graph)) {
					$legend_max = $graph['legend_max'];
				} else {
					echo "ERROR : 'legend_max' not found in $graph_template_title\n";
					exit;
				}
				if (sizeof($graph_items) !== 1) {
					echo "ERROR : invalid 'graph_items' in $graph_template_title\n";
					echo "multi type graph must have 'one' item\n";
					exit;
				}
				$graph_type = "multi";
			}
			
			$options['chart_style'] = $chart_style;

			// $data_template_rrds = array();
			// if ($graph_type === "multi") {
			// 	foreach (range(1, $legend_max) as $suffix) {
			// 		$rrds = $this->check_or_create_data_template("$data_template_name/$suffix", $graph_items);
			// 		if (sizeof($rrds) === 1) {
			// 			$data_template_rrds[] = $rrds[0];
			// 		} else {
			// 			echo "ERROR : data source create error of $graph_template_title\n";
			// 			exit;
			// 		}
			// 	}
			// } else {
			// 	$data_template_rrds = $this->check_or_create_data_template($data_template_name, $graph_items);
			// }

			if ($graph_type === "multi") {
				$data_template_rrds = array();
				foreach (range(1, $legend_max) as $suffix) {
					$rrds = $this->check_or_create_data_template("$data_template_name/$suffix", $graph_items);
					if (sizeof($rrds) === 1) {
						$data_template_rrds[] = $rrds[0];
					} else {
						echo "ERROR : data source create error of $graph_template_title\n";
						exit;
					}

					$title = $graph_template_title;
					$title = str_replace("<devn>", $suffix, $title);
					$graph_template = new CactiGraphTemplate($title, $graph, $data_template_rrds, $options);
					$graph_template_id = $graph_template->generate();
					$graph_template_ids[] = $graph_template_id;
				}
			} else {
				$data_template_rrds = $this->check_or_create_data_template($data_template_name, $graph_items);
				$graph_template = new CactiGraphTemplate($graph_template_title, $graph, $data_template_rrds, $options);
				$graph_template_id = $graph_template->generate();
				$graph_template_ids[] = $graph_template_id;
			}
		}

		/* check, if graph template was already associated */
		foreach ($graph_template_ids as $graph_template_id) {
			db_execute("replace into host_template_graph (host_template_id,graph_template_id) values($host_template_id,$graph_template_id)");
		}
	}

}

