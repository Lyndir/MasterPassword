### CMAKE
project( masterpassword-cli C )
cmake_minimum_required( VERSION 3.0.2 )


### CONFIGURATION
# Features.
option( USE_SODIUM              "Implement crypto functions with sodium (depends on libsodium)." ON )
option( USE_JSON                "Support JSON-based user configuration format (depends on libjson-c)." ON )
option( USE_COLOR               "Colorized identicon (depends on libncurses)." ON )
option( USE_XML                 "XML parsing (depends on libxml2)." ON )

option( BUILD_MPW               "C CLI version of Master Password (needs: mpw_sodium, optional: mpw_color, mpw_json)." ON )
option( BUILD_MPW_BENCH         "C CLI Master Password benchmark utility (needs: mpw_sodium)." OFF )
option( BUILD_MPW_TESTS         "C Master Password algorithm test suite (needs: mpw_sodium, mpw_xml)." OFF )

# Default build flags.
set( CMAKE_BUILD_TYPE           Release )
set( CMAKE_C_FLAGS              "-O3" )

# Version.
find_package( Git )
if( GIT_FOUND )
    execute_process( COMMAND    "${GIT_EXECUTABLE}" describe --match *-cli* --long --dirty
                     OUTPUT_VARIABLE mpw_version OUTPUT_STRIP_TRAILING_WHITESPACE )
endif()
if( NOT mpw_version MATCHES "." )
    file( READ                  "VERSION" mpw_version )
    string( STRIP               "${mpw_version}" mpw_version )
endif()
if( mpw_version MATCHES "." )
    add_definitions(            "-DMP_VERSION=${mpw_version}" )
    message( STATUS             "Current mpw source version ${mpw_version}..." )
else()
    message( STATUS             "Current mpw source version unknown..." )
endif()


### DEPENDENCIES
function( use_mpw_sodium t r )
    if( USE_SODIUM )
        target_link_libraries(  "${t}" PRIVATE sodium )
        target_compile_definitions( "${t}" PRIVATE -DMPW_SODIUM=1 )
        message( STATUS         "${t}: USE_SODIUM is enabled." )

    elseif( r STREQUAL "required" )
        message( FATAL_ERROR    "${t}: USE_SODIUM was required but is not enabled.  Please enable the option or remove this target." )

    else()
        message( STATUS         "${t}: USE_SODIUM is supported but not enabled." )

    endif()
endfunction()

function( use_mpw_color t )
    find_package( Curses )
    if( USE_COLOR )
        if ( CURSES_FOUND )
            target_include_directories( "${t}" PRIVATE ${CURSES_INCLUDE_DIR} )
            target_link_libraries( "${t}" PRIVATE ${CURSES_LIBRARIES} )
            target_compile_definitions( "${t}" PRIVATE -DMPW_COLOR=1 ${CURSES_DEFINITIONS} )
            message( STATUS     "${t}: USE_COLOR is enabled." )

        elseif( r STREQUAL "required" )
            message( FATAL_ERROR "${t}: USE_COLOR was enabled but is missing libcurses.  Please install this library before continuing." )

        else()
            message( WARNING    "${t}: USE_COLOR was enabled but is missing libcurses.  Will continue with USE_COLOR disabled!" )

        endif()

    elseif( r STREQUAL "required" )
        message( FATAL_ERROR    "${t}: USE_COLOR was required but is not enabled.  Please enable the option or remove this target." )

    else()
        message( STATUS         "${t}: USE_COLOR is supported but not enabled." )

    endif()
endfunction()

function( use_mpw_json t )
    if( USE_JSON )
        target_link_libraries(  "${t}" PRIVATE json-c )
        target_compile_definitions( "${t}" PRIVATE -DMPW_JSON=1 )
        message( STATUS         "${t}: USE_JSON is enabled." )

    elseif( r STREQUAL "required" )
        message( FATAL_ERROR    "${t}: USE_JSON was required but is not enabled.  Please enable the option or remove this target." )

    else()
        message( STATUS         "${t}: USE_JSON is supported but not enabled." )

    endif()
endfunction()

function( use_mpw_xml t r )
    find_package( LibXml2 )
    if( USE_XML )
        if ( LIBXML2_FOUND )
            target_include_directories( "${t}" PRIVATE ${LIBXML2_INCLUDE_DIR} )
            target_link_libraries( "${t}" PRIVATE ${LIBXML2_LIBRARIES} )
            target_compile_definitions( "${t}" PRIVATE -DMPW_XML=1 ${LIBXML2_DEFINITIONS} )
            message( STATUS     "${t}: USE_XML is enabled." )

        elseif( r STREQUAL "required" )
            message( FATAL_ERROR "${t}: USE_XML was enabled but is missing libxml2.  Please install this library before continuing." )

        else()
            message( WARNING    "${t}: USE_XML was enabled but is missing libxml2.  Will continue with USE_XML disabled!" )

        endif()

    elseif( r STREQUAL "required" )
        message( FATAL_ERROR    "${t}: USE_XML was required but is not enabled.  Please enable the option or remove this target." )

    else()
        message( STATUS         "${t}: USE_XML is supported but not enabled." )

    endif()
endfunction()


### TARGET: MPW
if( BUILD_MPW )
    # target
    add_executable( mpw "../core/src/base64.c" "../core/src/aes.c" "../core/src/mpw-algorithm.c"
                        "../core/src/mpw-algorithm_v0.c" "../core/src/mpw-algorithm_v1.c" "../core/src/mpw-algorithm_v2.c" "../core/src/mpw-algorithm_v3.c"
                        "../core/src/mpw-types.c" "../core/src/mpw-util.c" "../core/src/mpw-marshal-util.c" "../core/src/mpw-marshal.c"
                        "src/mpw-cli-util.c" "src/mpw-cli.c" )
    target_include_directories( mpw PUBLIC ../core/src src )
    install( TARGETS mpw RUNTIME DESTINATION bin )

    # dependencies
    use_mpw_sodium( mpw required )
    use_mpw_color( mpw optional )
    use_mpw_json( mpw optional )
endif()


### TARGET: MPW-BENCH
if( BUILD_MPW_BENCH )
    # target
    add_executable( mpw-bench "../core/src/base64.c" "../core/src/aes.c" "../core/src/mpw-algorithm.c"
                              "../core/src/mpw-algorithm_v0.c" "../core/src/mpw-algorithm_v1.c" "../core/src/mpw-algorithm_v2.c" "../core/src/mpw-algorithm_v3.c"
                              "../core/src/mpw-types.c" "../core/src/mpw-util.c" "src/mpw-bench.c" )
    target_include_directories( mpw-bench PUBLIC ../core/src src )
    install( TARGETS mpw-bench RUNTIME DESTINATION bin )

    # dependencies
    use_mpw_sodium( mpw-bench required )
endif()


### TARGET: MPW-TESTS
if( BUILD_MPW_TESTS )
    # target
    add_executable( mpw-tests "../core/src/base64.c" "../core/src/aes.c" "../core/src/mpw-algorithm.c"
                              "../core/src/mpw-algorithm_v0.c" "../core/src/mpw-algorithm_v1.c" "../core/src/mpw-algorithm_v2.c" "../core/src/mpw-algorithm_v3.c"
                              "../core/src/mpw-types.c" "../core/src/mpw-util.c" "src/mpw-tests-util.c" "src/mpw-tests.c" )
    target_include_directories( mpw-tests PUBLIC ../core/src src )
    install( TARGETS mpw-tests RUNTIME DESTINATION bin )

    # dependencies
    use_mpw_sodium( mpw-tests required )
    use_mpw_xml( mpw-tests required )
endif()
