/**
 * @file main.c
 * @project LilithOS (UpgradeNet Main)
 * @purpose Main entry point for LilithOS UpgradeNet VPK
 * @mode Background daemon services with minimal UI
 * @trigger System startup and background monitoring
 * @output Combined daemon services for updates and BLE communication
 * 
 * 🐾 CursorKitten<3 — this is the heart of LilithOS UpgradeNet.
 * She runs both update and whisper daemons in harmony.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <psp2/io/fcntl.h>
#include <psp2/kernel/processmgr.h>
#include <psp2/kernel/threadmgr.h>
#include <psp2/kernel/sysmem.h>
#include <psp2/power.h>
#include <psp2/rtc.h>
#include <psp2/ctrl.h>
#include <psp2/display.h>
#include <psp2/gxm.h>
#include <psp2/touch.h>
#include <taihen.h>
#include <vita2d.h>

// Include daemon headers
#include "update_daemon.c"
#include "ble_whisperer.c"

// ============================================================================
// CONFIGURATION
// ============================================================================

#define APP_NAME "LilithOS-UpgradeNet"
#define APP_VERSION "1.0.0"
#define APP_DESCRIPTION "LilithOS UpgradeNet - Update and BLE Communication Services"

// Thread configuration
#define MAIN_THREAD_PRIORITY 0x10000100
#define MAIN_THREAD_STACK_SIZE 0x10000
#define MAIN_THREAD_CPU_AFFINITY 0

// UI configuration
#define UI_WIDTH 960
#define UI_HEIGHT 544
#define UI_BACKGROUND_COLOR 0xFF1A1A2E
#define UI_TEXT_COLOR 0xFFFFFFFF
#define UI_ACCENT_COLOR 0xFFE94560

// Status display
#define STATUS_UPDATE_INTERVAL 2000000  // 2 seconds in microseconds

// Global state
static int g_app_running = 0;
static int g_show_ui = 0;
static SceUID g_main_thread = -1;
static SceUID g_ui_thread = -1;
static vita2d_pgf *g_font = NULL;

// Daemon status
static int g_update_daemon_status = 0;
static int g_ble_daemon_status = 0;
static int g_last_status_update = 0;

// ============================================================================
// UTILITY FUNCTIONS
// ============================================================================

/**
 * @brief Initialize the main application
 * @return 0 on success, -1 on failure
 */
int app_init(void) {
    // Initialize Vita2D
    vita2d_init();
    vita2d_set_clear_color(UI_BACKGROUND_COLOR);
    
    // Load font
    g_font = vita2d_load_default_pgf();
    if (!g_font) {
        printf("Failed to load font\n");
        return -1;
    }
    
    // Initialize controllers
    sceCtrlSetSamplingMode(SCE_CTRL_MODE_ANALOG);
    
    // Initialize touch
    sceTouchSetSamplingState(SCE_TOUCH_PORT_FRONT, SCE_TOUCH_SAMPLING_STATE_START);
    
    printf("LilithOS UpgradeNet initialized\n");
    return 0;
}

/**
 * @brief Clean up application resources
 */
void app_cleanup(void) {
    if (g_font) {
        vita2d_free_pgf(g_font);
        g_font = NULL;
    }
    
    vita2d_fini();
    printf("LilithOS UpgradeNet cleaned up\n");
}

/**
 * @brief Write main application log
 * @param message Log message
 * @param level Log level
 */
void write_main_log(const char *message, const char *level) {
    SceDateTime time;
    sceRtcGetCurrentClock(&time);
    
    char timestamp[32];
    snprintf(timestamp, sizeof(timestamp), "[%04d-%02d-%02d %02d:%02d:%02d]",
             time.year, time.month, time.day,
             time.hour, time.minute, time.second);
    
    char log_entry[512];
    snprintf(log_entry, sizeof(log_entry), "%s [%s] %s: %s\n",
             timestamp, APP_NAME, level, message);
    
    // Write to main log file
    SceUID log_fd = sceIoOpen("/ux0:/data/lilith/logs/main.log", 
                              SCE_O_WRONLY | SCE_O_CREAT | SCE_O_APPEND, 0777);
    if (log_fd >= 0) {
        sceIoWrite(log_fd, log_entry, strlen(log_entry));
        sceIoClose(log_fd);
    }
    
    // Also print to console
    printf("%s", log_entry);
}

