package main

import (
	"bytes"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"io/ioutil"
	"net/http"
	"os"
	"strings"
	"sync"
	"time"
)

var wg = sync.WaitGroup{}

// assigned from command args
var port, url string

//var maxtime time.Duration

func createFile(filename string, contents io.Reader) {
	//fmt.Printf("file: %s\n", filename)
	f, err := os.Create(filename)
	if err != nil {
		panic(err)
	}
	defer f.Close()

	// copy to the file
	if _, err := io.Copy(f, contents); err != nil {
		panic(err)
	}
}

// type for error responses
type Response struct {
	Err     string `json:"error"`
	Value   string `json:"value"`
	Content string `json:"content"`
}

// type for status
type Status struct {
	R Response `json:"response"`
}

// newStatus creates a new Status with err and value
func newStatus(err, value, content string) Status {
	return Status{Response{err, value, content}}
}

// jSONError encoding status into json
// for example:
// {
//    "response" : {
//       "value"   : "FAIL",
//       "error"   : "Timeout connecting to host"
//       "content" : "503 Bad Gateway"
//    }
// }
func jSONError(s Status) *bytes.Buffer {
	b, err := json.Marshal(s)
	if err != nil {
		panic(err)
	}
	return bytes.NewBuffer(b)
}

func get(prefix string, host string, finishedChan <-chan bool) {
	//fmt.Printf("url:%s\n",url)
	defer wg.Done()
	defer func() { <-finishedChan }()

	// build the url
	//fmt.Printf("get: prefix:%s host:%s port:%s url:%s\n", prefix, host, port, url)
	s := []string{prefix, host, ":", port, url}
	uri := strings.Join(s, "")
	controller := strings.Split(url, "/")
	filename := fmt.Sprintf("%s-%s.json", host, controller[2])

	// issue the request in a child goroutine to handle timing out
	reqchan := make(chan bool)
	go func() {
		// close the reqchan on the way out to wake up the timeout select
		defer func() { close(reqchan) }()

		// issue the request
		resp, err := http.Get(uri)
		if err != nil {
			fmt.Printf("timeout connecting to: %s\n err:%s", uri, err)
			createFile(filename, jSONError(newStatus("Could not connect to host", "FAIL", err.Error())))
			return
		}

		defer resp.Body.Close()

		buf, err := ioutil.ReadAll(resp.Body)

		if err != nil {
			panic(err)
		}

		if resp.StatusCode != 200 {
			createFile(filename, jSONError(newStatus("not a 200", resp.Status, (string)(buf))))
			return
		}

		var i interface{}
		// try to decode the json received

		err = json.Unmarshal(buf, &i)
		if err != nil {
			createFile(filename, jSONError(newStatus("invalid JSON", "FAIL", (string)(buf))))
		}
		// create the file to write to
		createFile(filename, bytes.NewBuffer(buf))
	}()

	select {
	case <-time.After(4 * time.Second):
		createFile(filename, jSONError(newStatus("Timeout connecting to host", "FAIL", "")))
		fmt.Printf("timeout connecting to: %s\n", uri)
	case <-reqchan:
	}
}

func main() {
	var serverlist string
	var concurrency int
	//var maxtime time.Duration

	flag.IntVar(&concurrency, "c", 1, "number of parallel requests")
	//flag.DurationVar(&maxtime, "t", 10, "number of seconds to wait before timing out")
	flag.StringVar(&port, "p", "44444", "default pinky port")
	flag.StringVar(&url, "u", "/pinky/disk", "url to hit")
	flag.StringVar(&serverlist, "s", "./servers.txt", "List of servers to hit")
	flag.Parse()

	// validation
	if concurrency < 1 {
		fmt.Print("ERROR: Concurrency must be > 1\n")
		os.Exit(1)
		return // safety thing
	}
	if strings.Count(url, "/") < 2 {
		fmt.Print("ERROR: The URI must be two part, eg /pinky/disk, with at least two slashes")
		os.Exit(1)
		return // safety thing
	}

	// read the server list
	fileBytes, err := ioutil.ReadFile(serverlist)
	if err != nil {
		panic(err)
	}

	// use a buffered channel for limiting concurrency... push into it at the
	// beginning of the for loop, have the goroutine read from it when it is
	// done... this wait the buffer will fill, then block until something
	// finishes
	concurrencyChan := make(chan bool, concurrency)

	// loop over the servers
	startTime := time.Now()
	for _, line := range strings.Split(string(fileBytes), "\n") {
		// skip blank lines
		if line == "" {
			continue
		}

		// block on the concurrency channel, or it can buffer to let us run
		concurrencyChan <- true

		// increment the waitgroup before the goroutine to avoid a race condition
		wg.Add(1)

		// download the file
		go get("http://", line, concurrencyChan)
	}

	// block until all downloads are finished
	wg.Wait()

	// print difference in time
	fmt.Printf("time used %s\n", time.Now().Sub(startTime))
}
