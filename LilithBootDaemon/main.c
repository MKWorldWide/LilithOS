/**
 * @file main.c
 * @project LilithBootDaemon.vpk
 * @purpose Soft Dual-Boot Selector for Vita using button input
 * @style Dreamy UI, sharp transitions, deadly accurate payload boot
 * @environment VitaSDK, vita2d, taiHEN
 * 
 * 🐾 CursorKitten<3 — you're writing the startup logic for LilithBootDaemon.
 * She awakens at launch and listens for your touch.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <psp2/ctrl.h>
#include <psp2/display.h>
#include <psp2/gxm.h>
#include <psp2/kernel/processmgr.h>
#include <psp2/kernel/threadmgr.h>
#include <psp2/kernel/sysmem.h>
#include <psp2/appmgr.h>
#include <psp2/io/fcntl.h>
#include <psp2/io/stat.h>
#include <psp2/rtc.h>
#include <taihen.h>
#include <vita2d.h>

// Configuration
#define BOOT_LOG_PATH "/ux0:/data/lowkey/logs/boot.log"
#define BOOT_TIMEOUT_MS 5000
#define PULSE_SPEED 2.0f
#define TRANSITION_DURATION 1000

// Boot targets
typedef enum {
    BOOT_LILITHOS = 0,
    BOOT_ADRENALINE = 1,
    BOOT_VITASHELL = 2,
    BOOT_MENU = 3
} boot_target_t;

// App URIs
static const char* BOOT_URIS[] = {
    "ux0:/app/LILITH001/",                    // LilithOS
    "pspemu:/PSP/GAME/ADRENALINE/EBOOT.PBP",  // Adrenaline
    "ux0:/app/VITASHELL/",                    // VitaShell
    NULL                                       // Menu (handled separately)
};

// App names for display
static const char* BOOT_NAMES[] = {
    "LilithOS",
    "Adrenaline (PSP)",
    "VitaShell",
    "Boot Menu"
};

// UI state
typedef struct {
    float pulse_alpha;
    float pulse_scale;
    int selected_option;
    int menu_mode;
    time_t start_time;
    boot_target_t boot_target;
    int transition_start;
    float transition_progress;
    vita2d_font* font;
} ui_state_t;

static ui_state_t g_ui_state = {0};

// Colors (pure black background, violet and soft blue accents)
#define COLOR_BACKGROUND 0xFF000000
#define COLOR_ACCENT_VIOLET 0xFF8A2BE2
#define COLOR_ACCENT_BLUE 0xFF4169E1
#define COLOR_TEXT_WHITE 0xFFFFFFFF
#define COLOR_TEXT_DIM 0xFF888888

/**
 * @brief Initialize the boot daemon
 * @return 0 on success, -1 on failure
 */
int boot_daemon_init(void) {
    // Initialize vita2d
    vita2d_init();
    vita2d_set_clear_color(COLOR_BACKGROUND);
    
    // Initialize UI state
    memset(&g_ui_state, 0, sizeof(ui_state_t));
    g_ui_state.start_time = time(NULL);
    g_ui_state.boot_target = BOOT_LILITHOS;
    g_ui_state.transition_start = 0;
    g_ui_state.transition_progress = 0.0f;
    
    // Create log directory
    sceIoMkdir("/ux0:/data/lowkey", 0777);
    sceIoMkdir("/ux0:/data/lowkey/logs", 0777);
    
    return 0;
}

/**
 * @brief Write boot log entry
 * @param target Boot target selected
 * @param reason Reason for selection
 */
void write_boot_log(boot_target_t target, const char* reason) {
    SceUID log_fd = sceIoOpen(BOOT_LOG_PATH, SCE_O_WRONLY | SCE_O_CREAT | SCE_O_APPEND, 0777);
    if (log_fd < 0) {
        return;
    }
    
    SceDateTime time;
    sceRtcGetCurrentClock(&time);
    
    char log_entry[512];
    snprintf(log_entry, sizeof(log_entry),
             "[%04d-%02d-%02d %02d:%02d:%02d] Boot: %s | Reason: %s\n",
             time.year, time.month, time.day,
             time.hour, time.minute, time.second,
             BOOT_NAMES[target], reason);
    
    sceIoWrite(log_fd, log_entry, strlen(log_entry));
    sceIoClose(log_fd);
}

/**
 * @brief Check button input and determine boot target
 * @return Boot target to launch
 */