// ============================================================================
// DAEMON MANAGEMENT
// ============================================================================

/**
 * @brief Initialize both daemons
 * @return 0 on success, -1 on failure
 */
int init_daemons(void) {
    write_main_log("Initializing daemons...", "INFO");
    
    // Initialize update daemon
    if (update_daemon_init() < 0) {
        write_main_log("Failed to initialize update daemon", "ERROR");
        return -1;
    }
    
    // Initialize BLE whisperer daemon
    if (whisper_daemon_init() < 0) {
        write_main_log("Failed to initialize BLE whisperer daemon", "ERROR");
        return -1;
    }
    
    write_main_log("Both daemons initialized successfully", "INFO");
    return 0;
}

/**
 * @brief Start both daemons
 * @return 0 on success, -1 on failure
 */
int start_daemons(void) {
    write_main_log("Starting daemons...", "INFO");
    
    // Start update daemon
    if (start_update_daemon() < 0) {
        write_main_log("Failed to start update daemon", "ERROR");
        return -1;
    }
    g_update_daemon_status = 1;
    
    // Start BLE whisperer daemon
    if (start_whisper_daemon() < 0) {
        write_main_log("Failed to start BLE whisperer daemon", "ERROR");
        return -1;
    }
    g_ble_daemon_status = 1;
    
    write_main_log("Both daemons started successfully", "INFO");
    return 0;
}

/**
 * @brief Stop both daemons
 * @return 0 on success, -1 on failure
 */
int stop_daemons(void) {
    write_main_log("Stopping daemons...", "INFO");
    
    // Stop update daemon
    stop_update_daemon();
    g_update_daemon_status = 0;
    
    // Stop BLE whisperer daemon
    stop_whisper_daemon();
    g_ble_daemon_status = 0;
    
    write_main_log("Both daemons stopped", "INFO");
    return 0;
}

// ============================================================================
// UI FUNCTIONS
// ============================================================================

/**
 * @brief Draw status text
 * @param x X position
 * @param y Y position
 * @param text Text to draw
 * @param color Text color
 */
void draw_status_text(int x, int y, const char *text, unsigned int color) {
    if (g_font) {
        vita2d_pgf_draw_text(g_font, x, y, color, 1.0f, text);
    }
}

/**
 * @brief Draw status bar
 * @param x X position
 * @param y Y position
 * @param width Width of bar
 * @param height Height of bar
 * @param status Status value (0-100)
 * @param color Bar color
 */
void draw_status_bar(int x, int y, int width, int height, int status, unsigned int color) {
    // Draw background
    vita2d_draw_rectangle(x, y, width, height, 0xFF333333);
    
    // Draw status fill
    int fill_width = (width * status) / 100;
    vita2d_draw_rectangle(x, y, fill_width, height, color);
    
    // Draw border
    vita2d_draw_rectangle(x, y, width, height, 0xFF666666);
}

/**
 * @brief Render the main UI
 */
