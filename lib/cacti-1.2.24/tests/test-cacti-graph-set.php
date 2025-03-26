<?php

use CACTI_CLI\Config;
use CACTI_CLI\NodeManager;
use CACTI_CLI\GraphConfigManager;
use CACTI_CLI\CactiGraphSet;

class CactiGraphSetTests extends PHPUnit_Framework_TestCase {

	public $site_home;
	public $node_configs;
	public $graph_configs;

	function setup() {
		$site_home = dirname( __DIR__ ) . '/t/cacti_cli';
		Config::getInstance()->switchSiteHome($site_home);

		$this->site_home     = $site_home;
		$this->node_configs  = new NodeManager("$site_home/node");
		$this->graph_configs = new GraphConfigManager("$site_home/lib/graph");
	}

	function retrieve($path) {
		extract(get_object_vars($this));
		$node_configs->retrieve( $path );
		$graph_configs->retrieve( $path );
	}

	function testNodeManageClusterDomain() {
		extract(get_object_vars($this));

		$this->retrieve('/Linux');
		$node_configs->generate_metric_keys();
		$node_configs->reset_metric_pointer();
		$metric_set = $node_configs->find_next_metric_set();
		extract($metric_set);
		$this->assertEquals($metric->metric_name, "memfree");

		$graph_config = $graph_configs->get('Linux', $metric->metric_name);
		$this->assertEquals($metric->metric_name, "memfree");
		$this->assertEquals($graph_config->host_template, "Linux");
	}

	function testGraphSetMemfree() {
		$cacti_graph_set = new CactiGraphSet($this->site_home);
		$cacti_graph_set->retrieve_configs('/Linux/testlnx01/memfree.json');
//		$this->assertTrue($cacti_graph_set->make_graphs());
		$cacti_graph_set->retrieve_configs('/Linux/testlnx01');
//		$this->assertTrue($cacti_graph_set->make_graphs());
		$cacti_graph_set->retrieve_configs('/Linux');
//		$this->assertTrue($cacti_graph_set->make_graphs());
	}

	function testNodeManageClusterDomainOrderByPriority() {
		extract(get_object_vars($this));

		$this->retrieve('/Linux');
		$prioritys = $graph_configs->get_prioritys();
		$node_configs->generate_metric_keys($prioritys);
		$node_configs->reset_metric_pointer();
		$metric_set = $node_configs->find_next_metric_set();
		extract($metric_set);
		$this->assertEquals($metric->metric_name, "vmstat");
		$metric_set = $node_configs->find_next_metric_set();
		extract($metric_set);
		$this->assertEquals($metric->metric_name, "memfree");
		$metric_set = $node_configs->find_next_metric_set();
		extract($metric_set);
		$this->assertEquals($metric->metric_name, "iostat");
	}
}

