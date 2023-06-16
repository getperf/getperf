<?php

define( 'CACTI_CLI_ROOT', dirname( __DIR__ ) );

require dirname( dirname( __FILE__ ) ) . '/php/common.php';
require_once getcwd() . '/vendor/autoload.php';

function cli_autoload( $className ) {
	$className = ltrim($className, '\\');
	$fileName  = '';
	$namespace = '';
	if ($lastNsPos = strrpos($className, '\\')) {
		$namespace = substr($className, 0, $lastNsPos);
		$className = substr($className, $lastNsPos + 1);
		$fileName  = str_replace('\\', DIRECTORY_SEPARATOR, $namespace) . DIRECTORY_SEPARATOR;
	}
	$fileName .= str_replace('_', DIRECTORY_SEPARATOR, $className) . '.php';

	if ( 'CACTI_CLI' !== substr( $fileName, 0, 9 ) ) {
		return;
	}

	require dirname( dirname( __FILE__ ) ) . '/php/' . $fileName;
}

spl_autoload_register( 'cli_autoload' );

// include_once CACTI_CLI_ROOT . "/t/cacti_cli/html/cacti/include/global.php";
// include_once($config["base_path"]."/lib/api_automation_tools.php");
// include_once($config["base_path"]."/lib/data_query.php");
// include_once($config["base_path"]."/lib/utility.php");
// include_once($config["base_path"]."/lib/sort.php");
// include_once($config["base_path"]."/lib/template.php");
// include_once($config["base_path"]."/lib/api_data_source.php");
// include_once($config["base_path"]."/lib/api_graph.php");
// include_once($config["base_path"]."/lib/snmp.php");
// include_once($config["base_path"]."/lib/data_query.php");
// include_once($config["base_path"]."/lib/api_device.php");
