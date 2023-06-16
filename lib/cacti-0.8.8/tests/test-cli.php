<?php

use CACTI_CLI\Config;

class Test_Cli extends PHPUnit_Framework_TestCase {

	function setUp() {
	}

	function test_string_length() {
		$arguments = new \cli\Arguments(compact('strict'));
		$this->assertEquals( 1, 1 );
	}
}

