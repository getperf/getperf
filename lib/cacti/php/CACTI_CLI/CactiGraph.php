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

const GRAPH_LEGEND_MAX = 10;

class CactiGraph {
	public $tenant;
	public $force_update;

	public $domain_name;
	public $node_path;
	public $node_name;
	public $node_alias;
	public $node_infos;
	public $graph_config;
	public $metric;

	public $cacti_tree_id;
	public $cacti_host_id;
	public $cacti_graph_id;
	public $cacti_datasource_ids;
	public $title;
	public $graph_title;
	public $graph_type;
	public $max_datasources;
	public $graph_tree;

	public $graph_template_id;
	public $cacti_graph_set;
	public $graph_host_config;
	public $device_set;
	public $graph_count;

	function __construct($cacti_graph_set, $graph_host_config, $graph_config, $metric, $metric_infos) {
		extract($metric_infos);
		$this->domain_name  = $domain_name;
		$this->node_path    = $node_path;
		$this->node_name    = $node_name;
		$this->node_alias   = $node_alias;
		$this->node_infos   = $node_infos;
		$this->graph_config = $graph_config;
		$this->metric       = $metric;

		$this->cacti_graph_set   = $cacti_graph_set;
		$this->graph_host_config = $graph_host_config;
		$this->tenant       = (isset($tenant)) ? $tenant : '_default';
		$this->force_update = (isset($force)) ? $force : false;
		$this->skip_tree    = (isset($skip_tree)) ? $skip_tree : false;

		$this->graph_type   = (array_key_exists('graph_type', $graph_config)) ? $graph_config['graph_type'] : 'single';
		$max_datasources = 1;
		if ( $this->graph_type === 'multi' ) {
			$max_datasources = ( array_key_exists("legend_max", $graph_config) ) ? $graph_config["legend_max"] : GRAPH_LEGEND_MAX;
		}
		$this->max_datasources = $max_datasources;

		if ($devices = $metric->devices) {
			$device_texts = ( $metric->device_texts ) ? $metric->device_texts : $devices;
			if (count($devices) !== count($device_texts)) {
				echo "Error: devices and device texts is unmatch.\n";
				echo "  devices:      " . implode(",", $devices) . "\n";
				echo "  device_texts: " . implode(",", $device_texts) . "\n";
				exit -1;
			}
			$metric->device_texts = $device_texts;
		}
		// Trim special character from title
		$filter_sql_string = function(&$item) {
		    $item = str_replace ( array("\\", "\"", "'"), "", $item );
		};
		array_walk($metric->device_texts, $filter_sql_string);
	}

	function make_graph($options = null) {
		extract(get_object_vars($this));

		if (! $this->regist_root_tree() )
			return false;
		if (! $this->regist_node() )
			return false;

		$graph_count = 1;
		if ($metric->devices) {
			$metric->sort_device($options['device_sort']);
			$devices = $metric->devices;
			$device_texts = $metric->device_texts;
			$device_set_index = 0;
			$row = 1;
			$device_sets = array();
			foreach ($devices as $device) {
				$device_text = array_shift($device_texts);
				if ($device_text === "") {
					$device_text = $device;
				}
				$device_sets[$device_set_index][] = compact('device', 'device_text');
				if ($row % $max_datasources == 0)
					$device_set_index ++;
				$row ++;
			}
			foreach ($device_sets as $device_set) {
				$this->graph_count = $graph_count;
				$this->device_set  = $device_set;
				if (! $this->regist_graphs() )
					return false;
				if (! $skip_tree ) {
					if (! $this->regist_tree() )
					 	return false;		
				}
				$graph_count ++;
			}
		} else {
			$this->graph_count = $graph_count;
			if (! $this->regist_graphs() )
				return false;
			if (! $skip_tree ) {
				if (! $this->regist_tree() )
					return false;
			}		
			return true;
		}

		return true;
	} 

