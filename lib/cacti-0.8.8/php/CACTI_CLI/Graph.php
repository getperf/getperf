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

class Graph {

	public $site_home;
	public $domain_name;
	public $node_name;
	public $metric_name;
	public $title;

	public $data_source_ids = array();
	public $rrd_paths = array();

	public $graph_template_id;
	public $graph_type;

	static $nodeTypes = array('header' => 1, 'graph' => 2, 'host' => 3);

	function __construct( $set ) {
		try {
			$this->host_template   = $this->retrieve_data("host_template", $set, true);
			$this->host_title      = $this->retrieve_data("host_title", $set, true);
			$this->graph_composite = $this->retrieve_data("graph_composite", $set, false);
			$this->graphs          = $this->retrieve_data("graphs", $set, true);

		} catch (Exception $e) {
 		   echo 'Graph config error : ',  $e->getMessage(), "\n";
		}
	}

	// グラフツリーの追加
	// パス名で指定されたメニューを検索する
	// 存在しない場合は新規作成して、作成したIDを返す
	function mkdir_graph_tree($tree_id, $tree_path) {
		$paths = explode("/", $tree_path);
		$lvl	   = 0;
		$parent_id = 0;
		$cond	   = "";

		foreach ($paths as $path) {
			$path = str_replace("<node>", $node_name, $path);
			$path = str_replace("<domain>",  $domain_name, $path);

			if (strcmp($path, "") == 0) 
				continue;

			$sql  = "select * from graph_tree_items where graph_tree_id=$tree_id ";
			$sql .= "and order_key like '{$cond}___000%'";

			$tree_field = db_fetch_assoc($sql);
			$found = 0;
			if (sizeof($tree_field)) {
				foreach ($tree_field as $field) {
					if (strcmp($field["title"], $path) == 0) {
						$parent_id = $field["id"];
						$order_key = $field["order_key"];
						$found = 1;
						break;
					}
				}
			}
			// 検索結果が0の場合は、新規にパスを追加する
			if ($found == 0) {
				$item_type = 1; // 'header' => 1, 'graph' => 2, 'host' => 3
				$sort_methods = 1; // 'manual' => 1, 'alpha' => 2, 'natural' => 4, 'numeric' => 3
				$parent_id = api_tree_item_save(0, $tree_id, $item_type, $parent_id, $path, 0, 0, 0, 1, $sort_methods, false);

				$sql = "select order_key from graph_tree_items where id=$parent_id";
				$order_key = db_fetch_cell($sql, "order_key");
			}

			$cond .= substr($order_key, 3 * $lvl, 3);
			$lvl ++;

			echo "[" . __LINE__ . "] [$lvl][$cond]($path) id : $parent_id\n";
		}

		return($parent_id);
	}

