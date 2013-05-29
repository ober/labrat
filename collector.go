package main

import (
	"errors"
	"flag"
	"fmt"
	"io/ioutil"
	"net/http"
	"time"
	"strings"
	"os"
)

var controller []string
var url string
var uri string
var port string
var serverlist string

func get(start, done chan bool, prefix string, host string, port string, url string) {
	fmt.Printf("get: prefix:%s host:%s port:%s url:%s\n",prefix,host,port,url)
	if host != "" {
		s := []string{ prefix,host,":",port, url}
		uri := strings.Join(s,"")
		err := errors.New("Error")
		var resp *http.Response
		for {
			<-start
			resp, err = http.Get(uri)
			if err != nil {
				fmt.Printf("XXX %v\n", err)
			} else {
				controller = strings.Split(url,"/")
				f := []string{ host, controller[2] }
				fmt.Printf("file: %s\n", strings.Join(f, "-"))
				fo,err := os.Create(strings.Join(f, "-"))
				if err != nil { panic(err) }
				defer func() {
					if err := fo.Close(); err != nil {
						panic(err)
					}
				}()
				//buf := make([]byte, 1024)
				buff,err := ioutil.ReadAll(resp.Body)
				for {
					if _, err := fo.Write(buff); err != nil {
						panic(err)
					}
				}

				//file, err := os.Open(
				resp.Body.Close()
			}
			done <- true
		}
	}
}

func main() {
	// c := flag.Int("c", 1, "number of parallel requests")
	port := flag.String("p", "44444", "default pinky port")
	url := flag.String("u", "/pinky/disk", "url to hit")
	serverlist := flag.String("s", "./servers.txt", "List of servers to hit")
	flag.Parse()

	fileBytes, err := ioutil.ReadFile(*serverlist)
	if err != nil {
		panic(err)
	}

	n := 0
	done := make(chan bool, n)
	start := make(chan bool, n)
	b := time.Now().Unix()
	for _, line := range strings.Split(string(fileBytes), "\n") {
		n++
		// Magic here.
	        go get(start, done, "http://", line, *port, *url)
		start <- true
	}
	<-done
	e := time.Now().Unix()
	fmt.Printf("time used %d\n", (e-b))
}