	function regist_graphs() {
		extract(get_object_vars($this));
		$graph_template = $graph_config['graph_template'];
		if ($device_set) {
			if ( ($count_device_set = count($device_set)) > 0 ) {
				$graph_template = str_replace('<devn>', $count_device_set, $graph_template);
			}
		}
		$title = $graph_config['graph_title'];
		$title = str_replace('<node>',   $node_alias,          $title);
		$title = str_replace('<metric>', $metric->metric_name, $title);
		if ($tenant !== '_default') {
			$title = "$title - $tenant";
		}
		if ($graph_count >= 2) {
			$title .= " - " . $graph_count;
		} elseif ( count($device_set) === 1) {
			$title = str_replace('<device>', $device_set[0]["device_text"], $title);
		}
		$existsAlready = 0;
		$existsTree    = 0;
		if (array_key_exists($title, $cacti_graph_set->cacti_graph_ids )) {
			$existsAlready = $cacti_graph_set->cacti_graph_ids[$title];
		} else {
			$existsAlready = db_fetch_cell("select local_graph_id from graph_templates_graph where title ='$title'");
			if ($force_update) {
				$existsTree = $this->remove_graph($existsAlready, $skip_tree);

				$existsAlready = 0;
			}
		}
		if ($existsAlready > 0) {
			$this->cacti_graph_id = $existsAlready;
			return true;
		}

		$graph_templates = SiteInfo::getInstance()->graph_templates;
		if ( !array_key_exists($graph_template, $graph_templates) ) {
			echo "Error : '$graph_template' graph template not found in cacti database.\n";
			exit -1;
		}

		// $cmd = "add_graphs.php --graph-type=cg --force --graph-title=\"$title\" ";
		// $cmd .= "--host-id=$hostid --graph-template-id=$graph_template_id";
		$templateId = $graph_templates[$graph_template];
		$hostId     = $cacti_host_id;
		$empty = array(); /* Suggested Values are not been implemented */

		$returnArray = create_complete_graph_from_template($templateId, $hostId, "", $empty);
		if ( !array_key_exists("local_graph_id", $returnArray) ) {
			echo "Error : create graph from template '$graph_template'. template_id : $templateId, host_id : $hostId.\n";
			exit -1;
		}

		$graph_id = $returnArray["local_graph_id"];
		db_execute("UPDATE graph_templates_graph
			SET title=\"$title\" WHERE local_graph_id=$graph_id");
		update_graph_title_cache( $graph_id );
		$dataSourceIds = array();
		/* Add the ksort to fix the item is shifted problem , when the legend is more than 10 */
		ksort($returnArray["local_data_id"]);
		foreach($returnArray["local_data_id"] as $key => $item) {
			push_out_host($hostId, $item);
			$dataSourceIds[] = $item;
		}
		$this->cacti_datasource_ids = $dataSourceIds;

		// add graph comment
		if (array_key_exists('graph_comment', $graph_config)) {
			$graph_comment = $graph_config['graph_comment'];
			foreach ($node_infos as $node_info_key => $node_info_value) {
				$graph_comment = str_replace("<$node_info_key>", $node_info_value, $graph_comment);
			}
			if (preg_match_all("/<(.+?)>/", $graph_comment, $matches) > 0) {
	
				$matches_str = join(',', $matches[0]);
				echo "Warning : Remove the string that could not be replaced ; $matches_str.\n";
				$graph_comment = preg_replace("/<(.+?)>/", "", $graph_comment);
			}
			$sql  = "SELECT id from graph_templates_item WHERE ";
			$sql .= "local_graph_id = $graph_id AND ";
			$sql .= "task_item_id = 0 AND graph_type_id = 1";
			$graph_template_id = db_fetch_cell($sql);
			if (!isset($graph_template_id)) {
				echo "ERROR: Not found comment in graph template '$graph_template' (graph-id=$graph_id)\n";
				exit -1;
			}
			$sql  = "UPDATE graph_templates_item SET text_format='$graph_comment' ";
			$sql .= "WHERE  id = $graph_template_id";
			db_execute($sql);
		}

		// add graph borderline
		if (array_key_exists('graph_borderline', $graph_config)) {
			$borderline = $graph_config['graph_borderline'];
			foreach ($node_infos as $node_info_key => $node_info_value) {
				$borderline = str_replace("<$node_info_key>", $node_info_value, $borderline);
			}
			$sql  = "SELECT id from graph_templates_item WHERE ";
			$sql .= "local_graph_id = $graph_id AND graph_type_id = 2";
			$graph_template_id = db_fetch_cell($sql);
			if (!isset($graph_template_id)) {
				echo "ERROR: Not found borderline in graph template '$graph_template' (graph-id=$graph_id)\n";
				exit -1;
			}
			$sql  = "UPDATE graph_templates_item SET value=$borderline ";
			$sql .= "WHERE  id = $graph_template_id";
			db_execute($sql);
		}

		if ($graph_id > 0) {
			$this->cacti_graph_id = $graph_id;
			$cacti_graph_set->cacti_graph_ids[$title] = $graph_id;
		}
		if ($tenant !== '_default') {
			$graph_config['datasource_title'] .= ' - ' . $tenant;
		}

		$this->regist_datasources();
		if ($graph_type === 'multi') {
			if ( !$this->update_legend_text() )
				return false;
		}

		// update tree if force and skip tree.
		if ($force_update && $skip_tree) {
			if ($existsTree > 0 && $graph_id > 0) {
				$sql = "update graph_tree_items set local_graph_id=$graph_id where local_graph_id=$existsTree";
				db_execute($sql);
			}
		}

		return true;
	}
	function remove_graph($local_graph_id, $skip_tree = false) {
		$data_sources = array_rekey(db_fetch_assoc(
			"SELECT distinct data_template_data.local_data_id
				FROM (data_template_rrd, data_template_data, graph_templates_item)
				WHERE graph_templates_item.task_item_id=data_template_rrd.id
				AND data_template_rrd.local_data_id=data_template_data.local_data_id
				AND graph_templates_item.local_graph_id = $local_graph_id
				AND data_template_data.local_data_id > 0"
			), "local_data_id", "local_data_id");

		if (sizeof($data_sources)) {
			api_data_source_remove_multi($data_sources);
			api_plugin_hook_function('data_source_remove', $data_sources);
		}

		// It called directly instead of api_graph_remove() for skip_tree
		$existsTree = 0;
		db_execute("delete from graph_templates_graph where local_graph_id=$local_graph_id");
		db_execute("delete from graph_templates_item where local_graph_id=$local_graph_id");
		if ($skip_tree) {
			$existsTree = db_fetch_cell("select local_graph_id from graph_tree_items where local_graph_id=$local_graph_id");
		} else {
			db_execute("delete from graph_tree_items where local_graph_id=$local_graph_id");
		}
		db_execute("delete from graph_local where id=$local_graph_id");
		api_plugin_hook_function('graphs_remove', $local_graph_id);

		return $existsTree;
	}