	function ptune_addgraphs($exec_option) {
		global $script_path;

		$force           = 0;
		$hasone          = 0;
		$append	         = 0;
		$add_treetext    = 0;
		$alert_enabled   = 0;
		$nodevicetree    = 0;
		$rrd_path		     = "";
		$graph_tree_name = "";
		$domain_name	   = "";
		$host_name   	   = "";
		$rrd_config		   = "hw.conf";
		$server_type	   = "local";
		$build_file		   = "";
		$item_text		   = "";
		$devs			   = array();
		$graph_texts	   = array();
		$graph_thresholds  = array();
		extract($exec_option);

		// --rrdpathオプションは必須とする
		if (!sizeof($rrd_path)) {
			echo "ERROR: --rrdpath must be specified.\n\n";
			display_help();
			exit(1);
		}

		// --conf={ファイル}オプションで指定したJSONファイル
		if (file_exists("$script_path/$rrd_config")) {
			$rrd_config = "$script_path/$rrd_config";
		} elseif (!file_exists($rrd_config)) {
			echo "ERROR: Not Found: $rrd_config\n\n";
			display_help();
			exit(1);
		}

		// conf ファイルが前回実行時より更新されていれば キャッシュを無効にする
		$updated = TRUE;
		$update_time = filemtime($rrd_config);
		$checkdir  = $script_path . '/.conf_stat';
		$checkfile = str_replace("/", "_", $rrd_config);
		$checkpath = $checkdir . '/' . $checkfile;

		if (!is_dir($checkdir)) {
			mkdir($checkdir, 0755);
		} elseif (file_exists($checkpath)) {
			$last_update = file_get_contents($checkpath);
			if ($last_update == $update_time) {
				$updated = FALSE;
			}
		}
		if ($updated) {
			file_put_contents($checkpath, $update_time);
			$force = 1;
		}

		// --hasone,--appendオプションが付加されている時は、--devsオプションを必須とする
		if (($hasone == 1 || $append == 1) && sizeof($devs) == 0) {
			echo "ERROR: [--hasone|--append] --devs=[devs] required.\n\n";
			display_help();
			exit(1);
		}

		// --hasoneオプションがなく--devsオプションがあり--textsオプションがない場合は
		// --devsの値を--textsとする
		if ($hasone === 0 && sizeof($devs) > 0) {
			if (sizeof($graph_texts) === 0) {
				$graph_texts = $devs;
			} elseif (sizeof($devs) !== sizeof($graph_texts) ||
				(sizeof($graph_thresholds) > 0 && sizeof($devs) !== sizeof($graph_thresholds) )) {
				echo "ERROR: unmatch --devs=[devs] --texts=[texts]\n";
				print_r($devs);
				print_r($graph_texts);
				display_help();
				exit(1);
			} 
		}

		// JSONファイルのパース。エラー時には"decode error"とのみ出力する
		$conf = json_decode(file_get_contents($rrd_config));
		if (!$conf) {
			echo "ERROR: JSON decode error : $rrd_config\n";
			exit(1);
		}
		// Cactiリポジトリ読込み
		$cactidb = get_cacti_repository();

		// グラフ構成DBの初期化
		init_graph_db();

		// ツリーIDの検索
		$tree_id = find_graph_tree_id($graph_tree_name, $cactidb);

		// rrdファイルパスからホスト、rrdファイル名、ディレクトリを抽出する
		// ローカルホストの入力：/{host}/{cat}/.../rrdfile.rrd
		// リモートホストの入力:/{host}/{remote}/{cat}/.../rrdfile.rrd
		if (strcmp($server_type, "remote") === 0) {
			if (!preg_match("/^\/.*?\/(.*?)\/(.*)\/(.*\.rrd?)$/", $rrd_path, $rrd_regs)) {
				echo "ERROR: incorrect rrd path [/{host}/{cat}/{rrdfile.rrd}] : $rrd_path\n";
				exit(1);
			}
		} elseif (strcmp($server_type, "local") === 0) {
			if (!preg_match("/^\/(.*?)\/(.*)\/(.*\.rrd?)$/", $rrd_path, $rrd_regs)) {
				echo "ERROR: incorrect rrd path [/{host}/{cat}/{rrdfile.rrd}] : $rrd_path\n";
				exit(1);
			}
		} else {
			echo "ERROR: unmatch --server=[remote|local]\n";
			display_help();
			exit(1);
		}
		array_shift($rrd_regs);		   // 配列[0]の文字列全体は除く
		$rrd_host = array_shift($rrd_regs);
		$rrd_file = array_pop($rrd_regs);
		$rrd_dir  = join("/", $rrd_regs);

		// --host オプション付きの場合はホスト名を登録する
		if (strcmp($host_name, "") !== 0) {
			$host = $host_name;
		} else {
			$host = $rrd_host;
		}

		if (!sizeof($host) || !sizeof($rrd_file) || !sizeof($rrd_dir)) {
			echo "ERROR: incorrect rrd path : $rrd_path\n";
			echo "\thost=$host,rrd_dir=$rrd_dir,rrd_file=$rrd_file\n";
			exit(1);
		}

		// ホストの追加
		$host_id = ptune_add_device($host, $rrd_file, $conf, $cactidb, $force, $append);
		if ($host_id == 0) {
			echo "ERROR: ptune_add_device() failed.\n";
			print_r($host);
			print_r($rrd_file);
			exit(1);
		}

		// グラフの追加($graphidsには以下要素の配列が登録)
		// 
		// ["seq"] => 1
		// ["device"] => "sd1"
		// ["graph-id"] => 1
		// ["data-source-id"][] => 1,2...
		// ["graph-tree"] => "/HW/Disk/MBs"
		// ["datasource-title"] => "HW - <host> - Disk Busy% - <dev>"
		$reuse = 0;
		$graphids = ptune_add_graph($host, $devs, $graph_texts, $host_id, $rrd_file, $conf,
			$cactidb, $force, $append, $hasone, $graph_thresholds, $reuse);

		// 追加したグラフリストを順にCactiリポジトリに登録する
		echo "[" . __LINE__ . "] ==== Update Datasource ====\n";
		foreach ($graphids as $graphid) {
			if ($reuse === 1) {
				echo "[" . __LINE__ . "] Graph aleady exists. Skip Cacti update.\n";
			} else {
				// データソース、閾値、グラフテンプレートなどのCactiリポジトリへの登録
				echo "[" . __LINE__ . "] Update GraphID : " . $graphid{'graph-id'} . "\n";

				// confファイルの datasource-title (HW - <host> - CPU Util%) からメトリック種別(HW)取得
				$statname = '';
				if (preg_match("/^(\w.+?) - /", $graphid{'datasource-title'}, $matches)) {
					$statname = $matches[1];
				}
				$graphid{'statname'} = $statname;
				// --hasoneオプションありでデバイス指定ありの１：１のグラフの登録
				if ($hasone == 1) {
					update_ds_with_device_1x1($graphid, $host_id, $host, $rrd_path, $alert_enabled);
				// デバイス指定なしのグラフの登録
				} elseif (sizeof($devs) == 0) {
					update_ds_no_device($graphid, $host_id, $host, $rrd_path, $graph_thresholds, $alert_enabled);
				// デバイス指定ありの複数デバイスを束ねたグラフの登録
				} else {
					update_ds_with_multi_device($graphid, $host_id, $host, $rrd_path, $devs, $graph_texts, $alert_enabled);
				}
				// 項目のコメント追加
				if ($item_text !== "") {
					$sql  = "SELECT id from graph_templates_item WHERE ";
					$sql .= "local_graph_id = " . $graphid{'graph-id'} . " AND ";
					$sql .= "task_item_id = 0 AND graph_type_id = 1";

					$item_text_ids = db_fetch_assoc($sql);
					if (sizeof($item_text_ids) === 1) {
						foreach ($item_text_ids as $item_text_id) {
							$id = $item_text_id['id'];
							$sql  = "UPDATE graph_templates_item SET text_format='$item_text' ";
							$sql .= "WHERE  id = $id";
							db_execute($sql);
							echo "[" . __LINE__ . "] Add comment : $item_text, id : $id\n";
						}
					}
				}
			}
			// ツリーメニューの追加
			regist_tree($graphid, $tree_id, $host, $domain_name, $nodevicetree, $add_treetext);
		}
	}

