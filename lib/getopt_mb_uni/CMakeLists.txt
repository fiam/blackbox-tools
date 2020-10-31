add_library(getopt EXCLUDE_FROM_ALL getopt.c getopt.h)
target_include_directories(getopt PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})