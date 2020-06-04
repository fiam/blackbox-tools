include(ExternalProject)

find_program(MESON meson)
if(NOT MESON)
    message(FATAL_ERROR "Failed to find meson, which is required to build bundled dependencies")
endif()

find_program(NINJA ninja)
if(NOT NINJA)
    message(FATAL_ERROR "Failed to find ninja, which is required to build bundled dependencies")
endif()

find_program(SH sh)
if(NOT SH)
    message(FATAL_ERROR "Failed to find sh")
endif()
if(WIN32)
# If SH has spaces in its path, Makefiles invoking $SHELL
# will fail (like pkg-config's does). To avoid this, we
# copy the binary to our path (which we can control and avoid
# spaces)
    set(SH "C:\\msys64\\usr\\bin\\bash.exe")
    #file(COPY ${SH} DESTINATION ${CMAKE_CURRENT_BINARY_DIR})
    #get_filename_component(basename ${SH} NAME)
    #set(SH ${CMAKE_CURRENT_BINARY_DIR}/${basename})
    #message("-- using shell ${SH}")
endif()

set(DEPS_INSTALL_PREFIX ${CMAKE_CURRENT_BINARY_DIR}/deps)
set(DEPS_BIN_DIR ${DEPS_INSTALL_PREFIX}/bin)
set(DEPS_INCLUDE_DIR ${DEPS_INSTALL_PREFIX}/include)
set(DEPS_LIB_DIR ${DEPS_INSTALL_PREFIX}/lib)
if(WIN32)
    set(PATH_LIST_SEPARATOR ";")
else()
    set(PATH_LIST_SEPARATOR ":")
endif()
set(DEPS_PATH "${DEPS_BIN_DIR}${PATH_LIST_SEPARATOR}$ENV{PATH}")
set(DEPS_CMAKE_ARGS
    -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_OSX_DEPLOYMENT_TARGET=${OSX_DEPLOYMENT_TARGET}
    -DCMAKE_INSTALL_PREFIX=${DEPS_INSTALL_PREFIX}
)

set(DEPS_CFLAGS "")
set(DEPS_LDFLAGS "")

set(PKG_CONFIG_PATH ${DEPS_LIB_DIR}/pkgconfig)
if (NOT ENV${PKG_CONFIG_PATH} STREQUAL "")
    set(PKG_CONFIG_PATH "${PKG_CONFIG_PATH}${PATH_LIST_SEPARATOR}ENV${PKG_CONFIG_PATH}")
endif()
if (UNIX AND NOT APPLE)
    set(PKG_CONFIG_PATH "${PKG_CONFIG_PATH}${PATH_LIST_SEPARATOR}/usr/lib/x86_64-linux-gnu/pkgconfig/")
endif()

set(DEPS_MESON_OPTIONS
    --pkg-config-path=${PKG_CONFIG_PATH}
    --prefix=${DEPS_INSTALL_PREFIX}
    --libdir=${DEPS_LIB_DIR}
    --buildtype=release
    --default-library=static
)

if (APPLE)
    set(DEPS_CFLAGS "${DEPS_CFLAGS} -mmacosx-version-min=${CMAKE_OSX_DEPLOYMENT_TARGET}")
    set(DEPS_LDFLAGS "${DEPS_LDFLAGS} -mmacosx-version-min=${CMAKE_OSX_DEPLOYMENT_TARGET}")
endif()

# zlib

set(ZLIB_SOURCE_DIR ${CMAKE_CURRENT_BINARY_DIR}/zlib)

ExternalProject_Add(zlib
    URL https://zlib.net/zlib-1.2.11.tar.gz
    URL_HASH SHA1=e6d119755acdf9104d7ba236b1242696940ed6dd
    LOG_DOWNLOAD ON
    SOURCE_DIR ${ZLIB_SOURCE_DIR}
    CONFIGURE_COMMAND ${CMAKE_COMMAND} -E env
        CFLAGS=${DEPS_CFLAGS}
        LDFLAGS=${DEPS_LDFLAGS}
        ${SH} ${ZLIB_SOURCE_DIR}/configure
        --prefix=${DEPS_INSTALL_PREFIX}
    BUILD_COMMAND ${CMAKE_MAKE_PROGRAM}
    INSTALL_COMMAND ${CMAKE_MAKE_PROGRAM} install
)

# pkg-config

set(PKG_CONFIG_SOURCE_DIR ${CMAKE_CURRENT_BINARY_DIR}/pkg-config)

