<?php

use CACTI_CLI\Config;
use CACTI_CLI\ViewInfo;

class ViewInfoTests extends PHPUnit_Framework_TestCase {

	function setup() {
		$site_home = dirname( __DIR__ ) . '/t/cacti_cli';
		Config::getInstance()->switchSiteHome($site_home);
	}

	function testMissingPositional() {
		$view_home = Config::getInstance()->view_home;

		$view_info = ViewInfo::getInstance($view_home);
		$this->assertEquals( count($view_info->get_nodes('Datastore')), 2 );
		$this->assertEquals( count($view_info->get_nodes('Linux')),     2 );
	}

	function testGetNodeOrders() {
		$view_home = Config::getInstance()->view_home;

		$view_info = ViewInfo::getInstance($view_home);
		$node_orders = $view_info->get_node_orders('Datastore', '_default', 'timestamp');
		// var_dump($node_orders);
		$node_orders = $view_info->get_node_orders('Datastore', '_default', 'natural');
		// var_dump($node_orders);
		$this->assertEquals( count($node_orders), 2 );
	}

}

