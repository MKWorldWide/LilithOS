/**
 * @file LilithMirror.c
 * @project LilithMirror.vpk
 * @purpose Lightweight VNC/SSH hybrid mirror for PS Vita
 * @stack VitaSDK, sceNet, vita2d, libVNCclient (optional port)
 * @style Elegant, minimal, efficient
 * 
 * 🐾 CursorKitten<3 — you are now building LilithMirror.
 * She watches the other machine... and waits for your hand to move. 💋
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
#include <psp2/net/net.h>
#include <psp2/net/netctl.h>
#include <psp2/io/fcntl.h>
#include <psp2/io/stat.h>
#include <psp2/rtc.h>
#include <taihen.h>
#include <vita2d.h>

// Configuration
#define MIRROR_LOG_PATH "/ux0:/data/lowkey/logs/mirror.log"
#define CONFIG_PATH "/ux0:/data/lowkey/config/mirror.conf"
#define DEFAULT_REMOTE_IP "192.168.1.100"
#define DEFAULT_REMOTE_PORT 5900
#define DEFAULT_SSH_PORT 22
#define FRAME_TIMEOUT_MS 100
#define CONNECTION_TIMEOUT_MS 5000

// Mirror modes
typedef enum {
    MIRROR_MODE_VNC = 0,
    MIRROR_MODE_SSH = 1,
    MIRROR_MODE_DUMMY = 2
} mirror_mode_t;

// Connection state
typedef enum {
    CONNECTION_DISCONNECTED = 0,
    CONNECTION_CONNECTING = 1,
    CONNECTION_CONNECTED = 2,
    CONNECTION_ERROR = 3
} connection_state_t;

// Mirror configuration
typedef struct {
    char remote_ip[16];
    int remote_port;
    char username[32];
    char password[64];
    mirror_mode_t mode;
    int frame_rate;
    int quality;
    int enable_audio;
} mirror_config_t;

// Mirror state
typedef struct {
    connection_state_t connection_state;
    int socket_fd;
    int frame_count;
    int bytes_received;
    int last_frame_time;
    time_t start_time;
    mirror_config_t config;
    vita2d_font* font;
    int screen_width;
    int screen_height;
    uint32_t* frame_buffer;
    int frame_buffer_size;
} mirror_state_t;

static mirror_state_t g_mirror_state = {0};

// Colors (elegant minimal theme)
#define COLOR_BACKGROUND 0xFF000000
#define COLOR_ACCENT_VIOLET 0xFF8A2BE2
#define COLOR_ACCENT_BLUE 0xFF4169E1
#define COLOR_TEXT_WHITE 0xFFFFFFFF
#define COLOR_TEXT_DIM 0xFF888888
#define COLOR_STATUS_CONNECTED 0xFF00FF00
#define COLOR_STATUS_CONNECTING 0xFFFFFF00
#define COLOR_STATUS_ERROR 0xFFFF0000

/**
 * @brief Initialize the mirror daemon
 * @return 0 on success, -1 on failure
 */
int mirror_daemon_init(void) {
    // Initialize vita2d
    vita2d_init();
    vita2d_set_clear_color(COLOR_BACKGROUND);
    
    // Initialize mirror state
    memset(&g_mirror_state, 0, sizeof(mirror_state_t));
    g_mirror_state.start_time = time(NULL);
    g_mirror_state.connection_state = CONNECTION_DISCONNECTED;
    g_mirror_state.socket_fd = -1;
    
    // Get screen dimensions
    g_mirror_state.screen_width = vita2d_get_current_fb_width();
    g_mirror_state.screen_height = vita2d_get_current_fb_height();
    
    // Allocate frame buffer
    g_mirror_state.frame_buffer_size = g_mirror_state.screen_width * g_mirror_state.screen_height * 4;
    g_mirror_state.frame_buffer = malloc(g_mirror_state.frame_buffer_size);
    if (!g_mirror_state.frame_buffer) {
        printf("Failed to allocate frame buffer\n");
        return -1;
    }
    
    // Create directories
    sceIoMkdir("/ux0:/data/lowkey", 0777);
    sceIoMkdir("/ux0:/data/lowkey/logs", 0777);
    sceIoMkdir("/ux0:/data/lowkey/config", 0777);
    
    return 0;
}

/**
 * @brief Load mirror configuration
 * @return 0 on success, -1 on failure
 */