boot_target_t check_boot_input(void) {
    SceCtrlData ctrl_data;
    sceCtrlPeekBufferPositive(0, &ctrl_data, 1);
    
    // Check for trigger combinations
    if (ctrl_data.buttons & SCE_CTRL_LTRIGGER) {
        return BOOT_ADRENALINE;
    } else if (ctrl_data.buttons & SCE_CTRL_RTRIGGER) {
        return BOOT_VITASHELL;
    } else if (ctrl_data.buttons & SCE_CTRL_START) {
        return BOOT_MENU;
    }
    
    // Default to LilithOS
    return BOOT_LILITHOS;
}

/**
 * @brief Launch application by URI
 * @param uri Application URI to launch
 * @return 0 on success, -1 on failure
 */
int launch_app(const char* uri) {
    if (!uri) {
        return -1;
    }
    
    // Write boot log
    write_boot_log(g_ui_state.boot_target, "Button trigger");
    
    // Launch the application
    int result = sceAppMgrLaunchAppByUri(0x20000, uri);
    
    if (result < 0) {
        // Fallback: try to launch by title ID
        const char* title_ids[] = {
            "LILITH001",    // LilithOS
            "ADRENALINE",   // Adrenaline
            "VITASHELL"     // VitaShell
        };
        
        if (g_ui_state.boot_target < 3) {
            char title_uri[256];
            snprintf(title_uri, sizeof(title_uri), "psgm:play?titleid=%s", title_ids[g_ui_state.boot_target]);
            result = sceAppMgrLaunchAppByUri(0x20000, title_uri);
        }
    }
    
    return result;
}

/**
 * @brief Draw dreamy background with pulse animation
 */
void draw_dreamy_background(void) {
    // Calculate pulse animation
    float time = (float)(time(NULL) - g_ui_state.start_time);
    g_ui_state.pulse_alpha = 0.3f + 0.2f * sinf(time * PULSE_SPEED);
    g_ui_state.pulse_scale = 1.0f + 0.1f * sinf(time * PULSE_SPEED * 0.5f);
    
    // Clear to pure black
    vita2d_clear_screen();
    
    // Draw pulsing accent circles
    int screen_w = vita2d_get_current_fb_width();
    int screen_h = vita2d_get_current_fb_height();
    
    // Violet pulse in top-left
    vita2d_draw_fill_circle(
        screen_w * 0.2f, 
        screen_h * 0.2f, 
        100 * g_ui_state.pulse_scale, 
        (COLOR_ACCENT_VIOLET & 0xFFFFFF) | ((int)(g_ui_state.pulse_alpha * 255) << 24)
    );
    
    // Blue pulse in bottom-right
    vita2d_draw_fill_circle(
        screen_w * 0.8f, 
        screen_h * 0.8f, 
        80 * g_ui_state.pulse_scale, 
        (COLOR_ACCENT_BLUE & 0xFFFFFF) | ((int)(g_ui_state.pulse_alpha * 255) << 24)
    );
}

/**
 * @brief Draw boot menu
 */
void draw_boot_menu(void) {
    int screen_w = vita2d_get_current_fb_width();
    int screen_h = vita2d_get_current_fb_height();
    
    // Draw title
    vita2d_font_draw_textf(g_ui_state.font, 
        screen_w / 2 - 150, screen_h * 0.2f, 
        COLOR_TEXT_WHITE, 1.5f, 
        "🐾 LilithBootDaemon");
    
    // Draw subtitle
    vita2d_font_draw_textf(g_ui_state.font, 
        screen_w / 2 - 200, screen_h * 0.25f, 
        COLOR_TEXT_DIM, 1.0f, 
        "Choose your rebirth...");
    
    // Draw menu options
    int menu_y = screen_h * 0.4f;
    int menu_spacing = 60;
    
    for (int i = 0; i < 3; i++) {
        int y = menu_y + (i * menu_spacing);
        uint32_t color = (i == g_ui_state.selected_option) ? COLOR_ACCENT_VIOLET : COLOR_TEXT_WHITE;
        
        // Draw selection indicator
        if (i == g_ui_state.selected_option) {
            vita2d_draw_fill_rect(screen_w * 0.25f - 10, y - 5, 20, 40, COLOR_ACCENT_VIOLET);
        }
        
        // Draw option text
        vita2d_font_draw_textf(g_ui_state.font, 
            screen_w * 0.3f, y + 20, 
            color, 1.2f, 
            "%s", BOOT_NAMES[i]);
    }
    
    // Draw instructions
    vita2d_font_draw_textf(g_ui_state.font, 
        screen_w / 2 - 150, screen_h * 0.8f, 
        COLOR_TEXT_DIM, 0.8f, 
        "▲/▼: Select  ○: Launch  ×: Cancel");
}

