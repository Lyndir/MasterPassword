project( mpw-core C )
cmake_minimum_required( VERSION 3.0.0 )

add_library( mpw SHARED
    "${PROJECT_SOURCE_DIR}/../platform-independent/c/core/src/base64.c"
    "${PROJECT_SOURCE_DIR}/../platform-independent/c/core/src/aes.c"
    "${PROJECT_SOURCE_DIR}/../platform-independent/c/core/src/mpw-algorithm.c"
    "${PROJECT_SOURCE_DIR}/../platform-independent/c/core/src/mpw-types.c"
    "${PROJECT_SOURCE_DIR}/../platform-independent/c/core/src/mpw-util.c"
    "${PROJECT_SOURCE_DIR}/../platform-independent/c/core/src/mpw-marshal-util.c"
    "${PROJECT_SOURCE_DIR}/../platform-independent/c/core/src/mpw-marshal.c"
    "${PROJECT_SOURCE_DIR}/../platform-independent/c/core/src/mpw-jni.c" )

add_library( sodium SHARED IMPORTED )
set_target_properties( sodium PROPERTIES IMPORTED_LOCATION "${PROJECT_SOURCE_DIR}/../lib/libsodium/build-android~/out/lib/${ANDROID_ABI}/libsodium.so" )
target_include_directories( mpw PRIVATE "${PROJECT_SOURCE_DIR}/../lib/libsodium/build-android~/out" )
target_compile_definitions( mpw PRIVATE -DMPW_SODIUM=1 )
target_link_libraries( mpw PRIVATE sodium )

add_library( json-c SHARED IMPORTED )
set_target_properties( json-c PROPERTIES IMPORTED_LOCATION "${PROJECT_SOURCE_DIR}/../lib/libjson-c/build-android~/out/lib/${ANDROID_ABI}/libjson-c.so" )
target_include_directories( mpw PRIVATE "${PROJECT_SOURCE_DIR}/../lib/libjson-c/build-android~/out" )
target_compile_definitions( mpw PRIVATE -DMPW_JSON=1 )
target_link_libraries( mpw PRIVATE json-c )
