package main

import (
	"fmt"
	"os/exec"
	"time"
	"github.com/Songmu/timeout"
)

func main() {
	tio := &timeout.Timeout{
		Cmd: 	exec.Command("perl", "-E", "print 'Hello'"),
		Duration: 10 * time.Second,
		KillAfter: 5 * time.Second,
	}
	exitstatus, stdout, stderr, err := tio.Run()
	fmt.Println(exitstatus, stdout, stderr, err)
}