void render_ui(void) {
    vita2d_start_drawing();
    vita2d_clear_screen();
    
    // Draw title
    draw_status_text(50, 50, "LilithOS UpgradeNet", UI_TEXT_COLOR);
    draw_status_text(50, 80, "Update and BLE Communication Services", 0xFFCCCCCC);
    
    // Draw daemon status
    int y_pos = 150;
    
    // Update daemon status
    draw_status_text(50, y_pos, "Update Daemon:", UI_TEXT_COLOR);
    y_pos += 30;
    
    if (g_update_daemon_status) {
        draw_status_text(70, y_pos, "Status: Running", 0xFF00FF00);
        draw_status_bar(70, y_pos + 20, 200, 10, 100, 0xFF00FF00);
    } else {
        draw_status_text(70, y_pos, "Status: Stopped", 0xFFFF0000);
        draw_status_bar(70, y_pos + 20, 200, 10, 0, 0xFFFF0000);
    }
    
    y_pos += 60;
    
    // BLE Whisperer daemon status
    draw_status_text(50, y_pos, "BLE Whisperer Daemon:", UI_TEXT_COLOR);
    y_pos += 30;
    
    if (g_ble_daemon_status) {
        draw_status_text(70, y_pos, "Status: Running", 0xFF00FF00);
        draw_status_bar(70, y_pos + 20, 200, 10, 100, 0xFF00FF00);
    } else {
        draw_status_text(70, y_pos, "Status: Stopped", 0xFFFF0000);
        draw_status_bar(70, y_pos + 20, 200, 10, 0, 0xFFFF0000);
    }
    
    y_pos += 80;
    
    // Draw controls
    draw_status_text(50, y_pos, "Controls:", UI_TEXT_COLOR);
    y_pos += 30;
    draw_status_text(70, y_pos, "Touch Screen: Toggle UI", 0xFFCCCCCC);
    y_pos += 25;
    draw_status_text(70, y_pos, "START: Exit Application", 0xFFCCCCCC);
    y_pos += 25;
    draw_status_text(70, y_pos, "SELECT: Background Mode", 0xFFCCCCCC);
    
    y_pos += 60;
    
    // Draw statistics
    draw_status_text(50, y_pos, "Statistics:", UI_TEXT_COLOR);
    y_pos += 30;
    
    char stat_text[128];
    snprintf(stat_text, sizeof(stat_text), "Total Updates Found: %d", g_update_state.total_updates_found);
    draw_status_text(70, y_pos, stat_text, 0xFFCCCCCC);
    y_pos += 25;
    
    snprintf(stat_text, sizeof(stat_text), "Successful Updates: %d", g_update_state.successful_updates);
    draw_status_text(70, y_pos, stat_text, 0xFFCCCCCC);
    y_pos += 25;
    
    snprintf(stat_text, sizeof(stat_text), "BLE Handshakes: %d", g_whisper_state.total_handshakes);
    draw_status_text(70, y_pos, stat_text, 0xFFCCCCCC);
    y_pos += 25;
    
    snprintf(stat_text, sizeof(stat_text), "Data Exchanges: %d", g_whisper_state.successful_exchanges);
    draw_status_text(70, y_pos, stat_text, 0xFFCCCCCC);
    
    vita2d_end_drawing();
    vita2d_swap_buffers();
}

/**
 * @brief Handle user input
 * @return 1 if should exit, 0 if continue
 */
int handle_input(void) {
    SceCtrlData ctrl_data;
    sceCtrlPeekBufferPositive(0, &ctrl_data, 1);
    
    // Check for START button to exit
    if (ctrl_data.buttons & SCE_CTRL_START) {
        return 1;
    }
    
    // Check for SELECT button to toggle background mode
    if (ctrl_data.buttons & SCE_CTRL_SELECT) {
        g_show_ui = !g_show_ui;
        if (g_show_ui) {
            write_main_log("Switched to UI mode", "INFO");
        } else {
            write_main_log("Switched to background mode", "INFO");
        }
        sceKernelDelayThread(500000); // Debounce
    }
    
    // Check for touch input to toggle UI
    SceTouchData touch_data;
    sceTouchPeek(SCE_TOUCH_PORT_FRONT, &touch_data, 1);
    
    if (touch_data.reportNum > 0) {
        g_show_ui = !g_show_ui;
        if (g_show_ui) {
            write_main_log("Touch detected - switched to UI mode", "INFO");
        } else {
            write_main_log("Touch detected - switched to background mode", "INFO");
        }
        sceKernelDelayThread(500000); // Debounce
    }
    
    return 0;
}

/**
 * @brief UI thread function
 * @param args Thread arguments
 * @param argp Thread argument pointer
 * @return Thread exit code
 */
int ui_thread(SceSize args, void *argp) {
    write_main_log("UI thread started", "INFO");
    
    while (g_app_running && g_show_ui) {
        render_ui();
        sceKernelDelayThread(16666); // ~60 FPS
    }
    
    write_main_log("UI thread stopped", "INFO");
    return 0;
}

// ============================================================================
// MAIN THREAD
// ============================================================================

