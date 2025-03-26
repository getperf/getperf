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
use CACTI_CLI\NodeManager;
use CACTI_CLI\GraphConfigManager;
use CACTI_CLI\CactiGraph;

class CactiDomainTemplate {

	public $cacti_template_home;
	public $host_templates;

	function __construct() {
		$templates = getHostTemplates();
		$this->host_templates = array_flip($templates);
		$this->cacti_template_home = Config::getInstance()->cacti_template_home;
	}

	function mkdir_template_export_path( $domain_name ) {
		$cacti_version = db_fetch_cell('select * from version', 'cacti');

		$export_dir = $this->cacti_template_home . "/${cacti_version}";
		if (file_exists($export_dir)) {
			if  ( !is_dir($export_dir) ) {
				echo "Error: '$export_dir' is not a directory.\n";
				exit -1;
			}
		} else {
			if (!mkdir($export_dir, 0755, TRUE)) {
				echo "Error: Can't create directory '$export_dir'.\n";
				exit -1;
			}
		}

		return $export_dir;
	}

	function export( $domain_name, $options = null ) {
		echo "Export '$domain_name'\n";
		if (!array_key_exists($domain_name, $this->host_templates)) {
			echo "Error: Not found '$domain_name' in cacti host templates.\n";
			exit -1;
		}
		$template_id = $this->host_templates[$domain_name];
		error_reporting(0);
		$xml_data = get_item_xml('host_template', $template_id, true);
		error_reporting(1);
		if (!$xml_data) {
			echo "Error: Cacti host template '$domain_name' export failed.\n";
			exit -1;
		}
		$export_dir  = $this->mkdir_template_export_path( $domain_name );
		$export_path = $export_dir . "/cacti-host-template-${domain_name}.xml";
		echo "Writing '$export_path'\n";

		return file_put_contents($export_path, $xml_data );
	}

	function import_host_template( $filename ) {
		$rra_array = array();
		if(file_exists($filename) && is_readable($filename)) {
			$fp = fopen($filename,"r");
			$xml_data = fread($fp,filesize($filename));
			fclose($fp);

			echo "Read ".strlen($xml_data)." bytes of XML data\n";

			$debug_data = import_xml_data($xml_data, false, $rra_array);

			while (list($type, $type_array) = each($debug_data)) {
				print "** " . $hash_type_names[$type] . "\n";

				while (list($index, $vals) = each($type_array)) {
					if ($vals["result"] == "success") {
						$result_text = " [success]";
					}else{
						$result_text = " [fail]";
					}

					if ($vals["type"] == "update") {
						$type_text = " [update]";
					}else{
						$type_text = " [new]";
					}
					echo "   $result_text " . $vals["title"] . " $type_text\n";

					$dep_text = ""; $errors = false;
					if ((isset($vals["dep"])) && (sizeof($vals["dep"]) > 0)) {
						while (list($dep_hash, $dep_status) = each($vals["dep"])) {
							if ($dep_status == "met") {
								$dep_status_text = "Found Dependency: ";
							} else {
								$dep_status_text = "Unmet Dependency: ";
								$errors = true;
							}

							$dep_text .= "    + $dep_status_text " . hash_to_friendly_name($dep_hash, true) . "\n";
						}
					}

					/* dependency errors need to be reported */
					if ($errors) {
						echo $dep_text;
						exit(-1);
					}
				}
			}
		} else {
			echo "ERROR: file $filename is not readable, or does not exist\n\n";
			exit(1);
		}

		return true;
	}

	function import( $domain_name, $options = null ) {
		echo "Import '$domain_name'\n";
		if (array_key_exists($domain_name, $this->host_templates)) {
			echo "Error: Already exists '$domain_name' in cacti host templates. Remove '$domain_name' if you want.\n";
			exit -1;
		}
		$import_dir  = $this->mkdir_template_export_path( $domain_name );
		$import_path = $import_dir . "/cacti-host-template-${domain_name}.xml";
		if (!file_exists($import_path)) {
			echo "Error: Import file not found '$import_path'.\n";
			exit -1;
		}
		echo "Importing '$import_path'\n";
		error_reporting(0);
		$this->import_host_template( $import_path );
		error_reporting(1);

		return true;
	}
}

