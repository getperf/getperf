package jp.co.toshiba.infra.acceptance

import org.apache.commons.io.FileUtils.*
import groovy.transform.ToString
import org.apache.poi.ss.usermodel.*
import org.apache.poi.xssf.usermodel.*
import org.apache.poi.hssf.usermodel.HSSFWorkbook
import static groovy.json.JsonOutput.*
import org.hidetake.groovy.ssh.Ssh

class TestRunner {
    // 検査対象サーバ名をキーにしたサーバ接続情報
    VMConfig vm_configs = [:]
    // 検査ドメイン、検査IDをキーにした検査仕様
    TestConfig test_configs = [:].withDefault{[:]}
    // 検査対象サーバ、検査ドメイン、検査IDをキーにした検査結果
    TestResult test_results = [:].withDefault{[:].withDefault{[:]}}

    TestRunner(configs) {
        if (configs) {
            if (configs.contains('source'))
                spec_file    = configs['source']
            if (configs.contains('server_config'))
                sheet_server = configs['server_config']
            if (configs.contains('checksheet'))
                sheet_tests  = configs['checksheet']
        }
        println this
    }

    def initialize() {
        println test_spec_file
        if (this.getTestSpec() == false) {

            return false
        }
    }

    def getTestSpec() {
        def items = new FileInputStream(this.test_spec_file).withStream { ins ->
            WorkbookFactory.create(ins).with { workbook ->
                // 検査対象サーバリスト取得
                workbook.getSheet(this.server_config).with { sheet ->
                (2 .. sheet.getLastRowNum()).each { rownum ->
                    Row row = sheet.getRow(rownum)
                        println row
                        // VmConfigs.push([
                        //     test_server : row.getCell(2).getStringCellValue(),
                        //     ip          : row.getCell(3).getStringCellValue(),
                        //     os          : row.getCell(4).getStringCellValue(),
                        //     account     : row.getCell(5).getStringCellValue(),
                        //     vcenter_id  : row.getCell(6).getStringCellValue(),
                        //     vm          : row.getCell(7).getStringCellValue(),
                        // ])
                    }
                }
                // 検査仕様リスト取得
                // SheetTestSpecs.each { os, test_spec_sheet ->
                //     workbook.getSheet(test_spec_sheet).with { sheet ->
                //         (4 .. sheet.getLastRowNum()).each { rownum ->
                //             Row row = sheet.getRow(rownum)
                //             def yes_no      = row.getCell(0).getStringCellValue()
                //             def test_id     = row.getCell(1).getStringCellValue()
                //             def test_domain = row.getCell(3).getStringCellValue()
                //             if (test_id && test_domain && yes_no.toUpperCase() == "Y") {
                //                 TestSpecs[os][test_domain][test_id] = 1
                //             }
                //         }
                //     }
                // }
            }
        }

    }

    def runTest() {
    }

    def finish() {
    }

    def setup() {

        def ssh = Ssh.newService()
        ssh.remotes {
            webServer {
                host = 'paas.moi'
                port = 22
                user = 'psadmin'
                password = 'psadmin'
                knownHosts = allowAnyHosts
            }
        }

        ssh.run {
            session(ssh.remotes.webServer) {

                // 日本語設定
                def isJST = execute('echo `date | grep JST`')
                if (!isJST) {
                    executeSudo 'yum update -y'
                    executeSudo 'yum -y groupinstall "Japanese Support"'
                    executeSudo 'localedef -f UTF-8 -i ja_JP ja_JP.utf8'

                    executeSudo "sed -e 's/en_US/ja_JP/g' /etc/sysconfig/i18n > ~/i18n"
                    execute 'chmod 644 i18n'
                    executeSudo 'mv i18n /etc/sysconfig/'

                    executeSudo "sed -e 's/Etc/Asia/g' -e 's/UTC/Tokyo/g' /etc/sysconfig/clock > ~/clock"
                    execute 'chmod 644 clock'
                    executeSudo 'mv clock /etc/sysconfig/'

                    executeSudo 'sudo cp /usr/share/zoneinfo/Japan /etc/localtime'
                }
            }
        }
    }

    static void main(String[] args) {
        def config_file = System.properties["test.config"] ?: './config/test_scenario.groovy'
        def config = new ConfigSlurper().parse(new File(config_file).toURL())
        println config
        def excel = new TestSpecSheet(config['evidence'])
        println excel.spec_file
        excel.readVmConfig()
        // def test = new TestRunner(config['evidence'])
        // test.initialize()
        // test.runTest()
        // test.finish()
    }

}