/*
 * Copyright 2018, alex at staticlibs.net
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package main

import (
    "encoding/json"
    "io"
    "net/http"
    "runtime"
)

func hello_handler(w http.ResponseWriter, r *http.Request) {
    io.WriteString(w, "hello")
}

func json_handler(w http.ResponseWriter, r *http.Request) {

    decoder := json.NewDecoder(r.Body)
    var obj map[string]interface{}
    err := decoder.Decode(&obj)
    if err != nil {
        panic(err)
    }
    defer r.Body.Close()

    obj["serverHello"] = "hello";

    resp, err := json.Marshal(obj)
    if err != nil {
        panic(err)
    }

    w.Write(resp)
}

func main() {
    runtime.GOMAXPROCS(8)
    http.HandleFunc("/app/views/hello", hello_handler)
    http.HandleFunc("/app/views/json", json_handler)
    println("Starting golang server ...");
    http.ListenAndServe(":8080", nil)
}