	function regist_datasources() {
		extract(get_object_vars($this));
		$rrdpath = $metric->rrdpath;
		$datasource_title = $graph_config['datasource_title'];
		$datasource_title = str_replace("<node>", $this->node_name, $datasource_title);

		if (isset($device_set)) {
			foreach ($device_set as $device_list) {
				$id = array_shift($cacti_datasource_ids);
				$device      = $device_list['device'];
				$device_text = $device_list['device_text'];

				$rrdpath2          = str_replace("<device>", $device, $rrdpath);
				$rrdpath2          = str_replace("*",        $device, $rrdpath2);
				$datasource_title2 = str_replace("<device>", $device_text, $datasource_title);
				$datasource_title2 = str_replace("\\", "\\\\", $datasource_title2);
				$sql  = "UPDATE data_template_data SET ";
				$sql .= "name_cache='$datasource_title2', ";
				$sql .= "data_source_path='<path_rra>/$rrdpath2' ";
				$sql .= " WHERE    local_data_id=$id";
				db_execute($sql);
			}
		} else {
			$id = array_shift($cacti_datasource_ids);
			$sql  = "UPDATE data_template_data SET ";
			$sql .= "name_cache='$datasource_title', ";
			$sql .= "data_source_path='<path_rra>/$rrdpath' ";
			$sql .= " WHERE    local_data_id=$id";
			db_execute($sql);
		}
		return true;
	}