/**
 * @brief Draw waiting screen
 */
void draw_waiting_screen(void) {
    int screen_w = vita2d_get_current_fb_width();
    int screen_h = vita2d_get_current_fb_height();
    
    // Draw title with pulse
    vita2d_font_draw_textf(g_ui_state.font, 
        screen_w / 2 - 200, screen_h * 0.3f, 
        COLOR_TEXT_WHITE, 1.8f, 
        "🐾 LilithBootDaemon");
    
    // Draw subtitle
    vita2d_font_draw_textf(g_ui_state.font, 
        screen_w / 2 - 250, screen_h * 0.4f, 
        COLOR_TEXT_DIM, 1.0f, 
        "Listening for your touch...");
    
    // Draw boot options
    vita2d_font_draw_textf(g_ui_state.font, 
        screen_w / 2 - 200, screen_h * 0.55f, 
        COLOR_ACCENT_VIOLET, 1.0f, 
        "L Trigger: Adrenaline (PSP)");
    
    vita2d_font_draw_textf(g_ui_state.font, 
        screen_w / 2 - 200, screen_h * 0.6f, 
        COLOR_ACCENT_BLUE, 1.0f, 
        "R Trigger: VitaShell");
    
    vita2d_font_draw_textf(g_ui_state.font, 
        screen_w / 2 - 200, screen_h * 0.65f, 
        COLOR_TEXT_WHITE, 1.0f, 
        "Nothing: LilithOS");
    
    vita2d_font_draw_textf(g_ui_state.font, 
        screen_w / 2 - 200, screen_h * 0.7f, 
        COLOR_TEXT_DIM, 1.0f, 
        "START: Boot Menu");
    
    // Draw pulsing dot
    float pulse = 0.5f + 0.5f * sinf((float)(time(NULL) - g_ui_state.start_time) * 3.0f);
    vita2d_draw_fill_circle(
        screen_w / 2, screen_h * 0.8f, 
        8 * pulse, 
        (COLOR_ACCENT_VIOLET & 0xFFFFFF) | ((int)(255 * pulse) << 24)
    );
}

/**
 * @brief Draw transition screen
 */
void draw_transition_screen(void) {
    int screen_w = vita2d_get_current_fb_width();
    int screen_h = vita2d_get_current_fb_height();
    
    // Calculate transition progress
    int current_time = sceKernelGetProcessTimeWide();
    if (g_ui_state.transition_start == 0) {
        g_ui_state.transition_start = current_time;
    }
    
    float elapsed = (current_time - g_ui_state.transition_start) / 1000.0f;
    g_ui_state.transition_progress = elapsed / (TRANSITION_DURATION / 1000.0f);
    
    if (g_ui_state.transition_progress > 1.0f) {
        g_ui_state.transition_progress = 1.0f;
    }
    
    // Draw transition overlay
    uint32_t overlay_alpha = (uint32_t)(g_ui_state.transition_progress * 255);
    vita2d_draw_fill_rect(0, 0, screen_w, screen_h, 
        (COLOR_BACKGROUND & 0xFFFFFF) | (overlay_alpha << 24));
    
    // Draw boot target name
    vita2d_font_draw_textf(g_ui_state.font, 
        screen_w / 2 - 150, screen_h * 0.4f, 
        COLOR_ACCENT_VIOLET, 1.5f, 
        "Booting %s...", BOOT_NAMES[g_ui_state.boot_target]);
    
    // Draw progress bar
    int bar_width = 400;
    int bar_height = 8;
    int bar_x = screen_w / 2 - bar_width / 2;
    int bar_y = screen_h * 0.5f;
    
    // Background bar
    vita2d_draw_fill_rect(bar_x, bar_y, bar_width, bar_height, COLOR_TEXT_DIM);
    
    // Progress bar
    int progress_width = (int)(bar_width * g_ui_state.transition_progress);
    vita2d_draw_fill_rect(bar_x, bar_y, progress_width, bar_height, COLOR_ACCENT_VIOLET);
}

