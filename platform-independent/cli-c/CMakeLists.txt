project(mpw)
cmake_minimum_required(VERSION 3.0.2)

set(CMAKE_BUILD_TYPE Release)
set(CMAKE_C_FLAGS "-O3 -DHAS_SODIUM=1 -DMPW_SODIUM=1")

OPTION(USE_COLOR "Use lib curses for color output" ON)

include_directories(core cli)
file(GLOB SOURCES "core/*.c" "cli/mpw-cli.c")
add_executable(mpw ${SOURCES})

find_library(sodium REQUIRED)
find_library(json-c REQUIRED)

target_link_libraries(mpw sodium json-c)

if (USE_COLOR)
    find_library(curses REQUIRED)
    add_definitions(-DMPW_COLOR=1)
    target_link_libraries(mpw curses)
endif()
