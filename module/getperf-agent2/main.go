package main

import (
	// "crypto/tls"
	"log"
	"time"

	"github.com/hooklift/gowsdl/soap"
	"github.com/getperf/module/getperf-agent2/getperfservice"
)

func ExampleBasicUsage() {
	client := soap.NewClient(
		"http://svc.asmx",
		soap.WithTimeout(time.Second*5),
		// soap.WithBasicAuth("usr", "psw"),
		// soap.WithTLS(&tls.Config{InsecureSkipVerify: true}),
	)
	// client := soap.NewClient("http://svc.asmx")
	service := getperfservice.NewGetperfServicePortType(client)
	reply, err := service.GetLatestBuild(&getperfservice.GetLatestBuild{})
	if err != nil {
		log.Fatalf("could't get trade prices: %v", err)
	}
	log.Println(reply)
}

func main() {
	ExampleBasicUsage()
}
// func ExampleWithOptions() {
// 	client := soap.NewClient(
// 		"http://svc.asmx",
// 		soap.WithTimeout(time.Second*5),
// 		soap.WithBasicAuth("usr", "psw"),
// 		soap.WithTLS(&tls.Config{InsecureSkipVerify: true}),
// 	)
// 	service := gen.NewStockQuotePortType(client)
// 	reply, err := service.GetLastTradePrice(&gen.TradePriceRequest{})
// 	if err != nil {
// 		log.Fatalf("could't get trade prices: %v", err)
// 	}
// 	log.Println(reply)
// }