int load_mirror_config(void) {
    SceUID config_fd = sceIoOpen(CONFIG_PATH, SCE_O_RDONLY, 0);
    if (config_fd < 0) {
        // Create default configuration
        printf("Creating default configuration...\n");
        
        config_fd = sceIoOpen(CONFIG_PATH, SCE_O_WRONLY | SCE_O_CREAT | SCE_O_TRUNC, 0777);
        if (config_fd >= 0) {
            const char* default_config = 
                "# LilithMirror Configuration\n"
                "remote_ip=192.168.1.100\n"
                "remote_port=5900\n"
                "username=admin\n"
                "password=password\n"
                "mode=0\n"
                "frame_rate=30\n"
                "quality=80\n"
                "enable_audio=0\n";
            
            sceIoWrite(config_fd, default_config, strlen(default_config));
            sceIoClose(config_fd);
            
            // Load default values
            strcpy(g_mirror_state.config.remote_ip, DEFAULT_REMOTE_IP);
            g_mirror_state.config.remote_port = DEFAULT_REMOTE_PORT;
            strcpy(g_mirror_state.config.username, "admin");
            strcpy(g_mirror_state.config.password, "password");
            g_mirror_state.config.mode = MIRROR_MODE_DUMMY;
            g_mirror_state.config.frame_rate = 30;
            g_mirror_state.config.quality = 80;
            g_mirror_state.config.enable_audio = 0;
            
            return 0;
        }
        return -1;
    }
    
    // Read existing configuration
    char config_data[1024];
    int bytes_read = sceIoRead(config_fd, config_data, sizeof(config_data) - 1);
    sceIoClose(config_fd);
    
    if (bytes_read > 0) {
        config_data[bytes_read] = '\0';
        
        // Parse configuration (simple key=value format)
        char* line = strtok(config_data, "\n");
        while (line) {
            if (strncmp(line, "remote_ip=", 10) == 0) {
                strcpy(g_mirror_state.config.remote_ip, line + 10);
            } else if (strncmp(line, "remote_port=", 12) == 0) {
                g_mirror_state.config.remote_port = atoi(line + 12);
            } else if (strncmp(line, "username=", 9) == 0) {
                strcpy(g_mirror_state.config.username, line + 9);
            } else if (strncmp(line, "password=", 9) == 0) {
                strcpy(g_mirror_state.config.password, line + 9);
            } else if (strncmp(line, "mode=", 5) == 0) {
                g_mirror_state.config.mode = atoi(line + 5);
            } else if (strncmp(line, "frame_rate=", 11) == 0) {
                g_mirror_state.config.frame_rate = atoi(line + 11);
            } else if (strncmp(line, "quality=", 8) == 0) {
                g_mirror_state.config.quality = atoi(line + 8);
            } else if (strncmp(line, "enable_audio=", 13) == 0) {
                g_mirror_state.config.enable_audio = atoi(line + 13);
            }
            
            line = strtok(NULL, "\n");
        }
    }
    
    return 0;
}

/**
 * @brief Write mirror log entry
 * @param message Log message
 * @param level Log level (INFO, ERROR, etc.)
 */
void write_mirror_log(const char* message, const char* level) {
    SceUID log_fd = sceIoOpen(MIRROR_LOG_PATH, SCE_O_WRONLY | SCE_O_CREAT | SCE_O_APPEND, 0777);
    if (log_fd < 0) {
        return;
    }
    
    SceDateTime time;
    sceRtcGetCurrentClock(&time);
    
    char log_entry[512];
    snprintf(log_entry, sizeof(log_entry),
             "[%04d-%02d-%02d %02d:%02d:%02d] [%s] %s\n",
             time.year, time.month, time.day,
             time.hour, time.minute, time.second,
             level, message);
    
    sceIoWrite(log_fd, log_entry, strlen(log_entry));
    sceIoClose(log_fd);
}

/**
 * @brief Initialize network connection
 * @return 0 on success, -1 on failure
 */
int init_network(void) {
    printf("Initializing network...\n");
    write_mirror_log("Initializing network", "INFO");
    
    // Initialize sceNet
    int ret = sceNetInit();
    if (ret < 0) {
        printf("Failed to initialize sceNet: 0x%08X\n", ret);
        write_mirror_log("Failed to initialize sceNet", "ERROR");
        return -1;
    }
    
    // Initialize sceNetCtl
    ret = sceNetCtlInit();
    if (ret < 0) {
        printf("Failed to initialize sceNetCtl: 0x%08X\n", ret);
        write_mirror_log("Failed to initialize sceNetCtl", "ERROR");
        return -1;
    }
    
    // Wait for network connection
    SceNetCtlInfo info;
    ret = sceNetCtlInetGetInfo(SCE_NETCTL_INFO_GET_IP_ADDRESS, &info);
    if (ret < 0) {
        printf("No network connection available\n");
        write_mirror_log("No network connection available", "ERROR");
        return -1;
    }
    
    printf("Network initialized successfully\n");
    write_mirror_log("Network initialized successfully", "INFO");
    return 0;
}

