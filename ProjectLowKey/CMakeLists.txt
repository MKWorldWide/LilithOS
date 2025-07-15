cmake_minimum_required(VERSION 3.10)
project(ProjectLowKey)

set(CMAKE_TOOLCHAIN_FILE $ENV{VITASDK}/share/vita.toolchain.cmake)
set(VITA_APP_NAME "ProjectLowKey")
set(VITA_TITLEID  "LOKEY0001")
set(VITA_VERSION  "01.00")

add_subdirectory(src)
add_subdirectory(switcher_app)