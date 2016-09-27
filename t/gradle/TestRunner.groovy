package com.example

import org.hidetake.groovy.ssh.Ssh
import groovy.util.ConfigSlurper
import com.example.acceptance.*

/**
 * Created by naga on 2015/01/18.
 */
class CIServerProvisioning {

    def setup() {

        def ssh = Ssh.newService()
        ssh.remotes {
            webServer {
                host = '192.168.10.1'
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

                // Wget
                def existsWget = execute 'echo `yum list installed | grep wget`'
                if (!existsWget) {
                    executeSudo 'yum install wget -y'
                }

            }
        }
    }

    static void main(String[] args) {
        def config_file = System.properties["test.config"] ?: 'config/config.groovy'
        def config = new ConfigSlurper().parse(new File(config_file).toURL())
        // println config
        def test_class = 'LinuxTest'
        // def test = new LinuxTest(ip : '192.168.10.1')
        // def test = this.getClass.classLoader.loadClass( 'LinuxTest', true, false )?.newInstance(ip : '192.168.10.10')
        // def loader = new GroovyClassLoader(this.getClass().getClassLoader())
        // println loader.loadClass( 'LinuxTest', true, false )
        // def test = loader.loadClass( 'LinuxTest', true, false )?.newInstance(ip : '192.168.10.10')
        // test.run_test()

        // def url = 'src/main/groovy/com/example/acceptance/LinuxAcceptanceTest.groovy'
        def url = 'test/LinuxAcceptanceTest.groovy'
        GroovyClassLoader classLoader = new GroovyClassLoader()
        try {
            Class clazz = classLoader.parseClass(new File(url))
            if (clazz != null) {
                Object test = clazz.newInstance(ip : '192.168.10.10')
                test.run_test()
            }
        } catch (Throwable e) {
            println e.localizedMessage
        }
    }

}