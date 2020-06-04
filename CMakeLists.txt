cmake_minimum_required(VERSION 3.10)

project(blackbox-tools VERSION 0.4.4 LANGUAGES C)

# We need this extra variable because CMAKE_OSX_DEPLOYMENT_TARGET
# is empty until build time, but the arguments for the compiled
# in dependencies (in SDL2.cmake) are evaluated at cmake configure
# time, we need the minimum target set by the time the configuration
# step runs.
set(OSX_DEPLOYMENT_TARGET "10.10")
set(CMAKE_OSX_DEPLOYMENT_TARGET ${OSX_DEPLOYMENT_TARGET})

set(CMAKE_C_STANDARD 99) 
set(CMAKE_C_STANDARD_REQUIRED ON) 

set(USE_SYSTEM_LIBS_DEFAULT OFF)
if(UNIX AND NOT APPLE)
    set(USE_SYSTEM_LIBS_DEFAULT ON)
endif()

option(USE_SYSTEM_LIBS "Use system's SDL cairo and freetype instead of building our own" ${USE_SYSTEM_LIBS_DEFAULT})

add_subdirectory(src)

set(DECODE_TARGET blackbox_decode)
set(RENDER_TARGET blackbox_render)
set(TESTBED_TARGET encoder_testbed)


add_executable(${DECODE_TARGET} ${COMMON_SOURCES} ${DECODER_SOURCES})

add_executable(${RENDER_TARGET} ${COMMON_SOURCES} ${RENDER_SOURCES})

if(USE_SYSTEM_LIBS)
    find_package(PkgConfig REQUIRED)
    pkg_check_modules(cairo REQUIRED IMPORTED_TARGET cairo)
    pkg_check_modules(freetype2 REQUIRED IMPORTED_TARGET freetype2)
    target_link_libraries(${RENDER_TARGET} PUBLIC
        PkgConfig::cairo
        PkgConfig::freetype2)
else()
    include(cmake/deps.cmake)
    add_dependencies(${RENDER_TARGET} cairo freetype)
    target_include_directories(${RENDER_TARGET} PRIVATE
        ${CAIRO_INCLUDE_DIR} ${FREETYPE_INCLUDE_DIR})
    target_link_libraries(${RENDER_TARGET} PRIVATE
        ${CAIRO_LIBS} ${FREETYPE_LIBS})
endif()

add_executable(${TESTBED_TARGET} ${COMMON_SOURCES} ${TESTBED_SOURCES})

set(ALL_EXECUTABLES
    ${DECODE_TARGET}
    ${RENDER_TARGET}
    ${TESTBED_TARGET}
)

set(gnu_clang_options
    -Wall
    -Wextra
    -pedantic
    -Wno-gnu-zero-variadic-macro-arguments
    -Wno-gnu-folding-constant
    -Wno-gnu-statement-expression
    -Wno-padded
)
function(set_warning_options target)
endfunction()

foreach(exe ${ALL_EXECUTABLES})
    target_compile_options(${exe} PRIVATE
        $<$<C_COMPILER_ID:MSVC>:/W4>
        $<$<C_COMPILER_ID:GNU>:${gnu_clang_options}>
        $<$<C_COMPILER_ID:Clang>:${gnu_clang_options}>
        $<$<C_COMPILER_ID:AppleClang>:${gnu_clang_options}>
    )
    if (UNIX AND NOT APPLE)
        target_link_libraries(${exe} PRIVATE -lm -lpthread)
    endif()
endforeach()

if (CMAKE_C_COMPILER_ID STREQUAL "Clang" OR CMAKE_C_COMPILER_ID STREQUAL "AppleClang")
    option(USE_ADDRESS_SANITIZER "Use clang's address sanitizer")
    if(USE_ADDRESS_SANITIZER)
        message("-- using address sanitizer")
        set(SANITIZER_FLAGS "-fsanitize=address" "-g3" "-fno-omit-frame-pointer")
        foreach(exe ${ALL_EXECUTABLES})
            target_compile_options(${exe} PRIVATE ${SANITIZER_FLAGS})
            target_link_libraries(${exe} PRIVATE ${SANITIZER_FLAGS})
        endforeach()
    endif()
endif()

set(RELEASE_NAME "blackbox-tools-v${PROJECT_VERSION}")
if(WIN32)
    set(OS_NAME "win")
    set(RELEASE_ARCHIVE_FORMAT zip)
elseif(APPLE)
    set(OS_NAME "macOS")
    set(RELEASE_ARCHIVE_FORMAT zip)
else()
    set(OS_NAME "linux")
    set(RELEASE_ARCHIVE_FORMAT tar.gz)
endif()

if (USE_SYSTEM_LIBS)
    set(RELEASE_SUFFIX shared)
else()
    set(RELEASE_SUFFIX static)
endif()

set(RELEASE_FILENAME "${RELEASE_NAME}-${OS_NAME}-${RELEASE_SUFFIX}.${RELEASE_ARCHIVE_FORMAT}")

if(RELEASE_ARCHIVE_FORMAT STREQUAL zip)
    set(COMPRESS_CMD cmake -E tar cf ${RELEASE_FILENAME} --format=zip)
elseif(RELEASE_ARCHIVE_FORMAT STREQUAL tar.gz)
    set(COMPRESS_CMD cmake -E tar czf ${RELEASE_FILENAME})
else()
    message(FATAL_ERROR "can't create archive with format ${RELEASE_ARCHIVE_FORMAT}")
endif()

add_custom_target(release
    ${COMPRESS_CMD}

    $<TARGET_FILE:${DECODE_TARGET}>
    $<TARGET_FILE:${RENDER_TARGET}>

    BYPRODUCTS ${RELEASE_FILENAME}
)
