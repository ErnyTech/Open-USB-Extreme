cmake_minimum_required(VERSION 2.8.9)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/cmake/cmake-d")
project(Open-USB-Extreme D)

file(GLOB SOURCES "lib/*.d")
file(GLOB HEADERS "include/*.h" "include/*.di")
file(GLOB EXAMPLE_SOURCES "examples/*.d")

include_directories(include)

set(CMAKE_D_FLAGS "${CMAKE_D_FLAGS} -betterC -O -release -L-rpath=.")
add_library(${PROJECT_NAME} SHARED ${SOURCES})
add_executable(open-usbextreme-example ${EXAMPLE_SOURCES})
target_link_libraries(open-usbextreme-example ${PROJECT_NAME})

install(TARGETS ${PROJECT_NAME}
        LIBRARY DESTINATION lib
)

INSTALL(FILES ${HEADERS}
        DESTINATION include
)

INSTALL(TARGETS open-usbextreme-example
        RUNTIME DESTINATION bin
)
