
//クロージャ
def justDoIt2( Closure closure) {
	println "start"
	closure.call()
	println "end"
}

justDoIt2 { println "Hello, test!" }

// レキシカル変数
def createIdGenerator(prefix) {
	int counter = 1
	Closure c = {
		"${prefix}-${counter++}"
	}
	return c
}

def a = createIdGenerator("test")
println a()
println a()

// All-In-One Jarで groovy実行
// java -jar $GROOVY_HOME/embeddable/groovy-all-2.4.0.jar hello.groovy

// GExcelAPI

// PowerCLI

// jPowerShell

// AST変換

@Grab("log4j:log4j")
import groovy.util.logging.Log4j
@Log4j
class Sample {
	def doIt() {
		log.fatal "Hello"
	}
}

new Sample().doIt()