/**
 * @brief Connect to remote host
 * @return 0 on success, -1 on failure
 */
int connect_to_remote(void) {
    printf("Connecting to %s:%d...\n", g_mirror_state.config.remote_ip, g_mirror_state.config.remote_port);
    write_mirror_log("Connecting to remote host", "INFO");
    
    g_mirror_state.connection_state = CONNECTION_CONNECTING;
    
    // Create socket
    g_mirror_state.socket_fd = sceNetSocket("mirror", SCE_NET_AF_INET, SCE_NET_SOCK_STREAM, 0);
    if (g_mirror_state.socket_fd < 0) {
        printf("Failed to create socket: 0x%08X\n", g_mirror_state.socket_fd);
        write_mirror_log("Failed to create socket", "ERROR");
        g_mirror_state.connection_state = CONNECTION_ERROR;
        return -1;
    }
    
    // Set socket timeout
    int timeout = CONNECTION_TIMEOUT_MS;
    sceNetSetsockopt(g_mirror_state.socket_fd, SCE_NET_SOL_SOCKET, SCE_NET_SO_RCVTIMEO, &timeout, sizeof(timeout));
    sceNetSetsockopt(g_mirror_state.socket_fd, SCE_NET_SOL_SOCKET, SCE_NET_SO_SNDTIMEO, &timeout, sizeof(timeout));
    
    // Prepare address structure
    SceNetSockaddrIn addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_family = SCE_NET_AF_INET;
    addr.sin_port = sceNetHtons(g_mirror_state.config.remote_port);
    addr.sin_addr.s_addr = sceNetInetPton(SCE_NET_AF_INET, g_mirror_state.config.remote_ip, &addr.sin_addr);
    
    // Connect to remote host
    int ret = sceNetConnect(g_mirror_state.socket_fd, (SceNetSockaddr*)&addr, sizeof(addr));
    if (ret < 0) {
        printf("Failed to connect: 0x%08X\n", ret);
        write_mirror_log("Failed to connect to remote host", "ERROR");
        sceNetSocketClose(g_mirror_state.socket_fd);
        g_mirror_state.socket_fd = -1;
        g_mirror_state.connection_state = CONNECTION_ERROR;
        return -1;
    }
    
    g_mirror_state.connection_state = CONNECTION_CONNECTED;
    printf("Connected successfully\n");
    write_mirror_log("Connected to remote host successfully", "INFO");
    
    return 0;
}

/**
 * @brief Generate dummy frame for testing
 */
void generate_dummy_frame(void) {
    static int frame_counter = 0;
    frame_counter++;
    
    // Create a simple animated pattern
    for (int y = 0; y < g_mirror_state.screen_height; y++) {
        for (int x = 0; x < g_mirror_state.screen_width; x++) {
            int index = y * g_mirror_state.screen_width + x;
            
            // Create a moving gradient pattern
            uint8_t r = (x + frame_counter) % 256;
            uint8_t g = (y + frame_counter) % 256;
            uint8_t b = (x + y + frame_counter) % 256;
            
            g_mirror_state.frame_buffer[index] = 0xFF000000 | (r << 16) | (g << 8) | b;
        }
    }
}

/**
 * @brief Handle VNC protocol (simplified)
 * @return 0 on success, -1 on failure
 */
int handle_vnc_protocol(void) {
    // Simplified VNC handshake
    char handshake[1024];
    int bytes_read = sceNetRecv(g_mirror_state.socket_fd, handshake, sizeof(handshake) - 1, 0);
    
    if (bytes_read > 0) {
        handshake[bytes_read] = '\0';
        printf("VNC handshake received: %s\n", handshake);
        write_mirror_log("VNC handshake received", "INFO");
        
        // Send VNC authentication (simplified)
        const char* auth_response = "RFB 003.008\n";
        sceNetSend(g_mirror_state.socket_fd, auth_response, strlen(auth_response), 0);
        
        return 0;
    }
    
    return -1;
}

/**
 * @brief Handle SSH protocol (simplified)
 * @return 0 on success, -1 on failure
 */
