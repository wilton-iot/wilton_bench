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

message ( STATUS "Compiling wrk tool ..." )
#execute_process ( COMMAND git clean -dxf
#        WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}/wrk )
execute_process ( COMMAND make WITH_LUAJIT=/usr WITH_OPENSSL=/usr
        WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}/wrk )
execute_process ( COMMAND mv wrk ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/wrk
        WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}/wrk )
message ( STATUS "Compiling wrk tool - done" )