	// データソースの登録。１デバイスにつき１グラフ設定する場合
	function update_ds_with_device_1x1($graphid, $host_id, $host, $rrd_source, $alert_enabled) {
		$device = $graphid{'device'};

		foreach ($graphid{'data-source-id'} as $data_source_id) {
			$dsname = str_replace("<host>", $host, $graphid{'datasource-title'});
			$dsname = str_replace("<dev>", $device, $dsname);
			$rrd_path = str_replace("*", $device, $rrd_source);

			echo "[" . __LINE__ . "] DSName : $dsname, id : $data_source_id," .
				" /$rrd_path\n";
			$sql  = "UPDATE data_template_data SET ";
			$sql .= "name_cache='$dsname', ";
			$sql .= "data_source_path='<path_rra>/$rrd_path' ";
			$sql .= " WHERE    local_data_id=$data_source_id";
			db_execute($sql);

			$sql  = "UPDATE getperf_datasources SET ";
			$sql .= "datasource_title = '$device' where id = $data_source_id";
			db_execute($sql);

			// アラート監視登録
			if ($graphid{'alert_priority'} === 1) {
				$local_graph_id = $graphid{'graph-id'};
				$alert_priority = $graphid{'alert_priority'};
				$statname = $graphid{'statname'};
				$sql = "REPLACE INTO getperf_alerts " .
					"(statname, rrd_path, alert_priority, alert_enabled, " .
					"local_data_id, host_id, graph_id) " .
					"VALUES ('$statname','$rrd_path', $alert_priority, $alert_enabled, " .
					"$data_source_id, $host_id, $local_graph_id)";
				db_execute($sql);
				echo "[" . __LINE__ . "] === Add Alert($data_source_id) ===\n";
			}
		}
	}

