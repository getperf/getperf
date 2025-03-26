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

class CactiGraphTemplate {

	public $name;
	public $id;
	public $graph_options;
	public $data_sources;
	public $chart_style;
	public $color_scheme;
	public $color_style;
	public $graph_comment;
	public $graph_borderline;
	public $color_list;
	public $graph_item_count;
	public $vertical_label;
	public $disable_auto_scale;
	public $rigid_auto_scale;
	public $cdef_id;

	function __construct($name, $graph_options, $data_sources, $options) {
		$this->name = $name;
		$this->graph_options = $graph_options;
		$this->data_sources  = $data_sources;
	 	$site_home = \CACTI_CLI\Utils\get_site_home();
		$this->force            = array_key_exists('force', $options)       ?  $options['force']  : false;
		$this->chart_style      = array_key_exists('chart_style', $options) ?  $options['chart_style']  : 'line1';
		$this->graph_comment    = array_key_exists('graph_comment', $graph_options) ? $graph_options['graph_comment'] : NULL;
		$this->graph_borderline = array_key_exists('graph_borderline', $graph_options) ? $graph_options['graph_borderline'] : NULL;
		$this->vertical_label   = array_key_exists('vertical_label',   $graph_options) ? $graph_options['vertical_label'] : NULL;
		$this->upper_limit      = array_key_exists('upper_limit',      $graph_options) ?  $graph_options['upper_limit']  : NULL;
		$this->unit_exponent_value = array_key_exists('unit_exponent_value', $graph_options) ?  $graph_options['unit_exponent_value']  : NULL;
		$this->base_value       = array_key_exists('base_value',       $graph_options) ?  $graph_options['base_value']  : NULL;
		$this->legend_type      = array_key_exists('legend_type',      $graph_options) ?  $graph_options['legend_type']  : 'show_all';
		$this->graph_item_cols  = array_key_exists('graph_item_cols',  $graph_options) ?  $graph_options['graph_item_cols']  : NULL;
		$this->graph_item_texts = array_key_exists('graph_item_texts', $graph_options) ?  $graph_options['graph_item_texts']  : NULL;
		$this->total_data_source = array_key_exists('total_data_source', $graph_options) ?  $graph_options['total_data_source']  : NULL;
		$this->disable_auto_scale = array_key_exists('disable_auto_scale', $graph_options) ?  $graph_options['disable_auto_scale']  : false;
		$this->rigid_auto_scale = array_key_exists('rigid_auto_scale', $graph_options) ?  $graph_options['rigid_auto_scale']  : false;

		$this->color_style      = 'gradation';
		if (!is_null($options['color_style'])) {
			$this->color_style  = $options['color_style'];
		} elseif (array_key_exists('color_style', $graph_options)) {
			$this->color_style  = $graph_options['color_style'];
		}

		$this->color_scheme     = $site_home . '/lib/graph/color/default.json';
		if (!is_null($options['color_scheme'])) {
			$this->color_scheme = $options['color_scheme'];
		} elseif (array_key_exists('color_scheme', $graph_options)) {
			$color_scheme = $graph_options['color_scheme'];
			$this->color_scheme = $site_home . '/lib/graph/color/' . $color_scheme . '.json';
		}

		$cdef_id = NULL;
		if (array_key_exists('cdef', $graph_options)) {
			$cdef    = $graph_options['cdef'];
			$cdef_id = db_fetch_cell("select id from cdef where name = '$cdef'");
			if (!$cdef_id) {
				echo "ERROR: Not Found: $cdef\n";
			}
		}
		$this->cdef_id = $cdef_id;

		if ($this->graph_item_texts !== NULL && sizeof($this->graph_item_texts) !== sizeof($data_sources)) {
			$graph_items_str      = join(",", $data_sources);
			$graph_item_texts_str = join(",", $this->graph_item_texts);
			echo "ERROR: The number of the legend does not match\n" ,
				 "graph_items:$graph_items_str, \ngraph_item_texts: $graph_item_texts_str\n";
			exit;
		}
		$this->graph_item_count = 0;
		$this->get_color_schema($this->color_scheme);
		$this->graph_templates_item = array();
	}

	function get_color_schema($color_scheme) {
		if (!file_exists($color_scheme)) {
			echo "ERROR: Not Found: $color_scheme\n";
			exit;
		}
		$color_list = json_decode(file_get_contents($color_scheme), true);
		if (!$color_list) {
			echo "ERROR: JSON decode error : $rrd_config\n";
			exit;
		}
		if ($this->color_style === 'random') {
			shuffle($color_list);
		}
		$this->color_list = $color_list;
	}