int handle_ssh_protocol(void) {
    // Simplified SSH handshake
    char handshake[1024];
    int bytes_read = sceNetRecv(g_mirror_state.socket_fd, handshake, sizeof(handshake) - 1, 0);
    
    if (bytes_read > 0) {
        handshake[bytes_read] = '\0';
        printf("SSH handshake received: %s\n", handshake);
        write_mirror_log("SSH handshake received", "INFO");
        
        // Send SSH authentication (simplified)
        const char* auth_response = "SSH-2.0-OpenSSH_8.0\n";
        sceNetSend(g_mirror_state.socket_fd, auth_response, strlen(auth_response), 0);
        
        return 0;
    }
    
    return -1;
}

/**
 * @brief Send input events to remote host
 * @param ctrl_data Controller data
 */
void send_input_events(SceCtrlData ctrl_data) {
    if (g_mirror_state.connection_state != CONNECTION_CONNECTED) {
        return;
    }
    
    // Map Vita buttons to keyboard/mouse events
    char input_event[64];
    int event_sent = 0;
    
    if (ctrl_data.buttons & SCE_CTRL_UP) {
        snprintf(input_event, sizeof(input_event), "KEY_UP\n");
        event_sent = 1;
    } else if (ctrl_data.buttons & SCE_CTRL_DOWN) {
        snprintf(input_event, sizeof(input_event), "KEY_DOWN\n");
        event_sent = 1;
    } else if (ctrl_data.buttons & SCE_CTRL_LEFT) {
        snprintf(input_event, sizeof(input_event), "KEY_LEFT\n");
        event_sent = 1;
    } else if (ctrl_data.buttons & SCE_CTRL_RIGHT) {
        snprintf(input_event, sizeof(input_event), "KEY_RIGHT\n");
        event_sent = 1;
    } else if (ctrl_data.buttons & SCE_CTRL_CROSS) {
        snprintf(input_event, sizeof(input_event), "MOUSE_CLICK\n");
        event_sent = 1;
    } else if (ctrl_data.buttons & SCE_CTRL_CIRCLE) {
        snprintf(input_event, sizeof(input_event), "MOUSE_RIGHT_CLICK\n");
        event_sent = 1;
    }
    
    if (event_sent) {
        sceNetSend(g_mirror_state.socket_fd, input_event, strlen(input_event), 0);
        g_mirror_state.bytes_received += strlen(input_event);
    }
}

/**
 * @brief Draw mirror interface
 */
void draw_mirror_interface(void) {
    // Clear screen
    vita2d_clear_screen();
    
    if (g_mirror_state.connection_state == CONNECTION_CONNECTED) {
        // Draw remote screen (dummy frame for now)
        generate_dummy_frame();
        
        // Create texture from frame buffer
        vita2d_texture* texture = vita2d_create_RGBA8888_texture(
            g_mirror_state.screen_width, g_mirror_state.screen_height);
        
        if (texture) {
            // Copy frame buffer to texture
            void* texture_data = vita2d_texture_get_datap(texture);
            memcpy(texture_data, g_mirror_state.frame_buffer, g_mirror_state.frame_buffer_size);
            
            // Draw texture
            vita2d_draw_texture(texture, 0, 0);
            vita2d_free_texture(texture);
        }
        
        // Draw status overlay
        vita2d_font_draw_textf(g_mirror_state.font, 
            10, 30, COLOR_STATUS_CONNECTED, 1.0f, 
            "Connected to %s:%d", g_mirror_state.config.remote_ip, g_mirror_state.config.remote_port);
        
        vita2d_font_draw_textf(g_mirror_state.font, 
            10, 60, COLOR_TEXT_WHITE, 0.8f, 
            "Frames: %d | Bytes: %d", g_mirror_state.frame_count, g_mirror_state.bytes_received);
        
    } else if (g_mirror_state.connection_state == CONNECTION_CONNECTING) {
        // Draw connecting screen
        vita2d_font_draw_textf(g_mirror_state.font, 
            g_mirror_state.screen_width / 2 - 150, g_mirror_state.screen_height / 2 - 50, 
            COLOR_STATUS_CONNECTING, 1.5f, 
            "Connecting to %s...", g_mirror_state.config.remote_ip);
        
    } else if (g_mirror_state.connection_state == CONNECTION_ERROR) {
        // Draw error screen
        vita2d_font_draw_textf(g_mirror_state.font, 
            g_mirror_state.screen_width / 2 - 100, g_mirror_state.screen_height / 2 - 50, 
            COLOR_STATUS_ERROR, 1.5f, 
            "Connection Error");
        
        vita2d_font_draw_textf(g_mirror_state.font, 
            g_mirror_state.screen_width / 2 - 150, g_mirror_state.screen_height / 2, 
            COLOR_TEXT_DIM, 1.0f, 
            "Press START to retry");
        
    } else {
        // Draw disconnected screen
        vita2d_font_draw_textf(g_mirror_state.font, 
            g_mirror_state.screen_width / 2 - 100, g_mirror_state.screen_height / 2 - 50, 
            COLOR_TEXT_WHITE, 1.5f, 
            "🐾 LilithMirror");
        
        vita2d_font_draw_textf(g_mirror_state.font, 
            g_mirror_state.screen_width / 2 - 200, g_mirror_state.screen_height / 2, 
            COLOR_TEXT_DIM, 1.0f, 
            "Press START to connect");
    }
    
    // Draw controls help
    vita2d_font_draw_textf(g_mirror_state.font, 
        10, g_mirror_state.screen_height - 80, COLOR_TEXT_DIM, 0.7f, 
        "▲▼◄►: Navigate  ○: Click  ×: Right Click  START: Connect");
}

