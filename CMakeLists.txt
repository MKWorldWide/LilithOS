# ============================================================================
# LilithOS PS Vita Native Build System (Quantum-Documented)
# ============================================================================
#
# This CMakeLists.txt is the root build configuration for LilithOS PS Vita VPKs.
# It orchestrates the build and packaging of all VPK subprojects in build_all_vpks/.
#
# Quantum Documentation:
# - Each subproject is a self-contained VPK (PS Vita app/game/daemon)
# - All subprojects are built using the official Vitasdk toolchain
# - LiveArea assets and manifests are packaged per VPK
# - Python-based VPKs are handled as data (not compiled)
# - All dependencies, build steps, and packaging are documented inline
#
# For full system context, see ARCHITECTURE.md and @docs/.
#
# Dependencies:
# - Vitasdk (https://vitasdk.org/)
# - CMake >= 3.16
# - Standard Unix build tools (make, bash, etc.)
#
# Usage Example:
#   mkdir build && cd build
#   cmake ..
#   make
#   # All VPKs will be built and placed in dist_vpks/
#
# Performance: Parallel build supported via make -jN
# Security: No network access required for build; VPKs are unsigned homebrew
# Changelog: See CHANGELOG.md
#
# ============================================================================

cmake_minimum_required(VERSION 3.16)
project(LilithOS-VPKs C)

# Vitasdk toolchain setup
if(NOT DEFINED ENV{VITASDK})
    message(FATAL_ERROR "VITASDK environment variable not set. Please install VitaSDK.")
endif()
set(VITA_SDK $ENV{VITASDK})
set(VITA_TOOLCHAIN ${VITA_SDK}/bin/arm-vita-eabi)
set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR arm)
set(CMAKE_C_COMPILER ${VITA_TOOLCHAIN}-gcc)
set(CMAKE_CXX_COMPILER ${VITA_TOOLCHAIN}-g++)
set(CMAKE_AR ${VITA_TOOLCHAIN}-ar)
set(CMAKE_RANLIB ${VITA_TOOLCHAIN}-ranlib)
set(CMAKE_STRIP ${VITA_TOOLCHAIN}-strip)
set(CMAKE_C_FLAGS "" CACHE STRING "" FORCE)
set(CMAKE_CXX_FLAGS "" CACHE STRING "" FORCE)
set(CMAKE_OSX_ARCHITECTURES "" CACHE STRING "" FORCE)
include_directories(
    ${VITA_SDK}/arm-vita-eabi/include
    ${VITA_SDK}/arm-vita-eabi/include/psp2
    ${VITA_SDK}/arm-vita-eabi/include/taihen
)
link_directories(${VITA_SDK}/arm-vita-eabi/lib)

# ============================================================================
# Subproject VPKs (Quantum-documented)
# ============================================================================
add_subdirectory(build_all_vpks/bootloader)
add_subdirectory(build_all_vpks/mesh)
add_subdirectory(build_all_vpks/whisperer)
add_subdirectory(build_all_vpks/memory)
add_subdirectory(build_all_vpks/voice)

# ============================================================================
# VPK Distribution Directory
# ============================================================================
file(MAKE_DIRECTORY ${CMAKE_BINARY_DIR}/dist_vpks)

# ============================================================================
# End of Root CMakeLists.txt
# ============================================================================