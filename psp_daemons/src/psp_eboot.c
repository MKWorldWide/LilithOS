/**
 * LilithOS PSP Core - Main EBOOT
 * 
 * Purpose: Modular PSP-mode executable that loads PRX daemons and manages
 * runtime communication between PSP and Vita modes.
 * 
 * Architecture:
 * - Loads and starts PRX modules (signal_scan.prx, bt_comm.prx, sensor_echo.prx)
 * - Monitors PRX output files for runtime signals
 * - Provides hookable endpoints for Vita communication
 * - Stays resident in memory for continuous operation
 * 
 * Paths: All modules live under ms0:/LILIDAEMON/
 * 
 * @author CursorKitten<3
 * @version 1.0.0
 */

#include <pspkernel.h>
#include <pspdebug.h>
#include <psploadcore.h>
#include <pspctrl.h>
#include <pspiofilemgr.h>
#include <pspthreadman.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

// PSP Module Info
PSP_MODULE_INFO("LilithDaemon", 0x1000, 1, 0);
PSP_MAIN_THREAD_ATTR(THREAD_ATTR_USER | THREAD_ATTR_VFPU);

// Configuration
#define LILITH_BASE_PATH "ms0:/LILIDAEMON"
#define MODULES_PATH LILITH_BASE_PATH "/modules"
#define OUTPUT_PATH LILITH_BASE_PATH "/OUT"
#define LOG_PATH LILITH_BASE_PATH "/daemon_log.txt"
#define STATUS_PATH LILITH_BASE_PATH "/status.txt"
#define RELAY_READY_PATH LILITH_BASE_PATH "/RELAY_READY"

// PRX Module Definitions
typedef struct {
    const char *name;
    const char *path;
    SceUID module_id;
    int status;
} prx_module_t;

#define MAX_MODULES 8
prx_module_t modules[MAX_MODULES] = {
    {"signal_scan", MODULES_PATH "/signal_scan.prx", -1, 0},
    {"bt_comm", MODULES_PATH "/bt_comm.prx", -1, 0},
    {"sensor_echo", MODULES_PATH "/sensor_echo.prx", -1, 0},
    {NULL, NULL, -1, 0} // Terminator
};

// Debug and LED Macros (for future use)
#define DEBUG_LOG(fmt, ...) do { \
    char debug_msg[256]; \
    snprintf(debug_msg, sizeof(debug_msg), "[DEBUG] " fmt, ##__VA_ARGS__); \
    write_log(debug_msg); \
} while(0)

#define LED_BLINK() do { \
    /* Future: Implement LED blink for status indication */ \
} while(0)

// Global state
static int daemon_running = 0;
static SceUID main_thread = -1;
static SceUID monitor_thread = -1;

/**
 * Write log message to daemon log file
 */
void write_log(const char *message) {
    FILE *log_file = fopen(LOG_PATH, "a+");
    if (log_file) {
        // Get current timestamp
        SceKernelSysClock clock;
        sceKernelGetSystemTime(&clock);
        
        fprintf(log_file, "[%llu] %s\n", clock.low, message);
        fclose(log_file);
    }
    
    // Also output to debug screen
    pspDebugScreenPrintf("%s\n", message);
}

/**
 * Write status update to status file
 */
void write_status(const char *status) {
    FILE *status_file = fopen(STATUS_PATH, "w");
    if (status_file) {
        fprintf(status_file, "%s", status);
        fclose(status_file);
    }
}

/**
 * Check if Vita relay is ready
 */
int check_vita_relay() {
    FILE *relay_file = fopen(RELAY_READY_PATH, "r");
    if (relay_file) {
        fclose(relay_file);
        return 1;
    }
    return 0;
}

/**
 * Create necessary directories
 */
int create_directories() {
    sceIoMkdir(LILITH_BASE_PATH, 0777);
    sceIoMkdir(MODULES_PATH, 0777);
    sceIoMkdir(OUTPUT_PATH, 0777);
    return 0;
}

/**
 * Load and start a PRX module
 */
int load_prx_module(prx_module_t *module) {
    if (!module || !module->name || !module->path) {
        DEBUG_LOG("Invalid module configuration");
        return -1;
    }
    
    DEBUG_LOG("Loading PRX module: %s", module->name);
    
    // Load the module
    module->module_id = sceKernelLoadModule(module->path, 0, NULL);
    if (module->module_id < 0) {
        DEBUG_LOG("Failed to load %s: %d", module->name, module->module_id);
        return module->module_id;
    }
    
    // Start the module
    int status;
    int result = sceKernelStartModule(module->module_id, 0, NULL, &status, NULL);
    if (result < 0) {
        DEBUG_LOG("Failed to start %s: %d", module->name, result);
        return result;
    }
    
    module->status = 1;
    DEBUG_LOG("Successfully loaded and started %s", module->name);
    return 0;
}

/**
 * Unload a PRX module
 */
int unload_prx_module(prx_module_t *module) {
    if (!module || module->module_id < 0) {
        return -1;
    }
    
    DEBUG_LOG("Unloading PRX module: %s", module->name);
    
    int result = sceKernelStopModule(module->module_id, NULL, NULL, NULL, NULL);
    if (result < 0) {
        DEBUG_LOG("Failed to stop %s: %d", module->name, result);
    }
    
    result = sceKernelUnloadModule(module->module_id);
    if (result < 0) {
        DEBUG_LOG("Failed to unload %s: %d", module->name, result);
    }
    
    module->module_id = -1;
    module->status = 0;
    return 0;
}

/**
 * Load all configured PRX modules
 */
