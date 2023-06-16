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

class SiteInfo
{
  private static $instance;
  public $host_templates;
  public $graph_templates;
  public $graph_tree;

  private function __construct() {
    $this->host_templates = array_flip( getHostTemplates() );
    $this->graph_templates = array_flip( getGraphTemplates() );
    $this->graph_tree = $this->get_graph_tree( );
  }

  public static function getInstance() {
    if (!self::$instance) self::$instance = new SiteInfo;
    return self::$instance;
  }

  final function __clone() {
   throw new \Exception('Clone is not allowed against' . get_class($this)); 
  }

  private function get_graph_tree() {
    $tmpArray = db_fetch_assoc("select id, name from graph_tree order by id");
    $graph_tree[0] = "None";
    if (sizeof($tmpArray)) {
      foreach ($tmpArray as $template) {
        $graph_tree[$template["name"]] = $template["id"];
      }
    }
    return $graph_tree;    
  }

  public function find_graph_tree_id($title) {
    $tree_id = null;
    foreach ($graph_tree as $tree_key => $tree_val) {
      if (isset($title) && strcmp($title, "") != 0) {
        if(strpos($tree_key, $title) !== false) {
          $tree_id  = $tree_val;
          break;
        }
      }
      $tree_id  = $tree_val;
    }
    return($tree_id);
  }
}