	// デバイス指定なしのグラフの登録
	function update_ds_no_device($graphid, $host_id, $host, $rrd_source, $graph_thresholds, $alert_enabled) {

		foreach ($graphid{'data-source-id'} as $data_source_id) {
			$dsname  = str_replace("<host>", $host, $graphid{'datasource-title'});
			$rrd_path = $rrd_source;
			echo "[" . __LINE__ . "] DSName : $dsname, id : $data_source_id," .
				$rrd_path . "\n";

			$sql  = "UPDATE data_template_data SET ";
			$sql .= "name_cache='$dsname', ";
			$sql .= "data_source_path='<path_rra>/$rrd_path' ";
			$sql .= " WHERE    local_data_id=$data_source_id";
			db_execute($sql);

			$sql  = "UPDATE getperf_datasources SET ";
			$sql .= "datasource_title = '$dsname' where id = $data_source_id";
			db_execute($sql);
						
			// 閾値線の指定がある場合はgraph_templates_item表登録
			if (sizeof($graph_thresholds) === 1) {
				$graph_threshold = $graph_thresholds[0];
				$local_graph_id  = $graphid{'graph-id'};
				$sql = "select id from graph_templates_item where "
					 . "local_graph_id=$local_graph_id and graph_type_id=2";
				$threshold_ids = db_fetch_assoc($sql);
				if (sizeof($threshold_ids) === 1) {
					$threshold_id = $threshold_ids[0];
					$id = $threshold_id['id'];
					$sql = "update graph_templates_item set value= $graph_threshold "
						. "where id = $id";
					db_execute($sql);
					echo "[" . __LINE__ . "] Threshold($local_graph_id: $id) : $graph_threshold\n";
				}
			}
			// アラート監視登録
			if ($graphid{'alert_priority'} === 1) {
				$local_graph_id = $graphid{'graph-id'};
				$alert_priority = $graphid{'alert_priority'};
				$statname = $graphid{'statname'};
				$sql = "REPLACE INTO getperf_alerts " .
					"(statname, rrd_path, alert_priority, alert_enabled, " .
					"local_data_id, host_id, graph_id) " .
					"VALUES ('$statname','$rrd_path', $alert_priority, $alert_enabled, " .
					"$data_source_id, $host_id, $local_graph_id)";
				db_execute($sql);
				echo "[" . __LINE__ . "] === Add Alert($data_source_id) ===\n";
			}
		}
	}

	// 複数デバイスを束ねたグラフの登録
	function update_ds_with_multi_device($graphid, $host_id, $host, $rrd_source, $devs, $graph_texts, $alert_enabled) {
		$i = 0;
		foreach ($graphid{'data-source-id'} as $data_source_id) {
			// rrdファイル名の更新
			$dsname = str_replace("<host>", $host, $graphid{'datasource-title'});
			$dsname = str_replace("<dev>", $devs[$i], $dsname);
			$rrd_path = str_replace("*", $devs[$i++], $rrd_source);

			echo "[" . __LINE__ . "] DSName : $dsname, id : $data_source_id, $rrd_path\n";

			$sql  = "UPDATE data_template_data SET ";
			$sql .= "name_cache='$dsname', ";
			$sql .= "data_source_path='<path_rra>/$rrd_path' ";
			$sql .= " WHERE    local_data_id=$data_source_id";
			db_execute($sql);

			$sql  = "UPDATE getperf_datasources SET ";
			$sql .= "datasource_title = '$dsname' where id = $data_source_id";
			db_execute($sql);

			// アラート監視登録
			if ($graphid{'alert_priority'} === 1) {
				$local_graph_id = $graphid{'graph-id'};
				$alert_priority = $graphid{'alert_priority'};
				$statname = $graphid{'statname'};
				$sql = "REPLACE INTO getperf_alerts " .
					"(statname, rrd_path, alert_priority, alert_enabled, " .
					"local_data_id, host_id, graph_id) " .
					"VALUES ('$statname','$rrd_path', $alert_priority, $alert_enabled, " .
					"$data_source_id, $host_id, $local_graph_id)";
				db_execute($sql);
				echo "[" . __LINE__ . "] === Add Alert($data_source_id) ===\n";
			}
		}

		// グラフ凡例の更新
		echo "[" . __LINE__ . "] ==== Update Graph Text ====\n";
		$sql  = "SELECT id ";
		$sql .= "FROM graph_templates_item ";
		$sql .= "WHERE local_graph_id = " . $graphid{'graph-id'} . " ";
		$sql .= "AND graph_type_id in (4,5,6,7,8) ";
		$sql .= "AND task_item_id != 0 ";
		$sql .= "ORDER BY sequence ";

		$text_ids = db_fetch_assoc($sql);
		if (sizeof($text_ids) === sizeof($graph_texts)) {
			$text_seq = 0;
			foreach ($text_ids as $text_id) {
				$text_name = $graph_texts[$text_seq];
				$id = $text_id['id'];
				$sql  = "UPDATE graph_templates_item SET ";
				$sql .= "text_format='$text_name' ";
				$sql .= " WHERE id=$id";
				db_execute($sql);
				echo "[" . __LINE__ . "] GraphText($text_seq) : $text_name, id : $id\n";
				$text_seq ++;
			}
		} else {
			echo "ERROR: Graph text error(" . $graphid{'graph-id'} . ")\n";
			echo "ERROR: Graph text id : " . join(",", $text_ids) . "\n";
			echo "ERROR: --texts       : " . join(",", $graph_texts) . "\n";
			exit(1);
		}
	}