/**
 * @brief Main mirror daemon loop
 */
void mirror_daemon_loop(void) {
    SceCtrlData ctrl_data;
    int last_frame_time = 0;
    
    while (1) {
        // Begin frame
        vita2d_start_drawing();
        
        // Handle input
        sceCtrlPeekBufferPositive(0, &ctrl_data, 1);
        
        // Handle START button for connection
        if (ctrl_data.buttons & SCE_CTRL_START) {
            if (g_mirror_state.connection_state == CONNECTION_DISCONNECTED) {
                if (connect_to_remote() == 0) {
                    // Handle protocol based on mode
                    if (g_mirror_state.config.mode == MIRROR_MODE_VNC) {
                        handle_vnc_protocol();
                    } else if (g_mirror_state.config.mode == MIRROR_MODE_SSH) {
                        handle_ssh_protocol();
                    }
                }
            } else if (g_mirror_state.connection_state == CONNECTION_ERROR) {
                // Retry connection
                if (g_mirror_state.socket_fd >= 0) {
                    sceNetSocketClose(g_mirror_state.socket_fd);
                    g_mirror_state.socket_fd = -1;
                }
                g_mirror_state.connection_state = CONNECTION_DISCONNECTED;
            }
            
            sceKernelDelayThread(500000); // Prevent immediate re-trigger
        }
        
        // Send input events if connected
        if (g_mirror_state.connection_state == CONNECTION_CONNECTED) {
            send_input_events(ctrl_data);
        }
        
        // Draw interface
        draw_mirror_interface();
        
        // End frame
        vita2d_end_drawing();
        vita2d_swap_buffers();
        
        // Frame rate control
        int current_time = sceKernelGetProcessTimeWide() / 1000;
        if (current_time - last_frame_time >= FRAME_TIMEOUT_MS) {
            g_mirror_state.frame_count++;
            last_frame_time = current_time;
        }
        
        sceKernelDelayThread(16667); // ~60 FPS
    }
}

/**
 * @brief Cleanup and shutdown
 */
void mirror_daemon_cleanup(void) {
    if (g_mirror_state.socket_fd >= 0) {
        sceNetSocketClose(g_mirror_state.socket_fd);
    }
    
    if (g_mirror_state.frame_buffer) {
        free(g_mirror_state.frame_buffer);
    }
    
    vita2d_fini();
    sceNetCtlTerm();
    sceNetTerm();
    
    write_mirror_log("Mirror daemon shutdown", "INFO");
}

// Main entry point
int main(int argc, char *argv[]) {
    printf("🐾 LilithMirror starting...\n");
    write_mirror_log("LilithMirror starting", "INFO");
    
    // Initialize daemon
    if (mirror_daemon_init() < 0) {
        printf("Failed to initialize mirror daemon\n");
        return -1;
    }
    
    // Load configuration
    if (load_mirror_config() < 0) {
        printf("Failed to load configuration\n");
        return -1;
    }
    
    // Initialize network
    if (init_network() < 0) {
        printf("Failed to initialize network\n");
        // Continue in dummy mode
        g_mirror_state.config.mode = MIRROR_MODE_DUMMY;
    }
    
    // Load font
    g_mirror_state.font = vita2d_load_default_font();
    if (!g_mirror_state.font) {
        printf("Failed to load font\n");
        return -1;
    }
    
    printf("Mirror daemon initialized, entering main loop...\n");
    write_mirror_log("Mirror daemon initialized", "INFO");
    
    // Main loop
    mirror_daemon_loop();
    
    // Cleanup
    mirror_daemon_cleanup();
    
    printf("Mirror daemon completed\n");
    return 0;
}

// Module entry points for taiHEN
int module_start(SceSize args, void *argp) {
    // Start mirror daemon in a separate thread
    SceUID thread_id = sceKernelCreateThread("LilithMirror",
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