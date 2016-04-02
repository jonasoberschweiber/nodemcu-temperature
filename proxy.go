package main

import (
    "fmt"
    "net/http"
    "io/ioutil"
    "crypto/hmac"
    "crypto/sha256"
    "encoding/hex"
    "time"
    "strconv"
    "math"
    "strings"
)

func sendToLibrato(data string) {
    client := &http.Client {
    }
    lreq, _ := http.NewRequest("POST", "https://metrics-api.librato.com/v1/metrics", strings.NewReader(data))
    lreq.Header.Add("Content-Type", "application/x-www-form-urlencoded")
    lreq.Header.Add("Accept", "*/*")
    // Put your Librato credentials here
    lreq.SetBasicAuth("", "")
    client.Do(lreq)
}

func handler(w http.ResponseWriter, r *http.Request) {
    defer r.Body.Close()
    key := []byte("Your HMAC key goes here")
    body, _ := ioutil.ReadAll(r.Body)
    tstamp := r.FormValue("tstamp")
    auth := r.FormValue("auth")
    actualMAC, _ := hex.DecodeString(auth)
    mac := hmac.New(sha256.New, key)
    mac.Write([]byte(tstamp + "|" + string(body)))
    expectedMAC := mac.Sum(nil)
    if hmac.Equal(actualMAC, expectedMAC) {
        currentTime := time.Now().UTC().Unix()
        givenTime, _ := strconv.Atoi(tstamp)
        givenTimeF := float64(givenTime)
        currentTimeF := float64(currentTime)
        if math.Abs(givenTimeF - currentTimeF) < 5 * 60 {
            fmt.Printf("Received %s, forwarding to librato!", body)
            sendToLibrato(string(body))
        } else {
            fmt.Fprintf(w, "Time off!")
        }
    } else {
        fmt.Fprintf(w, "No auth!")
    }
}

func main() {
    http.HandleFunc("/", handler)
    http.ListenAndServe(":9090", nil)
}

