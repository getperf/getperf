package main

import (
	"fmt"
	"gopkg.in/ini.v1"
)

type Config struct{
	Port int
	Db string
	User string
}

var Cnf Config

func init(){
	c, _ := ini.Load("sample.ini")
	Cnf = Config{
		Port: c.Section("web").Key("port").MustInt(),
		Db: c.Section("db").Key("name").MustString("hogehoge.sql"),
		User: c.Section("db").Key("user").String(),
	}
}

func main(){
	fmt.Printf("%v \n", Cnf.Port)
	fmt.Printf("%v \n", Cnf.Db)
	fmt.Printf("%v \n", Cnf.User)
}
