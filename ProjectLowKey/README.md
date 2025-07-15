# Project Low-Key

A modular, switchable multi-OS platform for the PS Vita, supporting:
- Primary boot via Enso/enso_ex
- Chainloading into a Custom OS (Linux, shell, etc.)
- Launching Adrenaline (PSP/PS1)
- Userland Switcher App

## Build (Docker/VitaSDK)
```sh
docker build -t vitabuild .
docker run --rm -v $PWD:/src vitabuild ./scripts/build_vpk.sh
```

## Directory Structure
- `bootloader/` - Minimal ARM payloads for custom OS booting
- `build/` - Output: VPKs, binaries
- `cmake/` - CMake modules (if needed)
- `docs/` - Documentation
- `icons/` - Placeholder icons
- `param.sfo` - Sample SFO
- `scripts/` - Build and utility scripts
- `src/` - Main homebrew source
- `switcher_app/` - Userland switcher app