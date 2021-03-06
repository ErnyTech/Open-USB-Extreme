cmake_minimum_required(VERSION 2.8.9)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/cmake/cmake-d")
project(Open-USB-Extreme C D)
enable_testing()

file(GLOB SOURCES "lib/*.d")
file(GLOB PUB_SOURCES
        "lib/usbextreme.d"
)

file(GLOB HEADERS "include/*.h" "include/*.di")
file(GLOB EXAMPLE_SOURCES "examples/*.d")

include_directories(include)

set(CMAKE_D_FLAGS "${CMAKE_D_FLAGS} -betterC -O -release -L-rpath=.")
add_library(generate_header SHARED ${PUB_SOURCES})
target_compile_options(generate_header PRIVATE "-Hd=${CMAKE_SOURCE_DIR}/include")

add_library(${PROJECT_NAME} SHARED ${SOURCES})

add_executable(open-usbextreme-example ${EXAMPLE_SOURCES})
target_link_libraries(open-usbextreme-example ${PROJECT_NAME})

add_executable(cabitest "tests/cabitest.c")
target_link_libraries(cabitest ${PROJECT_NAME})
add_test(NAME CABI_TEST COMMAND cabitest /home/erny/Desktop/ul.cfg)

install(TARGETS ${PROJECT_NAME}
        LIBRARY DESTINATION lib
)

INSTALL(FILES ${HEADERS}
        DESTINATION include
)

INSTALL(TARGETS open-usbextreme-example
        RUNTIME DESTINATION bin
)
