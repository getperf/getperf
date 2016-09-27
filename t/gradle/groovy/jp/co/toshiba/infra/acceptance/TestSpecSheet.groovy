package jp.co.toshiba.infra.acceptance

import com.jcraft.jsch.ChannelExec
import groovy.util.logging.Slf4j
import org.apache.commons.io.FileUtils.*
import groovy.transform.ToString
import org.apache.poi.ss.usermodel.*
import org.apache.poi.xssf.usermodel.*
import org.apache.poi.hssf.usermodel.HSSFWorkbook
import static groovy.json.JsonOutput.*
import org.hidetake.groovy.ssh.Ssh

@Slf4j
class TestSpecSheet {
    // 検査シートファイル名
    def spec_file    = 'check_sheet.xlsx'
    // 検査対象サーバリストシート
    def sheet_server = 'testServers'
    // 検査シート
    def sheet_tests = [
        'Linux': 'checkSheet(Linux)', 'Windows': 'checkSheet(Windows)'
    ]

    def TestSpecSheet(Map configs) {
        if (configs) {
            if (configs['spec_file'])
                this.spec_file    = configs['spec_file']
            if (configs['sheet_server'])
                this.sheet_server = configs['sheet_server']
            if (configs['sheet_tests'])
                this.sheet_tests  = configs['sheet_tests']
        }
    }

    def readVmConfig() {
        println this.spec_file
        log.info("Reading test spec sheet $spec_file")
        def items = new FileInputStream(this.spec_file).withStream { ins ->
            WorkbookFactory.create(ins).with { workbook ->
                // 検査対象サーバリスト取得
        println this.sheet_server
                def sheet = workbook.getSheet(this.sheet_server)
                println sheet
            //     workbook.getSheet(this.sheet_server).with { sheet ->
            //     (2 .. sheet.getLastRowNum()).each { rownum ->
            //         Row row = sheet.getRow(rownum)
            //             println row
            //             // VmConfigs.push([
            //             //     test_server : row.getCell(2).getStringCellValue(),
            //             //     ip          : row.getCell(3).getStringCellValue(),
            //             //     os          : row.getCell(4).getStringCellValue(),
            //             //     account     : row.getCell(5).getStringCellValue(),
            //             //     vcenter_id  : row.getCell(6).getStringCellValue(),
            //             //     vm          : row.getCell(7).getStringCellValue(),
            //             // ])
            //         }
            //     }
            //     // 検査仕様リスト取得
            //     // SheetTestSpecs.each { os, test_spec_sheet ->
            //     //     workbook.getSheet(test_spec_sheet).with { sheet ->
            //     //         (4 .. sheet.getLastRowNum()).each { rownum ->
            //     //             Row row = sheet.getRow(rownum)
            //     //             def yes_no      = row.getCell(0).getStringCellValue()
            //     //             def test_id     = row.getCell(1).getStringCellValue()
            //     //             def test_domain = row.getCell(3).getStringCellValue()
            //     //             if (test_id && test_domain && yes_no.toUpperCase() == "Y") {
            //     //                 TestSpecs[os][test_domain][test_id] = 1
            //     //             }
            //     //         }
            //     //     }
            //     // }
            // }
            }
        }
    }

    def readTestSpec() {

    }

    def writeTestResult() {

    }
}