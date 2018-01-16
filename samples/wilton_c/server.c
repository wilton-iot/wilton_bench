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

/* 
 * File:   server.c
 * Author: alex
 *
 * Created on January 5, 2018, 6:52 PM
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <jansson.h>

#include "wilton/wilton.h"
#include "wilton/wilton_server.h"
#include "wilton/wilton_logging.h"
#include "wilton/wilton_signal.h"

void check_err(char* err) {
    if (NULL != err) {
        puts(err);
        wilton_free(err);
        exit(1);
    }
}

void init_logging() {
    const char* conf = "{\
        \"appenders\": [{\
            \"appenderType\": \"CONSOLE\",\
            \"thresholdLevel\": \"WARN\" \
        }],\
        \"loggers\": []\
    }";
    char* err = wilton_logger_initialize(conf, (int) strlen(conf));
    check_err(err);
}

void hello_handler(void* ctx, wilton_Request* req) {
    (void) ctx;
    wilton_Request_send_response(req, "hello", 6);
}

void json_handler(void* ctx, wilton_Request* req) {
    (void) ctx;
    char* err;
    json_error_t jerr;
    
    char* data = NULL;
    int data_len = 0;
    err = wilton_Request_get_request_data(req, &data, &data_len);
    check_err(err);

    json_t* obj = json_loadb(data, data_len, 0, NULL);
    if (NULL == obj) {
        puts("JSON parse error");
        exit(1);
    }
    
    json_t* hello_val = json_string("hello");
    json_object_set(obj, "serverHello", hello_val);
    char* resp = json_dumps(obj, 0);
    
    wilton_Request_send_response(req, resp, strlen(resp));

    free(resp);
    json_decref(obj);
    json_decref(hello_val);
    wilton_free(data);
}

int main(int argc, char const *argv[]) {
    char* err;
    init_logging();

    // paths
    wilton_HttpPath* path_to_hello;
    err = wilton_HttpPath_create(&path_to_hello, "GET", (int) strlen("GET"), "/app/views/hello", (int) strlen("/app/views/hello"), NULL, hello_handler);
    check_err(err);
    wilton_HttpPath* path_to_json;
    err = wilton_HttpPath_create(&path_to_json, "POST", (int) strlen("POST"), "/app/views/json", (int) strlen("/app/views/json"), NULL, json_handler);
    check_err(err);

    // paths array
    const int paths_size = 2;
    int paths_counter = 0;
    wilton_HttpPath* paths[paths_size];
    paths[paths_counter++] = path_to_hello;
    paths[paths_counter++] = path_to_json;

    // server
    puts("Starting wilton_c server ...");

    char* server_conf_format = "{\
            \"numberOfThreads\": %s,\
            \"tcpPort\": 8080,\
            \"ipAddress\": \"127.0.0.1\"\
    }";

    char* threads_number = NULL;
    const int first_arg = 1;
    if (first_arg < argc) {
      threads_number = (char* ) argv[first_arg];
    } else {
      threads_number = "2"; 
    }

    char server_conf[512];
    int server_conf_len = sprintf(server_conf, server_conf_format, threads_number);

    wilton_Server* server;
    err = wilton_Server_create(&server, server_conf, server_conf_len, paths, paths_size);
    check_err(err);

    // signals
    err = wilton_signal_initialize();
    check_err(err);
    err = wilton_signal_await();
    check_err(err);

    err = wilton_Server_stop(server);
    check_err(err);
    err = wilton_HttpPath_destroy(path_to_hello);
    check_err(err);
    err = wilton_HttpPath_destroy(path_to_json);
    check_err(err);

    return 0;
}
