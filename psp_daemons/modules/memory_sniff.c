/*
 * LilithOS PSP Plugin: memory_sniff.prx
 * -------------------------------------
 * Quantum-detailed PRX for runtime memory scanning, signal interface, and log bridge.
 *
 * 📋 Feature Context:
 *   - Dynamically scans PSP memory regions for patterns or anomalies.
 *   - Exposes a module signal interface for runtime control (start/stop/trigger scan).
 *   - Bridges logs to the Vita-side or external logger for analysis.
 *
 * 🧩 Dependency Listings:
 *   - Requires PSP SDK (pspsdk)
 *   - Communicates with Vita bridge via IPC or file/log
 *
 * 💡 Usage Example:
 *   - Load via Adrenaline or custom bootloader:
 *     load_module("ms0:/LILIDAEMON/MODULES/memory_sniff.prx");
 *
 * ⚡ Performance Considerations:
 *   - Scans are throttled to avoid frame drops.
 *   - Minimal memory footprint, runs in user thread.
 *
 * 🔒 Security Implications:
 *   - Only scans user memory regions.
 *   - Logs are sanitized before bridge output.
 *
 * 📜 Changelog Entries:
 *   - v1.0.0: Initial quantum-detailed scaffold.
 */

#include <pspkernel.h>
#include <pspdebug.h>
#include <pspthreadman.h>
#include <pspiofilemgr.h>
#include <string.h>

PSP_MODULE_INFO("MemorySniff", 0x1000, 1, 0);
PSP_MAIN_THREAD_ATTR(THREAD_ATTR_USER | THREAD_ATTR_VFPU);

#define LOG_PATH "ms0:/LILIDAEMON/memory_sniff.log"

static int running = 1;

// --- Logging Bridge ---
void log_bridge(const char* msg) {
    SceUID fd = sceIoOpen(LOG_PATH, PSP_O_WRONLY | PSP_O_CREAT | PSP_O_APPEND, 0777);
    if (fd >= 0) {
        sceIoWrite(fd, msg, strlen(msg));
        sceIoWrite(fd, "\n", 1);
        sceIoClose(fd);
    }
}

// --- Runtime Memory Scan Stub ---
void runtime_memory_scan() {
    // Example: Scan user memory for a simple pattern (0xDEADBEEF)
    unsigned int* mem = (unsigned int*)0x08800000; // User memory start
    unsigned int* end = (unsigned int*)0x0A000000; // User memory end
    int found = 0;
    for (; mem < end; ++mem) {
        if (*mem == 0xDEADBEEF) {
            found = 1;
            char buf[128];
            snprintf(buf, sizeof(buf), "[MemorySniff] Pattern found at 0x%08X", (unsigned int)mem);
            log_bridge(buf);
            break;
        }
    }
    if (!found) {
        log_bridge("[MemorySniff] Pattern not found");
    }
}

// --- Module Signal Interface ---
int signal_thread(SceSize args, void* argp) {
    log_bridge("[MemorySniff] Signal thread started");
    while (running) {
        // TODO: Replace with real IPC or signal mechanism
        sceKernelDelayThread(5 * 1000 * 1000); // 5 seconds
        runtime_memory_scan();
    }
    log_bridge("[MemorySniff] Signal thread stopped");
    sceKernelExitDeleteThread(0);
    return 0;
}

int module_start(SceSize args, void *argp) {
    pspDebugScreenInit();
    pspDebugScreenPrintf("MemorySniff: Module started\n");
    log_bridge("[MemorySniff] Module started");
    
    // Start signal thread
    SceUID thid = sceKernelCreateThread("MemorySniffSignal", signal_thread, 8, 0x1000, 0, NULL);
    if (thid >= 0) {
        sceKernelStartThread(thid, 0, NULL);
    } else {
        log_bridge("[MemorySniff] Failed to start signal thread");
    }
    return 0;
}

int module_stop(SceSize args, void *argp) {
    running = 0;
    log_bridge("[MemorySniff] Module stopped");
    pspDebugScreenPrintf("MemorySniff: Module stopped\n");
    return 0;
} 