# LilithOS Homebrew Application Makefile
# Nintendo Switch - SN hac-001(-01) Optimized

# Application information
APP_TITLE := LilithOS
APP_AUTHOR := LilithOS Team
APP_VERSION := 2.0.0
APP_ICON := icon.jpg

# Source files
SOURCES := $(wildcard source/*.c)
OBJECTS := $(SOURCES:.c=.o)

# Compiler and flags
CC := aarch64-none-elf-gcc
CFLAGS := -Wall -Wextra -O2 -g -fPIE
LDFLAGS := -pie

# Include directories
INCLUDES := -I$(DEVKITPRO)/libnx/include -I$(DEVKITPRO)/portlibs/switch/include

# Library directories and libraries
LIBDIRS := -L$(DEVKITPRO)/libnx/lib -L$(DEVKITPRO)/portlibs/switch/lib
LIBS := -lnx -lm

# Output file
OUTPUT := lilithos_app.nro

# Default target
all: $(OUTPUT)

# Build the application
$(OUTPUT): $(OBJECTS)
	@echo "Linking $(OUTPUT)..."
	$(CC) $(LDFLAGS) $(OBJECTS) $(LIBDIRS) $(LIBS) -o $@
	@echo "Build complete!"

# Compile source files
%.o: %.c
	@echo "Compiling $<..."
	$(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@

# Clean build files
clean:
	@echo "Cleaning build files..."
	rm -f $(OBJECTS) $(OUTPUT)
	@echo "Clean complete!"

# Install to SD card (requires SD card path)
install: $(OUTPUT)
	@echo "Installing to SD card..."
	@if [ -z "$(SDCARD)" ]; then \
		echo "Error: SDCARD path not specified"; \
		echo "Usage: make install SDCARD=/path/to/sd/card"; \
		exit 1; \
	fi
	cp $(OUTPUT) $(SDCARD)/switch/homebrew/
	@echo "Installation complete!"

# Create distribution package
package: $(OUTPUT)
	@echo "Creating distribution package..."
	mkdir -p dist/lilithos_app
	cp $(OUTPUT) dist/lilithos_app/
	cp README.md dist/lilithos_app/
	cp LICENSE dist/lilithos_app/
	tar -czf lilithos_app_v$(APP_VERSION).tar.gz -C dist lilithos_app
	rm -rf dist
	@echo "Package created: lilithos_app_v$(APP_VERSION).tar.gz"

# Help target
help:
	@echo "LilithOS Homebrew Application Makefile"
	@echo "====================================="
	@echo ""
	@echo "Targets:"
	@echo "  all      - Build the application (default)"
	@echo "  clean    - Remove build files"
	@echo "  install  - Install to SD card (requires SDCARD=path)"
	@echo "  package  - Create distribution package"
	@echo "  help     - Show this help message"
	@echo ""
	@echo "Variables:"
	@echo "  SDCARD   - Path to SD card for installation"
	@echo ""
	@echo "Examples:"
	@echo "  make                    # Build application"
	@echo "  make clean              # Clean build files"
	@echo "  make install SDCARD=O:  # Install to O: drive"
	@echo "  make package            # Create package"

# Phony targets
.PHONY: all clean install package help 