	function update_legend_text() {
		extract(get_object_vars($this));
		$sql  = "SELECT id ";
		$sql .= "FROM graph_templates_item ";
		$sql .= "WHERE local_graph_id = " . $cacti_graph_id . " ";
		$sql .= "AND graph_type_id in (4,5,6,7,8) ";
		$sql .= "AND task_item_id != 0 ";
		$sql .= "ORDER BY sequence ";

		$text_ids = db_fetch_assoc($sql);
		if (sizeof($text_ids) !== sizeof($device_set)) {
			echo "ERROR: Update graph legend text. Wrong size of legends\n";
			exit -1;
		}
		foreach ($device_set as $device_list) {
			$text_id = array_shift($text_ids);
			$id = $text_id['id'];
			$device_text = $device_list['device_text'];
			$sql  = "UPDATE graph_templates_item SET ";
			$sql .= "text_format='$device_text' ";
			$sql .= " WHERE id=$id";
			db_execute($sql);
		}
		return true;
	}

	function regist_tree() {
		extract(get_object_vars($this));
	
		$path = str_replace('<node>', $node_alias, $graph_config['graph_tree']);
		$path = str_replace('<domain>', $domain_name, $path);
		$path = str_replace('<node_path>', $node_path, $path);
 		if ( count($device_set) === 1) {
			$path = str_replace('<device>', $device_set[0]["device"], $path);
			$path = str_replace('<device_text>', $device_set[0]["device_text"], $path);
		}
		
		// // ツリーIDの検索。ツリーがない場合は新規作成
		$parent_id = $this->mkdir_graph_tree($path);

		# Blank out name, hostID, host_grouping_style
		$name           = '';
		$rra_id         = 0;
		$hostId         = 0;
		$hostGroupStyle = 1;
		// $nodeTypes   : 'header'=>1,'graph'=>2,'host'=>3
		$itemType       = 2;
		// $sortMethods : 'manual'=>1,'alpha'=>2,'natural'=>4,'numeric'=>3
		$sortMethod     = 1;

		# $nodeId could be a Header Node, a Graph Node, or a Host node.
		$nodeId = api_tree_item_save(0, $cacti_tree_id, $itemType, $parent_id, $name, $cacti_graph_id, $rra_id, $hostId, $hostGroupStyle, $sortMethod, false);
		return true;
	}

	function mkdir_graph_tree($tree_path) {
		extract(get_object_vars($this));

		$lvl	   = 0;
		$parent_id = 0;
		$cond	   = "";
		$tree      = "";

		// ツリーパスを分解し、順に検索する
		$tree_paths = explode('/', $tree_path);
		foreach ($tree_paths as $path) {
			if (strcmp($path, "") == 0) {
				continue;
			}
			$tree = $tree . '/' . $path;
			if (array_key_exists($tree, $cacti_graph_set->cacti_tree_ids)) {
				extract($cacti_graph_set->cacti_tree_ids[$tree]); 	// lvl, cond, parent_id
//				echo "[" . __LINE__ . "] [$lvl][$cond]($path) id : $parent_id\n";
				continue;
			}
			$sql  = "select * from graph_tree_items where graph_tree_id=$cacti_tree_id ";
			$sql .= "and order_key like '{$cond}___000%'";

			$tree_field = db_fetch_assoc($sql);
			$found = 0;
			if (sizeof($tree_field)) {
				foreach ($tree_field as $field) {
					if (strcmp($field["title"], $path) == 0) {
						$parent_id = $field["id"];
						$order_key = $field["order_key"];
						$found = 1;
						break;
					}
				}
			}
			// 検索結果が0の場合は、新規にパスを追加する
			if ($found == 0) {
				# Blank out the graphId, rra_id, hostID and host_grouping_style  fields
				$graphId        = 0;
				$rra_id         = 0;
				$hostId         = 0;
				$hostGroupStyle = 1;
				// $nodeTypes   : 'header'=>1,'graph'=>2,'host'=>3
				$itemType       = 1;
				// $sortMethods : 'manual'=>1,'alpha'=>2,'natural'=>4,'numeric'=>3
				$sortMethod     = 1;

				# $nodeId could be a Header Node, a Graph Node, or a Host node.
				$parent_id = api_tree_item_save(0, $cacti_tree_id, $itemType, $parent_id, $path, $graphId, $rra_id, $hostId, $hostGroupStyle, $sortMethod, false);

				$sql = "select order_key from graph_tree_items where id=$parent_id";
				$order_key = db_fetch_cell($sql, "order_key");
			}

			$cond .= substr($order_key, 3 * $lvl, 3);
			$lvl ++;

//			echo "[" . __LINE__ . "] [$lvl][$cond]($path) id : $parent_id\n";
			$cacti_graph_set->cacti_tree_ids[$tree] = compact('lvl', 'cond', 'parent_id');
		}
//		echo "[" . __LINE__ . "] [$lvl][$tree_path] id : $parent_id\n";
		return($parent_id);
	}

