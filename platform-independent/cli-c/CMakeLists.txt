project(mpw)
cmake_minimum_required(VERSION 3.0.2)

set(CMAKE_BUILD_TYPE Release)
set(CMAKE_C_FLAGS "-O3 -DHAS_SODIUM=1")

include_directories(core cli)
file(GLOB SOURCES "core/*.c" "cli/mpw-cli.c")
add_executable(mpw ${SOURCES})

find_library(libsodium REQUIRED)
target_link_libraries(mpw sodium)
