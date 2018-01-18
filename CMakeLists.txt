# Copyright 2018, alex at staticlibs.net
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

cmake_minimum_required ( VERSION 2.8.12 )

# nmon tool
add_custom_command ( OUTPUT nmon
        COMMAND make nmon_x86_ubuntu1604
        COMMAND mv nmon_x86_ubuntu1604 ${CMAKE_CURRENT_BINARY_DIR}/nmon
        WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}/tools/nmon
        COMMENT "Compiling nmon tool ..." )
add_custom_target( nmontool DEPENDS nmon )

# nmonvisualizer tool
add_custom_command ( OUTPUT nmonvis.jar
        COMMAND bash ${WILTON_DIR}/tools/ant/bin/ant
        COMMAND mv NMONVisualizer_*.jar ${CMAKE_CURRENT_BINARY_DIR}/nmonvis.jar
        WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}/tools/nmonvisualizer
        COMMENT "Compiling nmonvisualizer tool ..." )
add_custom_target( nmonvis DEPENDS nmonvis.jar )

# wrk tool
# libluajit-5.1-dev is required to build wrk
add_custom_command ( OUTPUT wrk
        COMMAND make WITH_LUAJIT=/usr WITH_OPENSSL=/usr
        COMMAND mv wrk ${CMAKE_CURRENT_BINARY_DIR}/wrk
        WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}/tools/wrk
        COMMENT "Compiling wrk tool ..." )
add_custom_target( wrktool DEPENDS wrk )

# go sample
add_custom_command ( OUTPUT golang_server
        COMMAND go build server.go
        COMMAND mv server ${CMAKE_CURRENT_BINARY_DIR}/golang_server
        WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}/samples/golang
        COMMENT "Compiling golang sample server ..." )
add_custom_target( golang DEPENDS golang_server )

# c sample
add_subdirectory ( samples/wilton_c )

configure_file (
    ${CMAKE_CURRENT_LIST_DIR}/resources/config.json
    ${CMAKE_CURRENT_BINARY_DIR}/config.json )

add_custom_target ( bench
        COMMAND ../wilton_${WILTON_VERSION}/bin/wilton
                ${CMAKE_CURRENT_LIST_DIR}/scripts/bench.js --
                ${CMAKE_CURRENT_BINARY_DIR}/config.json
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
        DEPENDS dist nmontool nmonvis wrktool golang bench_wilton_c
        COMMENT "Running benchmarks ..." )

add_custom_target ( bench_scripting
        COMMAND rm -rf data
        COMMAND mkdir data

        # wilton_js
        COMMAND ${WILTON_DIR}/bench/scripts/test_runner/server_test.sh --
                ${CMAKE_BINARY_DIR}/wilton_${WILTON_VERSION}/bin
                wilton
                "${WILTON_DIR}/bench/samples/wilton_js/server.js -s app"
                data/wilton_js
                ${WILTON_DIR}/bench/tools/wrk
                ${WILTON_DIR}/bench/scripts/test_runner/wrk_test_params.txt
        COMMAND ${WILTON_DIR}/bench/scripts/test_data_handler/run_handler.sh
                data/wilton_js

        # wilton_c
        COMMAND ${WILTON_DIR}/bench/scripts/test_runner/server_test.sh --
                ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}
                bench_wilton_c
                "2"
                data/wilton_c
                ${WILTON_DIR}/bench/tools/wrk
                ${WILTON_DIR}/bench/scripts/test_runner/wrk_test_params.txt
        COMMAND ${WILTON_DIR}/bench/scripts/test_data_handler/run_handler.sh
                data/wilton_c

        # node
        COMMAND ${WILTON_DIR}/bench/scripts/test_runner/server_test.sh --
                $ENV{NODE_HOME}/bin
                node
                "${WILTON_DIR}/bench/samples/node/server.js"
                data/node
                ${WILTON_DIR}/bench/tools/wrk
                ${WILTON_DIR}/bench/scripts/test_runner/wrk_test_params.txt
        COMMAND ${WILTON_DIR}/bench/scripts/test_data_handler/run_handler.sh
                data/node

        # golang
        COMMAND ${WILTON_DIR}/bench/scripts/test_runner/server_test.sh --
                ${CMAKE_CURRENT_BINARY_DIR}
                golang_server
                "foo"
                data/golang
                ${WILTON_DIR}/bench/tools/wrk
                ${WILTON_DIR}/bench/scripts/test_runner/wrk_test_params.txt
        COMMAND ${WILTON_DIR}/bench/scripts/test_data_handler/run_handler.sh
                data/golang

        # plot
        COMMAND ${WILTON_DIR}/bench/scripts/histogram_constructor/finder.sh
                requests
                data
        COMMAND ${WILTON_DIR}/bench/scripts/histogram_constructor/unite.sh
                requests
                data
                --clean

        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
        DEPENDS dist wrktool golang bench_wilton_c
        COMMENT "Running benchmarks ..." )

