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

# project
project ( bench_wilton_c_server CXX )

add_executable ( ${PROJECT_NAME} server.c )

target_include_directories ( ${PROJECT_NAME} BEFORE PRIVATE
        ${WILTON_DIR}/core/include
        ${WILTON_DIR}/modules/wilton_logging/include
        ${WILTON_DIR}/modules/wilton_signal/include
        ${WILTON_DIR}/modules/wilton_server/include )

target_link_libraries ( ${PROJECT_NAME} PRIVATE
        jansson
        wilton_core
        wilton_crypto
        wilton_loader
        wilton_logging
        wilton_server
        wilton_signal
        wilton_zip )