	// ツリーの登録
	function regist_tree($graphid, $tree_id, $host, $domain_name, $nodevicetree, $add_treetext) {
		global $script_path;
		// $graphid['greph-tree']を解析し、$tree_path[]を作成
		$tree_paths = array();
		$graph_tree_paths = explode("/", $graphid{'graph-tree'});
		$device = $graphid{"device"};
		if (array_key_exists("devtext", $graphid) && sizeof($graphid{"devtext"}) > 0) {
			$device = $graphid{"devtext"};
		}

		foreach ($graph_tree_paths as $path) {
			if (strcmp($path, "") == 0) {
				continue;
			} elseif (strcmp($path, "<host>") == 0) {
				$tree_paths[] = $host;
			} elseif (strcmp($path, "<dom>") == 0) {
				$domains = explode("/", $domain_name);
				foreach ($domains as $domain) {
					$tree_paths[] = $domain;			
				}
			} elseif (strcmp($path, "<dev>") == 0) {
				if ($nodevicetree == 0) {
					$tree_paths[] = $device;
				}
			} else {
				$tree_paths[] = $path;			
			}
		}

		// --add-treetext オプションつきの場合は最後にデバイス名を追加
		if ($add_treetext == 1 && $nodevicetree == 0) {
			$tree_paths[] = $device;
		}

		// ツリーにグラフ登録
		$graph_id = $graphid{'graph-id'};
		$tree_title = implode("->", $tree_paths);
		echo "[" . __LINE__ . "] Add Tree : $tree_title($graph_id)\n";

		// ツリーIDの検索。ツリーがない場合は新規作成
		$parent_id = mkdir_graph_tree($tree_id, $tree_paths);

		if ($parent_id > 0) {
			$cmd  = "add_tree.php --type=node --node-type=graph ";
			$cmd .= "--tree-id=$tree_id ";
			$cmd .= "--parent-node=$parent_id ";
			$cmd .= "--graph-id=$graph_id ";

			$out = array();
			$rc  = null;
			exec("php $script_path/$cmd", $out, $rc);
			if ($rc) {
				echo "ERROR: php $script_path/$cmd\n";
				exit(1);
			} else {
				foreach ($out as $str) {
					if (preg_match("/Added Node node-id: \((.*?)\)$/", $str, $regs)) {
						echo "[" . __LINE__ . "] ---> Graph Tree add : $regs[1]\n";
					}
				}
			}
		} else {
			echo "ERROR: mkdir_graph_tree() failed.\n";
			print_r($tree_id);
			print_r($graph_tree_path);
			exit(1);
		}
	}

	// グラフツリーの追加
	// パス名で指定されたメニューを検索する
	// 存在しない場合は新規作成して、作成したIDを返す
	function mkdir_graph_tree($tree_id, $tree_paths) {
		global $script_path;
		static $cache_trees = array();
		echo "[" . __LINE__ . "] ==== Update Tree ====\n";
		echo "[" . __LINE__ . "] id : $tree_id\n";

		$lvl	   = 0;
		$parent_id = 0;
		$cond	   = "";
		$tree      = "";

		// ツリーパスを分解し、順に検索する
		foreach ($tree_paths as $path) {
			if (strcmp($path, "") == 0) {
				continue;
			}
			$tree = $tree . '/' . $path;
			if (array_key_exists($tree, $cache_trees)) {
				extract($cache_trees[$tree]); 	// lvl, cond, parent_id
				echo "[" . __LINE__ . "] [$lvl][$cond]($path) id : $parent_id\n";
				continue;
			}
			$sql  = "select * from graph_tree_items where graph_tree_id=$tree_id ";
			$sql .= "and order_key like '{$cond}___000%'";

			$tree_field = db_fetch_assoc($sql);
			$found = 0;
			if (sizeof($tree_field)) {
				foreach ($tree_field as $field) {
					if (strcmp($field["title"], $path) == 0) {
						$parent_id = $field["id"];
						$order_key = $field["order_key"];
						$found = 1;
						break;
					}
				}
			}
			// 検索結果が0の場合は、新規にパスを追加する
			if ($found == 0) {
				$cmd  = "add_tree.php --type=node --node-type=header ";
				$cmd .= "--tree-id=$tree_id --sort-method=manual ";
				$cmd .= "--name=\"$path\" ";

				if ($parent_id > 0) {
					$cmd .= "--parent-node=$parent_id ";
				}

				$out = array();
				$rc  = null;
				exec("php $script_path/$cmd", $out, $rc);
				if ($rc) {
					echo "ERROR: php $script_path/$cmd\n";
					exit(1);
				} else {
				  foreach ($out as $str) {
						if (preg_match("/Added Node node-id: \((.*?)\)$/", $str, $regs)) {
							$parent_id = $regs[1];
						}
					}
					$sql = "select order_key from graph_tree_items where id=$parent_id";
					$order_key = db_fetch_cell($sql, "order_key");
				}
			}

			$cond .= substr($order_key, 3 * $lvl, 3);
			$lvl ++;

			echo "[" . __LINE__ . "] [$lvl][$cond]($path) id : $parent_id\n";
			$cache_trees[$tree] = compact('lvl', 'cond', 'parent_id');
		}

		return($parent_id);
	}

