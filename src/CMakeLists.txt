set(COMMON_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/parser.c
    ${CMAKE_CURRENT_SOURCE_DIR}/tools.c
    ${CMAKE_CURRENT_SOURCE_DIR}/platform.c
    ${CMAKE_CURRENT_SOURCE_DIR}/stream.c
    ${CMAKE_CURRENT_SOURCE_DIR}/decoders.c
    ${CMAKE_CURRENT_SOURCE_DIR}/units.c
    ${CMAKE_CURRENT_SOURCE_DIR}/blackbox_fielddefs.c

    PARENT_SCOPE
)

set(DECODER_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/blackbox_decode.c
    ${CMAKE_CURRENT_SOURCE_DIR}/gpxwriter.c
    ${CMAKE_CURRENT_SOURCE_DIR}/imu.c
    ${CMAKE_CURRENT_SOURCE_DIR}/battery.c
    ${CMAKE_CURRENT_SOURCE_DIR}/stats.c

    PARENT_SCOPE
)

set(RENDER_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/blackbox_render.c
    ${CMAKE_CURRENT_SOURCE_DIR}/datapoints.c
    ${CMAKE_CURRENT_SOURCE_DIR}/embeddedfont.c
    ${CMAKE_CURRENT_SOURCE_DIR}/expo.c
    ${CMAKE_CURRENT_SOURCE_DIR}/imu.c

    PARENT_SCOPE
)

set(TESTBED_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/encoder_testbed.c
    ${CMAKE_CURRENT_SOURCE_DIR}/encoder_testbed_io.c

    PARENT_SCOPE
)