	function get_color_id($type = NULL) {
		if ($type === 'total_line') {
			return 1;
		}
		$seq          = $this->graph_item_count;
		$color_list   = $this->color_list;
		$color_list_n = sizeof($color_list);
		$this->graph_item_count ++;
		return $color_list[$seq % $color_list_n]['id'];
	}

	function get_graph_type_id($type = NULL) {
		$chart_style = $this->chart_style;
		$graph_types = array(
			'comment' => 1, 
			'hrule'   => 2, 
			'vrule'   => 3, 
			'line1'   => 4, 
			'line2'   => 5, 
			'line3'   => 6
		);
		if ($type === 'total_line') {
			return 4; # 'line1'
		} else if ($chart_style === 'stack') {
			return ($this->graph_item_count === 1) ? 7 : 8; // AREA : STACK
		} else if (array_key_exists($chart_style, $graph_types)) {
			return $graph_types[$chart_style];
		} else {
			echo "ERROR: invalid chart style\n";
			exit;
		}
	}

	function get_cdef_id($type = NULL) {
		if ($type === 'total_line') {
			$total_data_source = $this->total_data_source;
			$cdef_id = db_fetch_cell("select id from cdef where name = '$total_data_source'");
			if (empty ($cdef_id)) {
				echo "ERROR: invaild cdef name (total_data_source): $total_data_source\n";
				exit;
			}
			return $cdef_id;
		}
		return 0;
	}

	function make_all_graph_items($ds_name, $type = NULL) {
		$items = array(
				0 => array(
					"color_id"                  => $this->get_color_id($type),
					"graph_type_id"             => $this->get_graph_type_id($type),
					"consolidation_function_id" => "1",
					"cdef_id"                   => $this->get_cdef_id($type),
					"text_format"               => $ds_name,
					"hard_return"               => ""
					),
				1 => array(
					"color_id"                  => "0",
					"graph_type_id"             => "9",
					"consolidation_function_id" => "4",
					"cdef_id"                   => $this->get_cdef_id($type),
					"text_format"               => "Current:",
					"hard_return"               => ""
					),
				2 => array(
					"color_id"                  => "0",
					"graph_type_id"             => "9",
					"consolidation_function_id" => "1",
					"cdef_id"                   => $this->get_cdef_id($type),
					"text_format"               => "Average:",
					"hard_return"               => ""
					),
				3 => array(
					"color_id"                  => "0",
					"graph_type_id"             => "9",
					"consolidation_function_id" => "3",
					"cdef_id"                   => $this->get_cdef_id($type),
					"text_format"               => "Maximum:",
					"hard_return"               => "on"
					));
		return $items;		
	}

	function make_simple_graph_items($ds_name, $legend_function, $hard_return, $type = NULL) {
		$items = array(
				0 => array(
					"color_id"                  => $this->get_color_id($type),
					"graph_type_id"             => $this->get_graph_type_id($type),
					"consolidation_function_id" => "1",
					"cdef_id"                   => $this->get_cdef_id($type),
					"text_format"               => $ds_name,
					"hard_return"               => ""
					),
				1 => array(
					"color_id"                  => "0",
					"graph_type_id"             => "9",
					"consolidation_function_id" => "1",
					"cdef_id"                   => $this->get_cdef_id($type),
					"text_format"               => ":",
					"hard_return"               => $hard_return
					));

		if ($legend_function === 'show_current') {
			$items[1]["consolidation_function_id"] = "4";
			$items[1]["text_format"]               = ":";

		} elseif ($legend_function == 'maximum') {
			$items[1]["consolidation_function_id"] = "3";
			$items[1]["text_format"]               = ":";
		}

		return $items;		
	}

	function make_minimum_graph_items($ds_name, $hard_return, $type = NULL) {
		$items = array(
				0 => array(
					"color_id"                  => $this->get_color_id($type),
					"graph_type_id"             => $this->get_graph_type_id($type),
					"consolidation_function_id" => "1",
					"cdef_id"                   => $this->get_cdef_id($type),
					"text_format"               => $ds_name,
					"hard_return"               => $hard_return
					));
		return $items;		
	}

	function check_or_create_graph_data_source($graph_template_id, $graph_template_item_id, $ds_name, $graph_template_item_seq, $legend_type, $hard_return) {
		$items = array();
		if ($legend_type === 'show_all') {
			$items = $this->make_all_graph_items($ds_name);	

		} else if ($legend_type === 'show_average') {
			$items = $this->make_simple_graph_items($ds_name, 'show_average', $hard_return);	

		} else if ($legend_type === 'show_current') {
			$items = $this->make_simple_graph_items($ds_name, 'show_current', $hard_return);	

		} else if ($legend_type === 'show_maximum') {
			$items = $this->make_simple_graph_items($ds_name, 'show_maximum', $hard_return);	

		} else if ($legend_type === 'minimum') {
			$items = $this->make_minimum_graph_items($ds_name, $hard_return);	

		}
		if ($this->cdef_id) {
			foreach ($items as $key => $value) {
				$items[$key]["cdef_id"] = $this->cdef_id;
			}
		}
		$this->check_or_create_graph_items($graph_template_id, $items, $graph_template_item_id, $ds_name, $graph_template_item_seq);
	}