set(PKG_CONFIG_LDFLAGS ${DEPS_LDFLAGS})
if(APPLE)
    set(PKG_CONFIG_LDFLAGS "${PKG_CONFIG_LDFLAGS} -Wl,-framework,CoreFoundation -Wl,-framework,Carbon")
endif()

ExternalProject_Add(pkg-config
    URL http://pkgconfig.freedesktop.org/releases/pkg-config-0.29.2.tar.gz
    URL_HASH SHA1=76e501663b29cb7580245720edfb6106164fad2b
    LOG_DOWNLOAD ON
    SOURCE_DIR ${PKG_CONFIG_SOURCE_DIR}
    CONFIGURE_COMMAND ${CMAKE_COMMAND} -E env
        CFLAGS=${DEPS_CFLAGS}
        LDFLAGS=${PKG_CONFIG_LDFLAGS}
        ${SH} ${PKG_CONFIG_SOURCE_DIR}/configure
        --srcdir=${PKG_CONFIG_SOURCE_DIR}
        --prefix=${DEPS_INSTALL_PREFIX}
        --with-internal-glib
    BUILD_COMMAND ${CMAKE_MAKE_PROGRAM}
    INSTALL_COMMAND ${CMAKE_MAKE_PROGRAM} install
)

# glib

set(GLIB_SOURCE_DIR ${CMAKE_CURRENT_BINARY_DIR}/glib)
set(GLIB_MESON_OPTIONS
    ${DEPS_MESON_OPTIONS}
)

ExternalProject_Add(glib
    URL https://ftp.gnome.org/pub/gnome/sources/glib/2.64/glib-2.64.3.tar.xz
    URL_HASH SHA1=0c14c207c7a35c37f9d3e51d45ed8a8aa03cb48d
    LOG_DOWNLOAD ON
    SOURCE_DIR ${GLIB_SOURCE_DIR}
    CONFIGURE_COMMAND
        ${CMAKE_COMMAND} -E env
        PATH=${DEPS_PATH}
        CFLAGS=${DEPS_CFLAGS}
        LDFLAGS=${DEPS_LDFLAGS}    
        ${MESON} "<SOURCE_DIR>" ${GLIB_MESON_OPTIONS}
        COMMAND
        ${MESON} configure ${GLIB_MESON_OPTIONS}
    BUILD_COMMAND ${NINJA}
    INSTALL_COMMAND ${NINJA} install
)

# png

set(PNG_CMAKE_ARGS
    -DCMAKE_C_FLAGS=-I${DEPS_INCLUDE_DIR}
    -DPNG_STATIC=ON
    -DPNG_SHARED=OFF
    -DPNG_TESTS=OFF
    ${DEPS_CMAKE_ARGS}
)

set(PNG_LIB ${DEPS_LIB_DIR}/${CMAKE_STATIC_LIBRARY_PREFIX}png${CMAKE_STATIC_LIBRARY_SUFFIX})

ExternalProject_Add(png
    URL https://download.sourceforge.net/libpng/libpng-1.6.37.tar.xz
    URL_HASH SHA1=3ab93fabbf4c27e1c4724371df408d9a1bd3f656
    LOG_DOWNLOAD ON
    CMAKE_ARGS ${PNG_CMAKE_ARGS}
    DEPENDS zlib
)

# pixman

set(PIXMAN_SOURCE_DIR ${CMAKE_CURRENT_BINARY_DIR}/pixman)
set(PIXMAN_LIB ${DEPS_LIB_DIR}/${CMAKE_STATIC_LIBRARY_PREFIX}pixman-1${CMAKE_STATIC_LIBRARY_SUFFIX})
set(PIXMAN_MESON_OPTIONS
    ${DEPS_MESON_OPTIONS}
)

ExternalProject_Add(pixman
    URL https://www.cairographics.org/releases/pixman-0.40.0.tar.gz
    URL_HASH SHA1=d7baa6377b6f48e29db011c669788bb1268d08ad
    LOG_DOWNLOAD ON
    SOURCE_DIR ${PIXMAN_SOURCE_DIR}
    # The tests fail to link on macOS and we don't want to
    # compile them anyway. Since there's no provided flag
    # to disable them, we just replace tests/meson.build
    # with an empty file
    PATCH_COMMAND
        ${CMAKE_COMMAND} -E remove -f "<SOURCE_DIR>/test/meson.build"
        COMMAND 
        ${CMAKE_COMMAND} -E touch "<SOURCE_DIR>/test/meson.build"
    CONFIGURE_COMMAND
        ${CMAKE_COMMAND} -E env
        CFLAGS=${DEPS_CFLAGS}
        LDFLAGS=${DEPS_LDFLAGS}    
        ${MESON} "<SOURCE_DIR>" ${PIXMAN_MESON_OPTIONS}
        COMMAND
        ${MESON} configure ${PIXMAN_MESON_OPTIONS}
    BUILD_COMMAND ${NINJA}
    INSTALL_COMMAND ${NINJA} install
    DEPENDS pkg-config glib png
)

