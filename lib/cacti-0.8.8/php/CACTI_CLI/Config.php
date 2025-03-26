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

class Config
{
  private static $instance;
  public $site_name;
  public $site_home;
  public $cacti_home;
  public $node_home;
  public $view_home;
  public $graph_config_home;

  private function __construct() {
  }

  public function switchSiteHome($site_home) {

    $site_home = preg_replace ( "/^(.+?)\/$/", "$1", $site_home );
    $this->site_home           = $site_home;
    $this->cacti_home          = $site_home . '/html/cacti';
    $this->node_home           = $site_home . '/node';
    $this->view_home           = $site_home . '/view';
    $this->graph_config_home   = $site_home . '/lib/graph';
    $this->cacti_template_home = $site_home . '/lib/cacti/template';

    $paths = explode("/", $site_home);
    foreach ( array_reverse($paths) as $path ) {
      if ( strlen( $path ) > 0 ) {
        $this->site_name = $path;
        return true;
      }
    }
    return false;
  }

  public static function getInstance() {
    if (!self::$instance) self::$instance = new Config;
    return self::$instance;
  }

  final function __clone() {
   throw new \Exception('Clone is not allowed against' . get_class($this)); 
  }

}