	function check_or_create_graph_total_data_source($graph_template_id, $graph_template_item_seq, $legend_type, $hard_return) {
		$ds_name = 'Total';
		$items   = array();
		if ($legend_type === 'show_all') {
			$items = $this->make_all_graph_items($ds_name, 'total_line');	

		} else if ($legend_type === 'show_average') {
			$items = $this->make_simple_graph_items($ds_name, 'show_average', $hard_return, 'total_line');	

		} else if ($legend_type === 'show_current') {
			$items = $this->make_simple_graph_items($ds_name, 'show_current', $hard_return, 'total_line');	

		} else if ($legend_type === 'show_maximum') {
			$items = $this->make_simple_graph_items($ds_name, 'show_maximum', $hard_return, 'total_line');	

		} else if ($legend_type === 'minimum') {
			$items = $this->make_minimum_graph_items($ds_name, $hard_return, 'total_line');	

		}
		$this->check_or_create_graph_items($graph_template_id, $items, 0, $ds_name, $graph_template_item_seq);
	}

	function check_or_create_graph_comment($graph_template_id, $ds_name = 'comment') {

		$items = array(
			0 => array(
				"color_id"                  => "0",
				"graph_type_id"             => "1",	// COMMENT
				"consolidation_function_id" => "1",
				"text_format"               => $ds_name,
				"hard_return"               => "on"
				));

		$this->check_or_create_graph_items($graph_template_id, $items, NULL, 'comment', NULL, 'text_format');
	}

	function check_or_create_graph_threshhold($graph_template_id, $ds_name = 'threshold') {

		$items = array(
			0 => array(
				"color_id"                  => "9", // background-color: #FF0000;
				"graph_type_id"             => "2",	// HRULE
				"consolidation_function_id" => "1",
				"text_format"               => $ds_name,
				"hard_return"               => "on"
				));

		$this->check_or_create_graph_items($graph_template_id, $items, NULL, 'threshold', NULL, 'value');
	}

	function get_instance_of_graph_templates_item($graph_template_id) {
		if (empty($this->graph_templates_item[$graph_template_id])) {
			$sql = "SELECT id,task_item_id,text_format FROM graph_templates_item WHERE local_graph_id = 0 AND graph_template_id=$graph_template_id";
			$this->graph_templates_item[$graph_template_id] = db_fetch_assoc($sql);
		}
		return $this->graph_templates_item[$graph_template_id];
	}

	function check_or_create_graph_items($graph_template_id, $items, $graph_template_item_id = NULL, $ds_name = 'comment', $graph_template_item_seq = NULL, $column_name = 'task_item_id') {

		$graph_template_item_ids = array();
		$graph_templates_items = $this->get_instance_of_graph_templates_item($graph_template_id);
		$is_exists = false;

		foreach ($items as $item) {
			$text_format = $item["text_format"];
			/* old item clean-up.  Don't delete anything if the item <-> task_item_id association remains the same. */
			if (!is_null($graph_template_item_id)) {
				db_execute("delete from graph_template_input_defs where graph_template_item_id=$graph_template_item_id");
			}

			$id = NULL;
			foreach ($graph_templates_items as $graph_template_item) {
				$is_exists = ($graph_template_item["text_format"] === $ds_name);
				if (!is_null($graph_template_item_id)) {
					if ($graph_template_item["task_item_id"] !== $graph_template_item_id) {
						$is_exists = FALSE;
					}
				}
				if ($is_exists) {
					$id = $graph_template_item["id"];
					break;
				}
			}
			if ($id) {
				$graph_template_item_ids[] = $id;
				continue;
			}
			/* generate a new sequence if needed */
			$sequence = get_sequence(null, "sequence", "graph_templates_item", "graph_template_id=" . $graph_template_id . " and local_graph_id=0");

			$save["id"]                           = 0;
			$save["local_graph_id"]               = 0;
			$save["graph_template_id"]            = $graph_template_id;
			$save["local_graph_template_item_id"] = $graph_template_item_id;
			$save["task_item_id"]                 = $graph_template_item_id;
			$save["color_id"]                     = $item["color_id"];
			$save["graph_type_id"]                = $item["graph_type_id"];
			$save["consolidation_function_id"]    = $item["consolidation_function_id"];
			$save["text_format"]                  = $item["text_format"];
			$save["hard_return"]                  = $item["hard_return"];
			$save["gprint_id"]                    = 2;
			$save["sequence"]                     = $sequence;
			if (array_key_exists("cdef_id", $item)) {
				$save["cdef_id"] = $item["cdef_id"];
			}
			$graph_template_item_ids[] = sql_save($save, "graph_templates_item");
		}

		/* check or create graph_template_input of 'ds_name' */
		$input_text = "Data Source [ $ds_name ]";
		if (!is_null($graph_template_item_seq)) {
			$seq =  str_pad($graph_template_item_seq, 2, " ", STR_PAD_LEFT);
			// $input_text = "Data Source [ $seq / $ds_name ]";
			$input_text = "Data Source [ $seq / $ds_name ]";
		}
		$sql = "select id from graph_template_input where graph_template_id=$graph_template_id and name = \"$input_text\"";
		$graph_template_input_id = db_fetch_cell($sql, 'id');
		// $graph_template_input_id = db_fetch_cell_return($sql);
		if (!($graph_template_input_id)) {
			$hash = get_hash_graph_template(0, "graph_template_input");
			$sql = "replace into graph_template_input (hash,graph_template_id,name,column_name) " . 
				"values ('$hash', $graph_template_id, '$input_text', '$column_name')";
			db_execute($sql);
			$graph_template_input_id = db_fetch_insert_id();
		}

		/* Input for current data source exists and has changed.  Update the association */
		foreach ($graph_template_item_ids as $id) {
			db_execute("replace into graph_template_input_defs " .
				"(graph_template_input_id, graph_template_item_id) " .
				"values ($graph_template_input_id, $id)");

			/* make sure all current graphs using this graph input are aware of this change */
			if (!$this->force && !$is_exists) {
				push_out_graph_item($id);
				push_out_graph_input($graph_template_input_id, $id, array($graph_template_item_id => $id));
			}
		}
	}

