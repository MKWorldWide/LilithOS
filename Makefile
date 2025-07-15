# Makefile for LilithMirror
# Target: PS Vita with taiHEN
# Dependencies: VitaSDK, taiHEN, vita2d, sceNet

# Project configuration
TARGET = LilithMirror
TITLE = LilithMirror
APPID = LILITHMIRROR001

# Build configuration
VITA_SDK = $(VITASDK)
VITA_TOOLCHAIN = $(VITA_SDK)/bin/arm-vita-eabi

# Compiler and flags
CC = $(VITA_TOOLCHAIN)-gcc
CXX = $(VITA_TOOLCHAIN)-g++
AR = $(VITA_TOOLCHAIN)-ar
STRIP = $(VITA_TOOLCHAIN)-strip

# Source files
SOURCES = LilithMirror.c
OBJECTS = $(SOURCES:.c=.o)

# Include directories
INCLUDES = -I$(VITA_SDK)/arm-vita-eabi/include \
           -I$(VITA_SDK)/arm-vita-eabi/include/psp2 \
           -I$(VITA_SDK)/arm-vita-eabi/include/taihen

# Library directories
LIBDIRS = -L$(VITA_SDK)/arm-vita-eabi/lib

# Libraries
LIBS = -lvita2d -ltaihen_stub -lScePower_stub -lSceRtc_stub \
       -lSceIo_stub -lSceKernel_stub -lSceThreadmgr_stub \
       -lSceSysmem_stub -lSceProcessmgr_stub -lSceDisplay_stub \
       -lSceGxm_stub -lSceCtrl_stub -lSceTouch_stub -lSceAudio_stub \
       -lSceNet_stub -lSceNetCtl_stub -lm

# Compiler flags
CFLAGS = -O2 -g -Wall -Wextra -std=c99 -fno-builtin-printf \
         -DVITA -D__PSP2__ -D__ARM__ -D__VITA__

# Linker flags
LDFLAGS = -Wl,-q $(LIBDIRS) $(LIBS)

# Default target
all: $(TARGET).vpk

# Build the VPK
$(TARGET).vpk: $(TARGET).velf
	$(VITA_TOOLCHAIN)-vita-make-fself $(TARGET).velf $(TARGET).self
	$(VITA_TOOLCHAIN)-vita-mksfoex -s TITLE_ID=$(APPID) -s APP_VER=1.00 -s TITLE="$(TITLE)" param.sfo
	$(VITA_TOOLCHAIN)-vita-pack-vpk $(TARGET).vpk param.sfo $(TARGET).self

# Build the ELF
$(TARGET).velf: $(OBJECTS)
	$(CC) $(OBJECTS) $(LDFLAGS) -o $(TARGET).velf
	$(STRIP) $(TARGET).velf

# Compile source files
%.o: %.c
	$(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@

# Clean build artifacts
clean:
	rm -f $(OBJECTS) $(TARGET).velf $(TARGET).self $(TARGET).vpk param.sfo

# Install to Vita (requires vita-mksfoex and vita-pack-vpk)
install: $(TARGET).vpk
	@echo "Installing $(TARGET).vpk to Vita..."
	@echo "Please copy $(TARGET).vpk to your Vita's ux0:/app/ directory"
	@echo "Then install via VitaShell or Package Installer"

# Debug build
debug: CFLAGS += -DDEBUG -O0
debug: $(TARGET).vpk

# Release build
release: CFLAGS += -DNDEBUG -O3
release: $(TARGET).vpk

# Help target
help:
	@echo "LilithMirror Build System"
	@echo "========================"
	@echo "Targets:"
	@echo "  all      - Build the VPK file (default)"
	@echo "  clean    - Remove build artifacts"
	@echo "  install  - Install instructions"
	@echo "  debug    - Build with debug symbols"
	@echo "  release  - Build optimized release version"
	@echo "  help     - Show this help message"
	@echo ""
	@echo "Environment:"
	@echo "  VITASDK  - Path to VitaSDK installation"
	@echo ""
	@echo "Usage:"
	@echo "  make VITASDK=/path/to/vitasdk"
	@echo "  make clean"
	@echo "  make install"

.PHONY: all clean install debug release help 