# ============================================================================
# LilithOS Voice VPK - Quantum-Documented CMake Build
# Target: PS Vita (Python-based, data packaging only)
#
# This CMakeLists.txt packages the voice VPK for PS Vita:
# - Packages all .py, .json, and .yaml files in eboot/
# - Packages LiveArea assets and manifest.txt
# - Produces a .vpk in ${CMAKE_BINARY_DIR}/dist_vpks/
#
# Dependencies: LiveArea assets, manifest.txt
# Usage: Built as part of root build system
# ============================================================================

file(GLOB VOICE_DATA eboot/*.py eboot/*.json eboot/*.yaml)
set(VPK_NAME "LilithVoice")
set(VPK_TITLE "LilithOS Voice")
set(VPK_TITLE_ID "LILITHVOICE01")
set(VPK_VERSION "1.00")

# Remove AppleClang/macOS flags that break Vitasdk cross-compiling
foreach(flag_var
    CMAKE_C_FLAGS CMAKE_C_FLAGS_DEBUG CMAKE_C_FLAGS_RELEASE
    CMAKE_CXX_FLAGS CMAKE_CXX_FLAGS_DEBUG CMAKE_CXX_FLAGS_RELEASE)
  string(REPLACE "-arch arm64" "" ${flag_var} "${${flag_var}}")
  string(REPLACE "-isysroot" "" ${flag_var} "${${flag_var}}")
endforeach()

# Copy LiveArea assets
add_custom_command(OUTPUT voice_livearea_copied
    COMMAND ${CMAKE_COMMAND} -E copy_directory ${CMAKE_CURRENT_SOURCE_DIR}/livearea ${CMAKE_CURRENT_BINARY_DIR}/livearea
    COMMENT "Copying LiveArea assets for ${VPK_NAME}")

# Copy all eboot/ files (Python/data) to build dir
add_custom_command(OUTPUT voice_data_copied
    COMMAND ${CMAKE_COMMAND} -E copy_directory ${CMAKE_CURRENT_SOURCE_DIR}/eboot ${CMAKE_CURRENT_BINARY_DIR}/eboot
    COMMENT "Copying Python/data files for ${VPK_NAME}")

add_custom_target(voice_copy ALL DEPENDS voice_livearea_copied voice_data_copied)

# Post-build: param.sfo (dummy for data VPK)
add_custom_command(OUTPUT param.sfo
    COMMAND vita-mksfoex "${VPK_TITLE}" param.sfo
        -s TITLE_ID=${VPK_TITLE_ID}
        -s APP_VER=${VPK_VERSION}
        -s TITLE="${VPK_TITLE}"
        -s CATEGORY=GAME
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
    COMMENT "Creating param.sfo for ${VPK_NAME}")

add_custom_target(voice_sfo ALL DEPENDS param.sfo)

# Post-build: .vpk (data only)
add_custom_command(OUTPUT ${CMAKE_BINARY_DIR}/dist_vpks/${VPK_NAME}.vpk
    COMMAND vita-pack-vpk ${CMAKE_BINARY_DIR}/dist_vpks/${VPK_NAME}.vpk
        ${CMAKE_CURRENT_BINARY_DIR}/param.sfo
        ${CMAKE_CURRENT_BINARY_DIR}/livearea/livearea.xml
        ${CMAKE_CURRENT_BINARY_DIR}/livearea/assets/icon.png
        ${CMAKE_CURRENT_BINARY_DIR}/livearea/assets/bg.png
        ${CMAKE_CURRENT_SOURCE_DIR}/manifest.txt
        ${CMAKE_CURRENT_BINARY_DIR}/eboot/lilith_voice_daemon.py
        ${CMAKE_CURRENT_BINARY_DIR}/eboot/main.py
        ${CMAKE_CURRENT_BINARY_DIR}/eboot/phrase_scripts.json
        ${CMAKE_CURRENT_BINARY_DIR}/eboot/voice_config.yaml
        ${CMAKE_CURRENT_BINARY_DIR}/eboot/whisperer_integration.py
        ${CMAKE_CURRENT_BINARY_DIR}/eboot/voice_manager.py
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
    COMMENT "Packaging ${VPK_NAME}.vpk for distribution")

add_custom_target(voice_vpk ALL DEPENDS ${CMAKE_BINARY_DIR}/dist_vpks/${VPK_NAME}.vpk)
add_dependencies(voice_vpk voice_copy voice_sfo) 