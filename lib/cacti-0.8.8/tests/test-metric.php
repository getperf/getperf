<?php

use CACTI_CLI\Config;
use CACTI_CLI\Domain;
use CACTI_CLI\Node;
use CACTI_CLI\Metric;

class MetricTests extends PHPUnit_Framework_TestCase {

	function setup() {
		$site_home = dirname( __DIR__ ) . '/t/cacti_cli';
		Config::getInstance()->switchSiteHome($site_home);
	}

	function testMetric() {
		$node_home = Config::getInstance()->node_home;
		$metric = new Metric( 'Linux', 'ostrich', 'vmstat.json');

		$this->assertTrue( $metric->read_metric() );
		$this->assertEquals( $metric->rrdpath, "Linux/ostrich/vmstat.rrd" );
		$this->assertTrue( count($metric->devices) === 0 );
	}

	function testMetricDevice() {
		$node_home = Config::getInstance()->node_home;
		$metric = new Metric( 'Linux', 'ostrich', 'device/diskutil.json');

		$this->assertTrue( $metric->read_metric() );
		$this->assertEquals( $metric->rrdpath, "Linux/ostrich/device/diskutil__*.rrd" );
		$this->assertTrue( count($metric->devices) > 0 );
	}

	function testNode() {
		$node_home = Config::getInstance()->node_home;
		$node = new Node( 'Linux', 'ostrich');

		$this->assertTrue( $node->read_node_info() );
		$this->assertEquals( $node->infos["model"], "Intel(R) Celeron(R) CPU  J1900  @ 1.99GHz");
		$this->assertEquals( $node->node_path, null);
	}

	function testDomain() {
		$node_home = Config::getInstance()->node_home;
		$domain = new Domain( 'Linux' );

		$this->assertTrue( $domain->check_domain_exists() );
	}

	function testNodeAddAllMetrics() {
		$node_home = Config::getInstance()->node_home;
		$node = new Node( 'Linux', 'ostrich');

		$this->assertTrue( $node->add_all_metrics() );
		$this->assertTrue( count($node->metrics) > 0 );

	}

	function testDomainAddAllNodes() {
		$node_home = Config::getInstance()->node_home;
		$domain = new Domain( 'Linux');

		$this->assertTrue( $domain->add_all_nodes() );
		$this->assertTrue( count($domain->nodes) > 0 );

		$this->assertEquals( $domain->find_first_metric(), "Linux/ostrich/memfree.json");


	}
}

