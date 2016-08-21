<?php

use CACTI_CLI\Config;

class ConfigTests extends PHPUnit_Framework_TestCase {

	function setup() {
	}

	function testConfigInitialize() {
		$config = Config::getInstance();
		$this->assertTrue( $config->switchSiteHome('/tmp/') );
		$this->assertTrue( $config->switchSiteHome('/tmp/site1/') );
	}

	function testConfigGet() {
		$site_home = Config::getInstance()->site_home;
		$this->assertEquals( $site_home, "/tmp/site1" );
	}
}

