# ============================================================================
# LilithOS Bootloader VPK - Quantum-Documented CMake Build
# Target: PS Vita (Vitasdk)
#
# This CMakeLists.txt builds the bootloader VPK for PS Vita:
# - Compiles all C sources in eboot/
# - Packages LiveArea assets and manifest.txt
# - Produces a .vpk in ${CMAKE_BINARY_DIR}/dist_vpks/
#
# Dependencies: Vitasdk, LiveArea assets, manifest.txt
# Usage: Built as part of root build system
# ============================================================================

file(GLOB BOOTLOADER_SOURCES eboot/*.c)
set(VPK_NAME "LilithBoot")
set(VPK_TITLE "LilithOS Bootloader")
set(VPK_TITLE_ID "LILITHBOOT001")
set(VPK_VERSION "1.00")

# Remove AppleClang/macOS flags that break Vitasdk cross-compiling
foreach(flag_var
    CMAKE_C_FLAGS CMAKE_C_FLAGS_DEBUG CMAKE_C_FLAGS_RELEASE
    CMAKE_CXX_FLAGS CMAKE_CXX_FLAGS_DEBUG CMAKE_CXX_FLAGS_RELEASE)
  string(REPLACE "-arch arm64" "" ${flag_var} "${${flag_var}}")
  string(REPLACE "-isysroot" "" ${flag_var} "${${flag_var}}")
endforeach()

add_executable(${VPK_NAME} ${BOOTLOADER_SOURCES})

# Link VitaSDK libraries (add/remove as needed)
target_link_libraries(${VPK_NAME}
    -lvita2d -ltaihen_stub -lScePower_stub -lSceRtc_stub -lSceIo_stub -lSceKernel_stub
    -lSceThreadmgr_stub -lSceSysmem_stub -lSceProcessmgr_stub -lSceDisplay_stub -lSceGxm_stub
    -lSceCtrl_stub -lSceTouch_stub -lSceAudio_stub -lm -lc
)

# Output .velf
set_target_properties(${VPK_NAME} PROPERTIES OUTPUT_NAME ${VPK_NAME} SUFFIX ".velf")

# Post-build: param.sfo
add_custom_command(TARGET ${VPK_NAME} POST_BUILD
    COMMAND vita-mksfoex "${VPK_TITLE}" param.sfo
        -s TITLE_ID=${VPK_TITLE_ID}
        -s APP_VER=${VPK_VERSION}
        -s TITLE="${VPK_TITLE}"
        -s CATEGORY=GAME
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
    COMMENT "Creating param.sfo for ${VPK_NAME}")

# Post-build: .self
add_custom_command(TARGET ${VPK_NAME} POST_BUILD
    COMMAND vita-make-fself ${CMAKE_CURRENT_BINARY_DIR}/${VPK_NAME}.velf ${CMAKE_CURRENT_BINARY_DIR}/${VPK_NAME}.self
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
    COMMENT "Creating .self for ${VPK_NAME}")

# Copy LiveArea assets
add_custom_command(TARGET ${VPK_NAME} POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_directory ${CMAKE_CURRENT_SOURCE_DIR}/livearea ${CMAKE_CURRENT_BINARY_DIR}/livearea
    COMMENT "Copying LiveArea assets for ${VPK_NAME}")

# Post-build: .vpk
add_custom_command(TARGET ${VPK_NAME} POST_BUILD
    COMMAND vita-pack-vpk ${CMAKE_BINARY_DIR}/dist_vpks/${VPK_NAME}.vpk
        ${CMAKE_CURRENT_BINARY_DIR}/param.sfo
        ${CMAKE_CURRENT_BINARY_DIR}/${VPK_NAME}.self
        ${CMAKE_CURRENT_BINARY_DIR}/livearea/livearea.xml
        ${CMAKE_CURRENT_BINARY_DIR}/livearea/assets/icon.png
        ${CMAKE_CURRENT_BINARY_DIR}/livearea/assets/bg.png
        ${CMAKE_CURRENT_SOURCE_DIR}/manifest.txt
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
    COMMENT "Packaging ${VPK_NAME}.vpk for distribution") 