<?php

use CACTI_CLI\Config;
use CACTI_CLI\NodeManager;

class NodeManagerTests extends PHPUnit_Framework_TestCase {

	function setup() {
		$site_home = dirname( __DIR__ ) . '/t/cacti_cli';
		Config::getInstance()->switchSiteHome($site_home);
	}

	function testNodeManageMetric() {
		$node_home = Config::getInstance()->node_home;

		$node_conf = new NodeManager();
		$this->assertTrue( $node_conf->retrieve('/Linux/ostrich/vmstat.json') );

		$domains = $node_conf->domains;
		$metric = $domains["Linux"]->nodes["ostrich"]->metrics["vmstat.json"];
		$this->assertEquals( $metric->rrdpath, "Linux/ostrich/vmstat.rrd" );
		$this->assertEquals( count($domains["Linux"]->nodes["ostrich"]->metrics), 1 );
	}

	function testNodeManageNode() {
		$node_home = Config::getInstance()->node_home;

		$node_conf = new NodeManager();
		$this->assertTrue( $node_conf->retrieve('/Linux/ostrich') );

		$domains = $node_conf->domains;
		$metric = $domains["Linux"]->nodes["ostrich"]->metrics["vmstat.json"];
		$this->assertEquals( $metric->rrdpath, "Linux/ostrich/vmstat.rrd" );
		$this->assertEquals( count($domains["Linux"]->nodes["ostrich"]->metrics), 5 );
	}

	function testNodeManageDomainCount() {
		$node_home = Config::getInstance()->node_home;

		$node_conf = new NodeManager();
		$this->assertTrue( $node_conf->retrieve('/Linux') );

		$domains = $node_conf->domains;
		$metric = $domains["Linux"]->nodes["ostrich"]->metrics["vmstat.json"];

		$this->assertEquals( $metric->rrdpath, "Linux/ostrich/vmstat.rrd" );
		$this->assertEquals( count($domains["Linux"]->nodes["ostrich"]->metrics), 5 );
	}

	function testNodeManageDomainRrdpath() {
		$node_home = Config::getInstance()->node_home;

		$node_conf = new NodeManager();
		$this->assertTrue( $node_conf->retrieve('/Linux') );
		$node_conf->generate_metric_keys();
		$node_conf->reset_metric_pointer();

		$rrdpaths = array();
		$nodes = array('ostrich', 'panda');
		foreach ($nodes as $node) {
			$rrdpaths[] = 'Linux/' . $node . '/memfree.rrd';
			$rrdpaths[] = 'Linux/' . $node . '/vmstat.rrd';
			$rrdpaths[] = 'Linux/' . $node . '/device/diskutil__*.rrd';
			$rrdpaths[] = 'Linux/' . $node . '/device/iostat__*.rrd';
			$rrdpaths[] = 'Linux/' . $node . '/device/netDev__*.rrd';
		}

		foreach ($rrdpaths as $rrdpath) {
			$metric_set = $node_conf->find_next_metric_set();
			$this->assertEquals($metric_set["metric"]->rrdpath, $rrdpath);
		}
		$metric_set = $node_conf->find_next_metric_set();
		$this->assertEquals($metric_set, null);
	}
}