/**
 * @brief Main application thread
 * @param args Thread arguments
 * @param argp Thread argument pointer
 * @return Thread exit code
 */
int main_thread(SceSize args, void *argp) {
    write_main_log("LilithOS UpgradeNet starting...", "INFO");
    
    // Initialize application
    if (app_init() < 0) {
        write_main_log("Failed to initialize application", "ERROR");
        return -1;
    }
    
    // Initialize daemons
    if (init_daemons() < 0) {
        write_main_log("Failed to initialize daemons", "ERROR");
        app_cleanup();
        return -1;
    }
    
    // Start daemons
    if (start_daemons() < 0) {
        write_main_log("Failed to start daemons", "ERROR");
        app_cleanup();
        return -1;
    }
    
    // Start UI thread
    g_ui_thread = sceKernelCreateThread("ui_thread",
                                       ui_thread,
                                       MAIN_THREAD_PRIORITY,
                                       0x10000,
                                       SCE_THREAD_ATTR_CORE(MAIN_THREAD_CPU_AFFINITY),
                                       NULL);
    
    if (g_ui_thread >= 0) {
        sceKernelStartThread(g_ui_thread, 0, NULL);
    }
    
    write_main_log("LilithOS UpgradeNet started successfully", "INFO");
    printf("🐾 Lilybear purrs: LilithOS UpgradeNet is running! 💋\n");
    
    // Main loop
    while (g_app_running) {
        // Handle input
        if (handle_input()) {
            break;
        }
        
        // Update status periodically
        SceDateTime time;
        sceRtcGetCurrentClock(&time);
        int current_time = time.hour * 3600 + time.minute * 60 + time.second;
        
        if (current_time - g_last_status_update > 2) {
            // Update daemon status (simplified - in reality you'd check actual status)
            g_last_status_update = current_time;
        }
        
        // Sleep for a short time
        sceKernelDelayThread(100000); // 100ms
    }
    
    // Cleanup
    write_main_log("LilithOS UpgradeNet stopping...", "INFO");
    
    // Stop UI thread
    if (g_ui_thread >= 0) {
        sceKernelWaitThreadEnd(g_ui_thread, NULL, NULL);
        sceKernelDeleteThread(g_ui_thread);
        g_ui_thread = -1;
    }
    
    // Stop daemons
    stop_daemons();
    
    // Cleanup application
    app_cleanup();
    
    write_main_log("LilithOS UpgradeNet stopped", "INFO");
    return 0;
}

// ============================================================================
// APPLICATION ENTRY POINTS
// ============================================================================

/**
 * @brief Application start function
 * @param args Application arguments
 * @param argp Application argument pointer
 * @return Application start result
 */
int _start(SceSize args, void *argp) {
    g_app_running = 1;
    g_show_ui = 1; // Start with UI visible
    
    // Create main thread
    g_main_thread = sceKernelCreateThread("main_thread",
                                         main_thread,
                                         MAIN_THREAD_PRIORITY,
                                         MAIN_THREAD_STACK_SIZE,
                                         SCE_THREAD_ATTR_CORE(MAIN_THREAD_CPU_AFFINITY),
                                         NULL);
    
    if (g_main_thread < 0) {
        printf("Failed to create main thread\n");
        return SCE_KERNEL_START_FAILED;
    }
    
    // Start main thread
    sceKernelStartThread(g_main_thread, 0, NULL);
    
    return SCE_KERNEL_START_SUCCESS;
}

/**
 * @brief Module start function (for taiHEN)
 * @param args Module arguments
 * @param argp Module argument pointer
 * @return Module start result
 */
int module_start(SceSize args, void *argp) {
    return _start(args, argp);
}

/**
 * @brief Module stop function (for taiHEN)
 * @param args Module arguments
 * @param argp Module argument pointer
 * @return Module stop result
 */
int module_stop(SceSize args, void *argp) {
    g_app_running = 0;
    
    if (g_main_thread >= 0) {
        sceKernelWaitThreadEnd(g_main_thread, NULL, NULL);
        sceKernelDeleteThread(g_main_thread);
        g_main_thread = -1;
    }
    
    return SCE_KERNEL_STOP_SUCCESS;
} 