	// デバイスの追加
	function ptune_add_device($host, $rrd_file, $conf, $cactidb, $force, $append) {
		global $script_path;
		static $cache_host_ids = array();

		echo "[" . __LINE__ . "] ==== Add Device ====\n";
		if (isset($conf->{$rrd_file})) {
			$conf_host = $conf->{$rrd_file};

			// ホストテンプレートIDの検索
			if (!isset($conf_host->{'host-template'})) {
				echo "ERROR: incorrect device : \n";
				print_r($conf_host);
				exit(1);
			}
			if (!isset($cactidb['host_template'][$conf_host->{'host-template'}])) {
				echo "ERROR: host-template Not Found : ";
				print_r($conf_host->{'host-template'});
				echo "\n";
				exit(1);
			}
			$host_template_name = $conf_host->{'host-template'};
			$host_template_id	= $cactidb['host_template'][$conf_host->{'host-template'}];
			echo "[" . __LINE__ . "] host_template_name : " .
				$host_template_name . ",id : " . $host_template_id . "\n";

			// デバイスタイトルの設定
			if (!isset($conf_host->{'host-title'})) {
				echo "ERROR: incorrect host-title : \n";
				print_r($conf_host);
				exit(1);
			}

			$host_title = $conf_host->{'host-title'};
			$host_title = str_replace('<host>', $host, $host_title);
			echo "[" . __LINE__ . "] host_title : $host_title\n";

			// デバイスが既に登録されいているかチェック
			if (array_key_exists($host_title, $cache_host_ids)) {
				$host_id = $cache_host_ids[$host_title];
			} else {
				$host_id = db_fetch_cell("select id from host where description ='$host_title'");
			}
			if ($host_id > 0) {
				echo "[" . __LINE__ . "] Host aleady exists($host_id) : $host_title\n";
				// 存在していて--forceモードでない場合はidを返す
				if ($force == 0) {
					return($host_id);
				// --forceモードの場合はデバイスを削除
				} else {
					api_device_remove($host_id);
					echo "[" . __LINE__ . "] Remove id : $host_id\n";
				}
			}

			// デバイスの登録
			// コマンド：php add_device.php --description="HW - test01" --ip="HW - test01" \
			//	   --template=10
			$out = array();
			$rc  = null;
			$cmd = "add_device.php --version=2 --description=\"$host_title\" ";
			$cmd .= "--ip=\"$host_title\" --template=$host_template_id";
			exec("php $script_path/$cmd", $out, $rc);
			if ($rc) {
				echo "ERROR: php $script_path/$cmd\n";
				exit(1);
			} else {
				// new device-id: (1125)
				$host_id = 0;
				foreach ($out as $str) {
					if (preg_match("/new device-id: \((.*?)\)$/", $str, $regs)) {
						$host_id = $regs[1];
					}
				}
			}
			echo "[" . __LINE__ . "] exec add_device.php ---> host_id : $host_id\n";
			return($host_id);
		} else {
			echo "ERROR: incorrect rrd_file : $rrd_file\n";
			exit(1);
		}
	}

	// データソースが既に登録されいている場合は削除
	function remove_data_source($datasource_title) {
		$sql = "select local_data_id from data_template_data where name_cache ='$datasource_title'";
		$ds_ids = db_fetch_assoc($sql);
		if (sizeof($ds_ids) > 0) {
			echo "[" . __LINE__ . "] Data Source aleady exists : $datasource_title\n";
			foreach ($ds_ids as $ds_id) {
				$id = $ds_id['local_data_id'];
				api_data_source_remove($id);
				echo "[" . __LINE__ . "] Remove id : $id\n";
			}
		}
		return 1;
	}

	// データソースが既に登録されいているかチェック
	function check_data_source($datasource_title) {
		$sql = "select local_data_id from data_template_data where name_cache ='$datasource_title'";
		$ds_ids = db_fetch_assoc($sql);
		return (sizeof($ds_ids) > 0) ? 1 : 0;
	}