	function regist_root_tree() {
		extract(get_object_vars($this));

		$existsAlready = db_fetch_cell("select id from graph_tree where name = '$tenant'");
		if ($existsAlready) {
			$this->cacti_tree_id = $existsAlready;
			return true;
		}

		$treeOpts = array();
		$treeOpts["id"]   = 0; # Zero means create a new one rather than save over an existing one
		$treeOpts["name"] = $tenant;
		$treeOpts["sort_type"] = 1; # 'manual' => 1, 'alpha' => 2, 'natural' => 4, 'numeric' => 3
		$treeId = sql_save($treeOpts, "graph_tree");

		sort_tree(SORT_TYPE_TREE, $treeId, $treeOpts["sort_type"]);
		$this->cacti_tree_id = $treeId;
		echo "Tree Created - tree-id: ($treeId)\n";

		return ($treeId > 0) ? true : false;
	}

	function regist_node() {
		extract(get_object_vars($this));

		$host_template = $graph_host_config->host_template;
		$host_title = $graph_host_config->host_title;
		$host_title = str_replace('<node>',   $node_name,           $host_title);
		$host_title = str_replace('<metric>', $metric->metric_name, $host_title);

		$existsAlready = 0;
		if (array_key_exists($host_title, $cacti_graph_set->cacti_host_ids )) {
			$existsAlready = $cacti_graph_set->cacti_host_ids[$host_title];
		} else {
			$existsAlready = db_fetch_cell("select id from host where description ='$host_title'");
		}
		if ($existsAlready > 0) {
			$this->cacti_host_id = $existsAlready;
			return true;
		}
		$host_templates = SiteInfo::getInstance()->host_templates;
		if ( !array_key_exists($host_template, $host_templates) ) {
			echo "Error : '$host_template' host template not found in cacti database.\n";
			exit -1;
		}
		$template_id = $host_templates[$host_template];
		$description = $host_title;
		$ip          = $host_title;
		$hostname    = $host_title;
		$community   = 'getperf';
		$snmp_ver    = 2;

		$notes                = "";
		$disable              = "";
		$snmp_username        = "";
		$snmp_password        = "";
		$snmp_auth_protocol   = "";
		$snmp_priv_passphrase = "";
		$snmp_priv_protocol   = "";
		$snmp_context         = "";
		$snmp_port            = 161;
		$snmp_timeout         = 60;
		$avail                = 1;
		$ping_method          = PING_ICMP;
		$ping_port            = null;
		$ping_timeout         = 60;
		$ping_retries         = 10;
		$max_oids             = 10;
		$device_threads       = 1;
		$host_id = api_device_save(0, $template_id, $description, $ip,
					$community, $snmp_ver, $snmp_username, $snmp_password,
					$snmp_port, $snmp_timeout, $disable, $avail, $ping_method,
					$ping_port, $ping_timeout, $ping_retries, $notes,
					$snmp_auth_protocol, $snmp_priv_passphrase,
					$snmp_priv_protocol, $snmp_context, $max_oids, $device_threads);
		if ($host_id > 0) {
			$this->cacti_host_id = $host_id;
			$cacti_graph_set->cacti_host_ids[$host_title] = $host_id;
			echo "Host ($host_title) Created - host_id: ($host_id)\n";
			return true;
		}

		return false;
	}
}

