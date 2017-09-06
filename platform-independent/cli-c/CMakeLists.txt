project(mpw C)
cmake_minimum_required(VERSION 3.0.2)

set(CMAKE_BUILD_TYPE Release)
set(CMAKE_C_FLAGS "-O3 -DMPW_SODIUM=1 -DMPW_JSON=1")

include_directories(core cli)
file(GLOB SOURCES "core/*.c" "cli/mpw-cli*.c")
add_executable(mpw ${SOURCES})

find_library(libsodium REQUIRED)
find_library(libjson-c REQUIRED)
target_link_libraries(mpw sodium json-c)
