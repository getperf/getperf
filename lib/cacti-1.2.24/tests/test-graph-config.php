<?php

use CACTI_CLI\Config;
use CACTI_CLI\GraphConfig;
use CACTI_CLI\GraphConfigManager;

class GraphConfigTests extends PHPUnit_Framework_TestCase {

	public $site_home;

	function setup() {
		$site_home = dirname( __DIR__ ) . '/t/cacti_cli';
		Config::getInstance()->switchSiteHome($site_home);
	}

	private function checkGraphSetIostat($graph_set) {
		extract($graph_set);
		$this->assertEquals( $graph_template, "HW - Disk Busy% - <devn> cols" );
		$this->assertEquals( $graph_tree, "/HW/<node_path>/DiskIO/" );
		$this->assertEquals( $graph_title, "HW - <node> - Disk Busy%" );
		$this->assertEquals( $datasource_title, "HW - <node> - Disk Busy% - <device>" );
	}

	private function checkGraphConfigIostat($graph_config) {
		$this->assertEquals( $graph_config->host_template, "Linux" );
		$this->assertEquals( $graph_config->host_title, "HW - <node>" );
		$graph_sets = $graph_config->graphs;
		$this->assertTrue( count($graph_sets) > 0);
		$graph_set = $graph_sets[0];
		$this->checkGraphSetIostat($graph_set);
	}

	function testGraphConfig() {
		$graph_config_home = Config::getInstance()->graph_config_home;
		$graph_config_file = "Linux/iostat.json";

		$graph_config_path = "$graph_config_home/$graph_config_file";
		$graph_config_json = \CACTI_CLI\Utils\read_json( $graph_config_path );
		$graph_config = new GraphConfig( $graph_config_json );
		$this->checkGraphConfigIostat($graph_config);
	}

	function testGraphConfigManagerFindMetric() {
		$graph_config_home = Config::getInstance()->graph_config_home;

		$config = new GraphConfigManager($graph_config_home);
		$this->assertTrue( $config->read_metric_graph_config('Linux', 'iostat') );
		$graph_config = $config->get("Linux", "iostat");
		$this->assertNotEquals( $graph_config, false );
		$this->checkGraphConfigIostat($graph_config);
		$graph_config = $config->get("Linux", "vmstat");
		$this->assertEquals( $graph_config, false );
	}

	function testGraphConfigManagerFindDomain() {
		$graph_config_home = Config::getInstance()->graph_config_home;

		$config = new GraphConfigManager($graph_config_home);
		$this->assertTrue( $config->read_domain_graph_config('Linux') );
		$graph_config = $config->get("Linux", "iostat");
		$this->assertNotEquals( $graph_config, false );
		$this->checkGraphConfigIostat($graph_config);
		$graph_config = $config->get("Linux", "vmstat");
		$this->assertNotEquals( $graph_config, false );
	}

	function testGraphConfigManagerFindAll() {
		$graph_config_home = Config::getInstance()->graph_config_home;
		$config = new GraphConfigManager($graph_config_home);
		$this->assertTrue( $config->read_all_graph_config() );
		$this->assertNotEquals( $config->get("Linux", "iostat"), false );
		$this->assertNotEquals( $config->get("Linux", "vmstat"), false );
	}

	function testGraphConfigManagerPrioritys() {
		$graph_config_home = Config::getInstance()->graph_config_home;

		$config = new GraphConfigManager($graph_config_home);
		$config->read_all_graph_config();
		$prioritys = $config->get_prioritys();
		$this->assertTrue( 0 < count($prioritys) );
	}
}