	function check_or_create_graph_template_properties($graph_template_id) {
		extract(get_object_vars($this));
		$set_statements = array();
		if ($vertical_label) {
			$set_statements[] = "vertical_label = '$vertical_label'";
		}
		if ($upper_limit) {
			$set_statements[] = "upper_limit = $upper_limit";
		}
		if ($unit_exponent_value) {
			$set_statements[] = "unit_exponent_value = $unit_exponent_value";
		}
		if ($base_value) {
			$set_statements[] = "base_value = $base_value";
		}
		if ($disable_auto_scale) {
			$set_statements[] = "auto_scale = ''";
		}
		if ($rigid_auto_scale) {
			$set_statements[] = "auto_scale_rigid = 'on'";
		}
		if (count($set_statements) > 0) {
			$set_statement = join(',', $set_statements);
			$sql = "update graph_templates_graph set $set_statement where graph_template_id=$graph_template_id";
			db_execute($sql);
		}
	}

	function make_data_source_text($data_source_text) {
		if ($this->graph_item_texts) {
			return array_shift($this->graph_item_texts);
		} else {
			return $data_source_text;
		}
	}

	function generate() {
		extract(get_object_vars($this));

		$graph_template_source_id = CactiModelTemplate::fetch_id_by_name('graph_templates', '__root__');
		if (empty($graph_template_source_id)) {
			echo "Error: Base of graph template '__root__' not found\n";
			exit;
		}
		echo "Check graph template : $name\n";
		$graph_template_id = CactiModelTemplate::fetch_id_by_name('graph_templates',  $name);
		if (empty($graph_template_id)) {
			api_duplicate_graph(0, $graph_template_source_id, $name);
			$graph_template_id = CactiModelTemplate::fetch_id_by_name('graph_templates', $name);
			echo "Create graph template[$graph_template_id] : $name\n";
		}

		$graph_items = array();
		$seq = 1;
		if ($graph_comment) {
			$this->check_or_create_graph_comment($graph_template_id);
		}
		if ($graph_borderline) {
			$this->check_or_create_graph_threshhold($graph_template_id);
		}
		$this->check_or_create_graph_template_properties($graph_template_id);
		foreach ($data_sources as $data_source) {
			$hard_return = ($data_source === end($data_sources)) ? "on" : "";
			if ($graph_item_cols && $seq % $graph_item_cols === 0) {
				$hard_return = "on";
			}
			$data_source_text = $this->make_data_source_text($data_source['data_source']);
			$this->check_or_create_graph_data_source($graph_template_id, $data_source['rrd_id'], $data_source_text, 
				                                     $seq, $legend_type, $hard_return);
			$seq ++;
		}
		if ($total_data_source) {
			$this->check_or_create_graph_total_data_source($graph_template_id, $seq, $legend_type, $hard_return);
			$seq ++;
		}
		return $graph_template_id;

	} 
}