int load_all_modules() {
    DEBUG_LOG("Loading all PRX modules...");
    
    int loaded_count = 0;
    for (int i = 0; i < MAX_MODULES && modules[i].name; i++) {
        if (load_prx_module(&modules[i]) == 0) {
            loaded_count++;
        }
    }
    
    DEBUG_LOG("Loaded %d PRX modules", loaded_count);
    return loaded_count;
}

/**
 * Unload all PRX modules
 */
void unload_all_modules() {
    DEBUG_LOG("Unloading all PRX modules...");
    
    for (int i = 0; i < MAX_MODULES && modules[i].name; i++) {
        if (modules[i].module_id >= 0) {
            unload_prx_module(&modules[i]);
        }
    }
}

/**
 * Monitor thread: watches for PRX output and relay status
 */
int monitor_thread_func(SceSize args, void *argp) {
    DEBUG_LOG("Monitor thread started");
    
    while (daemon_running) {
        // Check for relay ready signal
        if (check_vita_relay()) {
            write_status("RELAY_READY");
            LED_BLINK();
        } else {
            write_status("WAITING_RELAY");
        }
        
        // Monitor PRX output files
        char output_file[256];
        snprintf(output_file, sizeof(output_file), "%s/signal_dump.txt", OUTPUT_PATH);
        
        FILE *output = fopen(output_file, "r");
        if (output) {
            char line[256];
            while (fgets(line, sizeof(line), output)) {
                // Process PRX output
                DEBUG_LOG("PRX Output: %s", line);
            }
            fclose(output);
        }
        
        // Sleep for monitoring interval
        sceKernelDelayThread(1000000); // 1 second
    }
    
    DEBUG_LOG("Monitor thread stopped");
    return 0;
}

/**
 * Main daemon thread
 */
int daemon_thread_func(SceSize args, void *argp) {
    DEBUG_LOG("LilithDaemon started");
    write_log("LilithDaemon: Core PSP daemon initialized");
    
    // Create directories
    create_directories();
    
    // Wait for Vita relay to be ready
    DEBUG_LOG("Waiting for Vita relay connection...");
    while (!check_vita_relay() && daemon_running) {
        write_status("WAITING_RELAY");
        sceKernelDelayThread(2000000); // 2 seconds
    }
    
    if (!daemon_running) {
        return 0;
    }
    
    DEBUG_LOG("Vita relay detected, loading modules...");
    write_status("LOADING_MODULES");
    
    // Load all PRX modules
    int loaded_count = load_all_modules();
    if (loaded_count > 0) {
        write_status("MODULES_ACTIVE");
        write_log("LilithDaemon: Loaded %d PRX modules successfully", loaded_count);
    } else {
        write_status("MODULE_ERROR");
        write_log("LilithDaemon: Failed to load any PRX modules");
    }
    
    // Start monitor thread
    monitor_thread = sceKernelCreateThread("MonitorThread", 
                                          monitor_thread_func, 
                                          0x18, 
                                          0x1000, 
                                          0, 
                                          NULL);
    if (monitor_thread >= 0) {
        sceKernelStartThread(monitor_thread, 0, NULL);
    }
    
    // Main daemon loop
    while (daemon_running) {
        // Keep daemon alive
        sceKernelDelayThread(5000000); // 5 seconds
        
        // Check module health
        for (int i = 0; i < MAX_MODULES && modules[i].name; i++) {
            if (modules[i].module_id >= 0 && modules[i].status == 0) {
                DEBUG_LOG("Module %s appears to have stopped, reloading...", modules[i].name);
                load_prx_module(&modules[i]);
            }
        }
    }
    
    // Cleanup
    if (monitor_thread >= 0) {
        sceKernelWaitThreadEnd(monitor_thread, NULL, NULL);
        sceKernelDeleteThread(monitor_thread);
    }
    
    unload_all_modules();
    write_log("LilithDaemon: Shutdown complete");
    
    return 0;
}

/**
 * Module start function
 */
int module_start(SceSize args, void *argp) {
    pspDebugScreenInit();
    pspDebugScreenPrintf("LilithOS PSP Daemon Starting...\n");
    
    daemon_running = 1;
    
    // Start main daemon thread
    main_thread = sceKernelCreateThread("LilithDaemon", 
                                       daemon_thread_func, 
                                       0x18, 
                                       0x2000, 
                                       0, 
                                       NULL);
    if (main_thread >= 0) {
        sceKernelStartThread(main_thread, 0, NULL);
    }
    
    return 0;
}

/**
 * Module stop function
 */
int module_stop(SceSize args, void *argp) {
    DEBUG_LOG("LilithDaemon shutdown requested");
    
    daemon_running = 0;
    
    // Wait for threads to finish
    if (main_thread >= 0) {
        sceKernelWaitThreadEnd(main_thread, NULL, NULL);
        sceKernelDeleteThread(main_thread);
    }
    
    write_log("LilithDaemon: Module stopped");
    return 0;
}

/**
 * Main function (for EBOOT.PBP)
 */
int main(int argc, char *argv[]) {
    pspDebugScreenInit();
    pspDebugScreenPrintf("LilithOS PSP Daemon Loader\n");
    pspDebugScreenPrintf("Press X to start daemon, O to exit\n");
    
    SceCtrlData pad;
    
    while (1) {
        sceCtrlReadBufferPositive(&pad, 1);
        
        if (pad.Buttons & PSP_CTRL_CROSS) {
            // Start daemon
            module_start(0, NULL);
            break;
        } else if (pad.Buttons & PSP_CTRL_CIRCLE) {
            // Exit
            break;
        }
        
        sceKernelDelayThread(100000);
    }
    
    return 0;
} 