# freetype2

set(FREETYPE_INCLUDE_DIR ${DEPS_INCLUDE_DIR}/freetype2)
set(FREETYPE_LIB ${DEPS_INSTALL_PREFIX}/lib/${CMAKE_STATIC_LIBRARY_PREFIX}freetype${CMAKE_STATIC_LIBRARY_SUFFIX})
set(FREETYPE_CMAKE_ARGS
    -DCMAKE_DISABLE_FIND_PACKAGE_HarfBuzz=ON
    -DCMAKE_DISABLE_FIND_PACKAGE_ZLIB=ON
    -DCMAKE_DISABLE_FIND_PACKAGE_BZip2=ON
    ${DEPS_CMAKE_ARGS}
)

ExternalProject_Add(freetype
    URL https://download.savannah.gnu.org/releases/freetype/freetype-2.10.0.tar.gz
    URL_HASH SHA1=bf36aa9e967dfa6e99424f889399636feeebac1f
    LOG_DOWNLOAD ON
    CMAKE_ARGS ${FREETYPE_CMAKE_ARGS}
    DEPENDS png
)

# cairo

set(CAIRO_SOURCE_DIR ${CMAKE_CURRENT_BINARY_DIR}/cairo)
set(CAIRO_INCLUDE_DIR ${DEPS_INCLUDE_DIR}/cairo)
set(CAIRO_LIB ${DEPS_LIB_DIR}/${CMAKE_STATIC_LIBRARY_PREFIX}cairo${CMAKE_STATIC_LIBRARY_SUFFIX})

set(CAIRO_CFLAGS
    "-I${FREETYPE_INCLUDE_DIR}"
    ${DEPS_CFLAGS}
)

set(sed "sed" "-i")
if (APPLE)
    set(sed "sed" "-i''")
endif()

set(CAIRO_FREETYPE_LIBS "")

if(UNIX AND NOT APPLE)
    # In Linux, we need to pass libfreetype.a to cairo,
    # otherwise we get undefined symbols while building
    # libcairo.a
    # However, on macOS we can't pass libfreetype.a because
    # it will be added as an object inside libcairo.a and
    # then clang will consider it an invalid library.
    set(CAIRO_FREETYPE_LIBS ${FREETYPE_LIB})
endif()

ExternalProject_Add(cairo
    URL https://cairographics.org/snapshots/cairo-1.17.2.tar.xz
    URL_HASH SHA1=c5d6f12701f23b2dc2988a5a5586848e70e858fe
    LOG_DOWNLOAD ON
    SOURCE_DIR ${CAIRO_SOURCE_DIR}
    PATCH_COMMAND
        ${sed} "s/am__append_1 = boilerplate test perf/am__append_1 = /"
        "${CAIRO_SOURCE_DIR}/Makefile.in"
    CONFIGURE_COMMAND ${CMAKE_COMMAND} -E env
        PATH=${DEPS_PATH}
        FREETYPE_CFLAGS=-I${FREETYPE_INCLUDE_DIR}
        FREETYPE_LIBS=${CAIRO_FREETYPE_LIBS}
        PKG_CONFIG_PATH=${PKG_CONFIG_PATH}
        CFLAGS=${CAIRO_CFLAGS}
        LDFLAGS=${DEPS_LDFLAGS}
        ${SH} ${CAIRO_SOURCE_DIR}/configure
        --srcdir=${CAIRO_SOURCE_DIR}
        --prefix=${DEPS_INSTALL_PREFIX}
        --enable-static=yes
        --disable-shared
        --enable-quartz=no
        --enable-quartz-font=no
        --enable-quartz-image=no
    BUILD_COMMAND ${CMAKE_MAKE_PROGRAM}
    INSTALL_COMMAND ${CMAKE_MAKE_PROGRAM} install
    DEPENDS pkg-config png pixman freetype
)

set(CAIRO_LIBS
    ${CAIRO_LIB}
    ${PIXMAN_LIB}
    ${PNG_LIB}
)
if (UNIX)
    # Since zlib is installed by default on basically
    # every Linux distro and macOS, we always link
    # to it dynamically
    list(APPEND CAIRO_LIBS -lz)
endif()
set(FREETYPE_LIBS
    ${FREETYPE_LIB}
)
