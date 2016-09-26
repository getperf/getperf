package com.example.acceptance
import org.hidetake.groovy.ssh.Ssh

class LinuxTest {
	String server = 'localhost'
	String ip     = '127.0.0.1'

    def myField = 'foo'
    def test_uname(myArg) {
    	println "Test1 : $myField $myArg $ip"
    }

    def test_os(myArg) {
    	println "Test2 : $myField $myArg $ip"
    }

    def run_test() {
        println 'hello from GreetingTask'
		this.metaClass.methods.each { method ->
			(method.name =~ /^test_(.+)$/).each {m0,m1->
		        method.invoke(this, m1)
            }
		}
    }
}