	// グラフが既に登録されているかチェック
	function check_graph_exists($host, $devs, $rrd_file, $conf) {

		if (isset($conf->{$rrd_file})) {
			$res = array();
			$conf_host = $conf->{$rrd_file};

			// ホストテンプレートIDの検索
			if (!isset($conf_host->{'graph'})) {
				echo "ERROR: incorrect graph : \n";
				print_r($conf_host);
				exit(1);
			}
			// グラフ配列から順にグラフを登録する
			foreach ($conf_host->{'graph'} as $conf_graph) {

				if (sizeof($devs) == 0) {
					$ds = $conf_graph->{'datasource-title'};
					$ds = str_replace("<host>", $host, $ds);
					if (check_data_source($ds) === 1) {
						return 1;
					}
				} else {
					foreach ($devs as $dev) {
						$ds = $conf_graph->{'datasource-title'};
						$ds = str_replace("<host>", $host, $ds);
						$ds = str_replace("<dev>", $dev, $ds);
						if (check_data_source($ds) === 1) {
							return 1;
						}
					}
				}
			}
		}
		return 0;
	}

	// グラフの追加
	function ptune_add_graph($host, $devs, $texts, $hostid, $rrd_file, $conf, $cactidb, $force, $append, $hasone, $thresholds, &$reuse) {
		global $script_path;

		echo "[" . __LINE__ . "] ==== Add Graphs ====\n";
		echo "[" . __LINE__ . "] hostid : $hostid,rrd_file : $rrd_file\n";
		if (isset($conf->{$rrd_file})) {
			$res = array();
			$conf_host = $conf->{$rrd_file};

			$device_tag  = implode ( '|' , $devs );
			$devtext_tag = implode ( '|' , $texts );

			// 過去の実行履歴を検索して、同一の結果であれば処理をスキップする
			if (!$force) {
				$sql  = "select result from getperf_graphs where host_id=$hostid and hostname='$host' ";
				$sql .= "and rrdname='$rrd_file' and hasone = $hasone and devices = '$device_tag' and ";
				$sql .= "devicetexts = '$devtext_tag'";
				if ( $results_json = db_fetch_cell($sql) ) {
					$res = json_decode($results_json, true);
					if (!is_null($res)) {
						$reuse = 1;
						return $res;
					}
				}
			}

			// ホストテンプレートIDの検索
			if (!isset($conf_host->{'graph'})) {
				echo "ERROR: incorrect graph : \n";
				print_r($conf_host);
				exit(1);
			}
			// グラフ配列から順にグラフを登録する
			foreach ($conf_host->{'graph'} as $conf_graph) {

				// グラフ作成をする前に既存のデータソースを削除
				if ($append == 0) {
					if (sizeof($devs) == 0) {
						$ds = $conf_graph->{'datasource-title'};
						$ds = str_replace("<host>", $host, $ds);
						remove_data_source($ds);
					} else {
						foreach ($devs as $dev) {
							$ds = $conf_graph->{'datasource-title'};
							$ds = str_replace("<host>", $host, $ds);
							$ds = str_replace("<dev>", $dev, $ds);
							remove_data_source($ds);
						}
					}
				}
				// グラフテンプレートの指定
				$graph_template = $conf_graph->{'graph-template'};

				// デバイスの指定があり、--hasoneオプションがない場合は、グラフテンプレートを
				// "名前 - <devn> cols"として指定する
				$devn = sizeof($devs);
				if ($hasone == 0 && $devn > 0) {
					$graph_template = str_replace("<devn>", $devn, $graph_template);
				}

				// 閾値線指定がある場合はグラフテンプレートを "名前 - bordered" とする
				if (sizeof($thresholds) > 0) {
					$graph_template_borderd = $graph_template . ' - bordered';
					if (isset($cactidb['graph_template'][$graph_template_borderd])) {
						$graph_template = $graph_template_borderd;
					}
				}

				// グラフテンプレートIDの検索
				if (!isset($cactidb['graph_template'][$graph_template])) {
					echo "ERROR: graph-template Not Found : ";
					print_r($graph_template);
					echo "\n";
					exit(1);
				}

				$graph_template_id = $cactidb['graph_template'][$graph_template];
				echo "[" . __LINE__ . "] graph_template : " .
					$graph_template . ",id : " . $graph_template_id . "\n";

				// グラフタイトルの設定
				if (!isset($conf_graph->{'graph-title'})) {
					echo "ERROR: incorrect graph-title : \n";
					print_r($conf_graph);
					exit(1);
				}
				$graph_title = $conf_graph->{'graph-title'};
				$graph_title = str_replace('<host>', $host, $graph_title);
				echo "[" . __LINE__ . "] graph_title : $graph_title\n";

				// --hasone オプションがあり、複数デバイスに対して1:1のグラフを設定する場合
				$devices  = array();
				$devtexts = array();
				if ($hasone == 1) {
					$devices  = $devs;
					$devtexts = $texts;
				} else {
					array_push($devices,  '');
					array_push($devtexts, '');
				}

				// 登録したグラフタイトルを順に設定
				foreach ($devices as $device) {
					$graph_res = array();
					$devtext   = array_shift($devtexts);
					
					if (strcmp($device, "") == 0) {
						$title = $graph_title;
					} else {
						if (strcmp($devtext, "") == 0) {
							$title = str_replace('<dev>', $device,  $graph_title);
						} else {
							$title = str_replace('<dev>', $devtext, $graph_title);
						}
					}
					echo "[" . __LINE__ . "] exec add_graphs.php ($title)\n";

					// グラフが既に登録されいているかチェック
					$sql  = "select local_graph_id, title_cache ";
					$sql .= "from graph_templates_graph ";
					$sql .= "where title_cache like '$title%' ";
					$sql .= "order by title_cache ";

					$local_graphs = db_fetch_assoc($sql);

					$seq = 0;
					foreach ($local_graphs as $local_graph) {
						$title_cache = $local_graph['title_cache'];
						$suffix = substr($title_cache, strlen($title));

						// サフィックスが付いていない場合は1を発番とする
						$exist = 0;
						if (strcmp($suffix, "") == 0) {
							$exist = 1;
							$seq = 1;
						// 枝番が付いてる場合は枝番+1を発番とする
						} elseif (preg_match("/^ (\d+)$/", $suffix, $regs)) {
							$exist = 1;
							$seq = $regs[1] + 1;
						}
						// --appendモードでない場合は削除
						if ($exist == 1 && $append == 0) {
							echo "WARNING: Graph aleady exists : $title\n";
							$local_graph_id = $local_graph['local_graph_id'];

							// グラフを削除
							api_graph_remove($local_graph_id);

							echo "[" . __LINE__ . "] Remove id : $local_graph_id\n";
						}
					}
					// --appendモードで発番がされた場合はグラフ名を"$title <seq>"に変更
					if ($append == 1 && $seq > 0) {
						$title = $title . ' ' . $seq;
					}

					// グラフの登録
					// コマンド：php add_graphs.php --graph-type=cg --graph-title="test" \
					//	 --host-id=1125 --graph-template-id=224
					$out = array();
					$rc  = null;
					$cmd = "add_graphs.php --graph-type=cg --force --graph-title=\"$title\" ";
					$cmd .= "--host-id=$hostid --graph-template-id=$graph_template_id";
					exec("php $script_path/$cmd", $out, $rc);
					if ($rc) {
						echo "ERROR: php $script_path/$cmd\n";
						exit(1);
					} else {
						// Graph Added - graph-id: (4204) - data-source-ids: (5282)
						$graph_id = 0;
						$data_source_id = array();
						foreach ($out as $str) {
							if (preg_match("/graph-id: \((\d+)\).*data-source-ids: \((.*?)\)$/", $str, $regs)) {
								$graph_id = $regs[1];
								$data_source_id = split(",", $regs[2]);
								// データソースID の登録
								foreach ($data_source_id as $id) {
									$sql = "replace into getperf_datasources (id, getperf_graph_id) " .
										"values ($id, $graph_id)";
									db_execute($sql);
								}
							}
						}

						$graph_res{'seq'}		= $seq;
						$graph_res{'device'}	= $device;
						$graph_res{'devtext'}   = $devtext;
						$graph_res{'graph-id'}	= $graph_id;
						echo "[" . __LINE__ . "] ---> graph_id : $graph_id," .
							"data-source-id : " . join(",", $data_source_id) . "\n";
						$graph_res{'data-source-id'}   = $data_source_id;
						$graph_res{'graph-tree'}	   = $conf_graph->{'graph-tree'};
						$graph_res{'datasource-title'} = $conf_graph->{'datasource-title'};
						$graph_res{'alert_priority'} = 
							isset($conf_graph->{'alert_priority'}) ? 
							$conf_graph->{'alert_priority'} : 0;
					}
					array_push($res, $graph_res);
				}
			}
			// グラフ履歴の登録
			$result_tag = json_encode($res);
			$sql  = "replace into getperf_graphs (host_id, hostname, rrdname, hasone, devices, devicetexts, result) ";
			$sql .= "values ($hostid, '$host', '$rrd_file', $hasone, '$device_tag', '$devtext_tag', '$result_tag')"; 
			db_execute($sql);

			return($res);
		} else {
			echo "ERROR: incorrect rrd_file : $rrd_file\n";
			exit(1);
		}
	}
}

