cmake_minimum_required(VERSION 2.8.9)
INCLUDE(CheckIncludeFile)
project(Open-USB-Extreme)
include_directories(include)
# check headers
check_include_file("stdint.h" HAVE_STDINT)
if (HAVE_STDINT)
  add_definitions(-DHAVE_STDINT)
endif()

check_include_file("stddef.h" HAVE_STDDEF)
if (HAVE_STDDEF)
  add_definitions(-DHAVE_STDDEF)
endif()

file(GLOB SOURCES "lib/*.c")
file(GLOB HEADERS "include/*.h")
file(GLOB EXAMPLE_SOURCES "examples/*.c")
set (CMAKE_CXX_STANDARD 89)
#set(CMAKE_C_FLAGS "-Wall -pedantic -Wextra -Werror")
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
