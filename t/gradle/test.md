Groovy調査
=============

ToDo
------

* Spock テスト調査
* クラスローダープロト
* CLI スクリプト

Spoc テスト
-------------

**リファレンス**

http://qiita.com/shisashi/items/877446f3abfd46eafcd2

def "collectで変換1"() {
    given:
    def dates = ['2015/5/5', '2015/1/1', '2015/10/10', '2015/11/3'].collect { new Date(it) }

    when:
    def firstDate = FirstDate.firstDate(dates)

    then:
    firstDate == '2015/1/1' as Date
}

**groovyプロキシー設定**

vi ~/.groovy/startup

export JAVA_OPTS="-DproxyHost=proxy.toshiba.co.jp -DproxyPort=8080"

vi ~/.m2/setting.xml

<settings>
  <proxies>
    <proxy>
      <active>true</active>
      <protocol>http</protocol>
      <host>proxy.toshiba.co.jp</host>
      <port>8080</port>
    </proxy>
  </proxies>
</settings>

vi ~/.groovy/startup

export MAVEN_OPTS="-Dhttps.proxyHost=proxy.toshiba.co.jp -Dhttps.proxyPort=8080"

which keytool
/usr/java/jdk1.8.0_65/bin/keytool

sudo -E su
cd /etc/pki/ca-trust/extracted/java/

grape -d install org.spockframework spock-core 1.0-groovy-2.4

**チュートリアル**

http://koji-k.github.io/groovy-tutorial/unit-test/index.html

@Grab(group='org.spockframework', module='spock-core', version='1.0-groovy-2.4')


groovy spock1.groovy
JUnit 4 Runner, Tests: 1, Failures: 0, Time: 224

**gradle**

http://d.hatena.ne.jp/bluepapa32/20110601/1306930304

mkdir spock-test
gradle init --type groovy-library

gradle test --info しないとテスト結果がログ出力されない

> There were failing tests. See the report at: file:///home/psadmin/work/gradle/spock-test/build/reports/tests/index.html

HTMLで確認が必要

クラスローダープロト
-----------------------

ラップアップ

src/main/groovy の下は、javaの流儀に従った方が無難。 

package jp.co.toshiba.ITInfra.acceptance なら、jp/co/toshiba/ITInfra/acceptanceの下にソースコード配置

ベース

src/main/groovy/jp/co/toshiba/ITInfra/acceptance/Library.groovy 内

package jp.co.toshiba.ITInfra.acceptance

class Library {
    boolean libTest() {
        def url = './test/LinuxTest.groovy'
        GroovyClassLoader classLoader = new GroovyClassLoader()
        classLoader.addClasspath(".")
        Class clazz = classLoader.parseClass(new File(url))
        if (clazz != null) {
            Object test = clazz.newInstance(ip : '192.168.10.10')
            test.run_test()
        }
        return true
    }
}

ユーザカスタマイズ

test/LinuxTest.groovy

package com.example.acceptance
import jp.co.toshiba.ITInfra.acceptance.*

class LinuxTest  extends TestItem {
	String server = 'localhost'
	String ip     = '127.0.0.1'

    def myField = 'foo'
    def test_uname(myArg) {
        println "parent: ${num}"
    	println "Test1 : $myField $myArg $ip"
    }

    def test_os(myArg) {
    	println "Test2 : $myField $myArg $ip"
    }

    def run_test() {
        println 'hello from GreetingTask'
        println 'test test test'
		this.metaClass.methods.each { method ->
			(method.name =~ /^test_(.+)$/).each {m0,m1->
		        method.invoke(this, m1)
            }
		}
    }
}

テストコード

src/test/groovy/LibraryTest.groovy

import spock.lang.Specification
import jp.co.toshiba.ITInfra.acceptance.*

class LibraryTest extends Specification{
 
    def "someLibraryMethod returns true"() {
        setup:
        Library lib = new Library()
        when:
        def result = lib.libTest()
        then:
        result == true
    }

    def "someItemMethod returns true"() {
        setup:
        TestItem item = new TestItem()
        when:
        def result = item.test1()
        then:
        result == 1
    }
}

実行結果

gradle test
BUILD SUCCESSFUL

CLI
=============

http://qiita.com/informationsea/items/cd1d8d130a5c7b0bc31a

build.gradle に以下を追加


jar {
  manifest {
    attributes 'Implementation-Title': 'Mychael Style Tools', 'Implementation-Version': 1.0 
    attributes "Main-Class" : "jp.co.toshiba.ITInfra.acceptance.TestItem"
  }
  from configurations.compile.collect { it.isDirectory() ? it : zipTree(it) }
}

gradle jar
java -jar ./build/libs/spock-test.jar

以上、