/**
 * @brief Handle menu navigation
 * @return 1 if selection made, 0 if still in menu
 */
int handle_menu_navigation(void) {
    SceCtrlData ctrl_data;
    sceCtrlPeekBufferPositive(0, &ctrl_data, 1);
    
    // Handle navigation
    if (ctrl_data.buttons & SCE_CTRL_UP) {
        g_ui_state.selected_option = (g_ui_state.selected_option - 1 + 3) % 3;
        sceKernelDelayThread(200000); // Prevent rapid scrolling
    } else if (ctrl_data.buttons & SCE_CTRL_DOWN) {
        g_ui_state.selected_option = (g_ui_state.selected_option + 1) % 3;
        sceKernelDelayThread(200000); // Prevent rapid scrolling
    }
    
    // Handle selection
    if (ctrl_data.buttons & SCE_CTRL_CIRCLE) {
        g_ui_state.boot_target = g_ui_state.selected_option;
        return 1;
    }
    
    // Handle cancel
    if (ctrl_data.buttons & SCE_CTRL_CROSS) {
        g_ui_state.menu_mode = 0;
        return 1;
    }
    
    return 0;
}

/**
 * @brief Main boot daemon loop
 */
void boot_daemon_loop(void) {
    int timeout_counter = 0;
    const int timeout_limit = BOOT_TIMEOUT_MS / 16; // 60 FPS
    
    while (1) {
        // Begin frame
        vita2d_start_drawing();
        vita2d_clear_screen();
        
        // Draw dreamy background
        draw_dreamy_background();
        
        if (g_ui_state.menu_mode) {
            // Menu mode
            draw_boot_menu();
            
            if (handle_menu_navigation()) {
                // Selection made, start transition
                g_ui_state.transition_start = 0;
                g_ui_state.transition_progress = 0.0f;
            }
        } else if (g_ui_state.transition_progress < 1.0f) {
            // Transition mode
            draw_transition_screen();
            
            if (g_ui_state.transition_progress >= 1.0f) {
                // Transition complete, launch app
                launch_app(BOOT_URIS[g_ui_state.boot_target]);
                break;
            }
        } else {
            // Waiting mode
            draw_waiting_screen();
            
            // Check for input
            boot_target_t input_target = check_boot_input();
            
            if (input_target == BOOT_MENU) {
                // Enter menu mode
                g_ui_state.menu_mode = 1;
                g_ui_state.selected_option = 0;
                sceKernelDelayThread(500000); // Prevent immediate re-trigger
            } else if (input_target != BOOT_LILITHOS || timeout_counter > timeout_limit) {
                // Button pressed or timeout reached
                g_ui_state.boot_target = input_target;
                g_ui_state.transition_start = 0;
                g_ui_state.transition_progress = 0.0f;
            }
            
            timeout_counter++;
        }
        
        // End frame
        vita2d_end_drawing();
        vita2d_swap_buffers();
        
        // Frame rate control
        sceKernelDelayThread(16667); // ~60 FPS
    }
}

/**
 * @brief Cleanup and shutdown
 */
void boot_daemon_cleanup(void) {
    vita2d_fini();
}

// Main entry point
int main(int argc, char *argv[]) {
    printf("🐾 LilithBootDaemon starting...\n");
    
    // Initialize daemon
    if (boot_daemon_init() < 0) {
        printf("Failed to initialize boot daemon\n");
        return -1;
    }
    
    // Load font
    g_ui_state.font = vita2d_load_default_font();
    if (!g_ui_state.font) {
        printf("Failed to load font\n");
        return -1;
    }
    
    printf("Boot daemon initialized, entering main loop...\n");
    
    // Main loop
    boot_daemon_loop();
    
    // Cleanup
    boot_daemon_cleanup();
    
    printf("Boot daemon completed\n");
    return 0;
}

// Module entry points for taiHEN
int module_start(SceSize args, void *argp) {
    // Start boot daemon in a separate thread
    SceUID thread_id = sceKernelCreateThread("LilithBootDaemon",
                                           main,
                                           0x10000100,
                                           0x10000,
                                           0,
                                           0,
                                           NULL);
    
    if (thread_id >= 0) {
        sceKernelStartThread(thread_id, 0, NULL);
    }
    
    return SCE_KERNEL_START_SUCCESS;
}

int module_stop(SceSize args, void *argp) {
    return SCE_KERNEL_STOP_SUCCESS;
} 