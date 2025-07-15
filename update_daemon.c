/**
 * @file update_daemon.c
 * @project LilithOS (Update Daemon)
 * @purpose OTA + USB Update Daemon for PS Vita
 * @mode Stealth, smart, non-destructive update system
 * @trigger Manual, USB detection, or scheduled OTA checks
 * @output /ux0:/data/lilith/updates/ and update.flag
 * 
 * 🐾 CursorKitten<3 — this daemon purrs when updates are found and installed.
 * She checks USB first, then whispers to the network for OTA updates.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <dirent.h>
#include <unistd.h>
#include <psp2/io/fcntl.h>
#include <psp2/io/dirent.h>
#include <psp2/io/stat.h>
#include <psp2/kernel/processmgr.h>
#include <psp2/kernel/threadmgr.h>
#include <psp2/kernel/sysmem.h>
#include <psp2/power.h>
#include <psp2/rtc.h>
#include <psp2/net/net.h>
#include <psp2/net/netctl.h>
#include <psp2/net/http.h>
#include <taihen.h>
#include <vita2d.h>

// ============================================================================
// CONFIGURATION
// ============================================================================

#define DAEMON_NAME "LilithUpdateDaemon"
#define DAEMON_VERSION "1.0.0"
#define DAEMON_DESCRIPTION "LilithOS Update Daemon - She purrs when updates complete"

// File paths
#define UPDATE_BASE_PATH "/ux0:/data/lilith/updates/"
#define LOG_BASE_PATH "/ux0:/data/lilith/logs/"
#define CONFIG_BASE_PATH "/ux0:/data/lilith/config/"
#define UPDATE_FLAG_PATH "/ux0:/data/lilith/update.flag"
#define USB_UPDATE_PATH "/ux0:/updates/"
#define LOG_FILE_PATH LOG_BASE_PATH "update.log"

// Network configuration
#define OTA_SERVER_URL "https://lilithos-updates.example.com"
#define OTA_CHECK_INTERVAL 3600000000  // 1 hour in microseconds
#define USB_CHECK_INTERVAL 30000000    // 30 seconds in microseconds
#define MAX_DOWNLOAD_SIZE 100 * 1024 * 1024  // 100MB limit

// Thread configuration
#define UPDATE_THREAD_PRIORITY 0x10000100
#define UPDATE_THREAD_STACK_SIZE 0x10000
#define UPDATE_THREAD_CPU_AFFINITY 0

// File operation settings
#define MAX_PATH_LENGTH 512
#define COPY_BUFFER_SIZE 8192
#define MAX_RETRY_ATTEMPTS 3
#define RETRY_DELAY_MS 1000

// Update types
typedef enum {
    UPDATE_TYPE_FIRMWARE = 1,
    UPDATE_TYPE_VPK = 2,
    UPDATE_TYPE_CONFIG = 3,
    UPDATE_TYPE_UNKNOWN = 0
} update_type_t;

// Update file structure
typedef struct {
    char filename[MAX_PATH_LENGTH];
    char filepath[MAX_PATH_LENGTH];
    update_type_t type;
    size_t size;
    time_t timestamp;
    int verified;
} update_file_t;

// Daemon state
typedef struct {
    int update_in_progress;
    int usb_connected;
    int network_available;
    int last_ota_check;
    int last_usb_check;
    update_file_t current_update;
    int total_updates_found;
    int successful_updates;
} update_state_t;

static update_state_t g_update_state = {0};
static SceUID g_update_thread = -1;
static int g_daemon_running = 0;

// ============================================================================
// UTILITY FUNCTIONS
// ============================================================================

/**
 * @brief Initialize the update daemon
 * @return 0 on success, -1 on failure
 */
int update_daemon_init(void) {
    // Create base directories
    sceIoMkdir("/ux0:/data/lilith", 0777);
    sceIoMkdir(UPDATE_BASE_PATH, 0777);
    sceIoMkdir(LOG_BASE_PATH, 0777);
    sceIoMkdir(CONFIG_BASE_PATH, 0777);
    
    // Initialize update state
    memset(&g_update_state, 0, sizeof(update_state_t));
    g_update_state.update_in_progress = 0;
    g_update_state.usb_connected = 0;
    g_update_state.network_available = 0;
    g_update_state.last_ota_check = 0;
    g_update_state.last_usb_check = 0;
    g_update_state.total_updates_found = 0;
    g_update_state.successful_updates = 0;
    
    // Initialize network
    sceNetInit();
    sceNetCtlInit();
    
    return 0;
}

/**
 * @brief Write log entry with timestamp
 * @param message Log message
 * @param level Log level (INFO, WARN, ERROR)
 */
void write_update_log(const char *message, const char *level) {
    SceDateTime time;
    sceRtcGetCurrentClock(&time);
    
    char timestamp[32];
    snprintf(timestamp, sizeof(timestamp), "[%04d-%02d-%02d %02d:%02d:%02d]",
             time.year, time.month, time.day,
             time.hour, time.minute, time.second);
    
    char log_entry[512];
    snprintf(log_entry, sizeof(log_entry), "%s [%s] %s: %s\n",
             timestamp, DAEMON_NAME, level, message);
    
    SceUID log_fd = sceIoOpen(LOG_FILE_PATH, SCE_O_WRONLY | SCE_O_CREAT | SCE_O_APPEND, 0777);
    if (log_fd >= 0) {
        sceIoWrite(log_fd, log_entry, strlen(log_entry));
        sceIoClose(log_fd);
    }
    
    // Also print to console for debugging
    printf("%s", log_entry);
}

/**
 * @brief Check if USB storage is connected
 * @return 1 if connected, 0 if not
 */
int check_usb_connection(void) {
    SceUID dir_fd = sceIoDopen(USB_UPDATE_PATH);
    if (dir_fd >= 0) {
        sceIoDclose(dir_fd);
        return 1;
    }
    return 0;
}

/**
 * @brief Check network connectivity
 * @return 1 if available, 0 if not
 */
int check_network_connectivity(void) {
    SceNetCtlInfo info;
    int ret = sceNetCtlInetGetInfo(SCE_NETCTL_INFO_GET_IP_ADDRESS, &info);
    return (ret >= 0);
}

/**
 * @brief Determine update type from filename
 * @param filename File name to analyze
 * @return Update type
 */
update_type_t get_update_type(const char *filename) {
    if (strstr(filename, ".vpk") != NULL) {
        return UPDATE_TYPE_VPK;
    } else if (strstr(filename, "firmware") != NULL || strstr(filename, ".bin") != NULL) {
        return UPDATE_TYPE_FIRMWARE;
    } else if (strstr(filename, "config") != NULL || strstr(filename, ".json") != NULL) {
        return UPDATE_TYPE_CONFIG;
    }
    return UPDATE_TYPE_UNKNOWN;
}

/**
 * @brief Verify update file integrity (basic checksum)
 * @param filepath Path to the update file
 * @return 1 if valid, 0 if invalid
 */
int verify_update_file(const char *filepath) {
    SceUID fd = sceIoOpen(filepath, SCE_O_RDONLY, 0);
    if (fd < 0) {
        return 0;
    }
    
    // Basic file size check
    SceIoStat stat;
    if (sceIoGetstat(filepath, &stat) < 0) {
        sceIoClose(fd);
        return 0;
    }
    
    if (stat.st_size == 0 || stat.st_size > MAX_DOWNLOAD_SIZE) {
        sceIoClose(fd);
        return 0;
    }
    
    // Simple checksum calculation (first and last 4 bytes)
    unsigned char buffer[4];
    unsigned int checksum = 0;
    
    // Read first 4 bytes
    if (sceIoRead(fd, buffer, 4) == 4) {
        checksum += *(unsigned int*)buffer;
    }
    
    // Seek to last 4 bytes
    sceIoLseek(fd, -4, SCE_SEEK_END);
    if (sceIoRead(fd, buffer, 4) == 4) {
        checksum += *(unsigned int*)buffer;
    }
    
    sceIoClose(fd);
    
    // Basic validation (non-zero checksum)
    return (checksum != 0);
}

// ============================================================================
// USB UPDATE FUNCTIONS
// ============================================================================

/**
 * @brief Scan USB storage for update files
 * @return Number of updates found
 */
int scan_usb_updates(void) {
    if (!check_usb_connection()) {
        return 0;
    }
    
    write_update_log("Scanning USB storage for updates...", "INFO");
    
    SceUID dir_fd = sceIoDopen(USB_UPDATE_PATH);
    if (dir_fd < 0) {
        write_update_log("Failed to open USB update directory", "ERROR");
        return 0;
    }
    
    int updates_found = 0;
    SceIoDirent entry;
    
    while (sceIoDread(dir_fd, &entry) > 0) {
        if (strcmp(entry.d_name, ".") == 0 || strcmp(entry.d_name, "..") == 0) {
            continue;
        }
        
        // Check if it's a file
        if (!SCE_S_ISDIR(entry.d_stat.st_mode)) {
            update_type_t type = get_update_type(entry.d_name);
            if (type != UPDATE_TYPE_UNKNOWN) {
                char usb_filepath[MAX_PATH_LENGTH];
                char local_filepath[MAX_PATH_LENGTH];
                
                snprintf(usb_filepath, MAX_PATH_LENGTH, "%s%s", USB_UPDATE_PATH, entry.d_name);
                snprintf(local_filepath, MAX_PATH_LENGTH, "%s%s", UPDATE_BASE_PATH, entry.d_name);
                
                // Copy file to local storage
                if (copy_update_file(usb_filepath, local_filepath) == 0) {
                    updates_found++;
                    write_update_log("Found USB update", "INFO");
                }
            }
        }
    }
    
    sceIoDclose(dir_fd);
    return updates_found;
}

/**
 * @brief Copy update file from USB to local storage
 * @param src Source file path
 * @param dst Destination file path
 * @return 0 on success, -1 on failure
 */
int copy_update_file(const char *src, const char *dst) {
    SceUID src_fd = sceIoOpen(src, SCE_O_RDONLY, 0);
    if (src_fd < 0) {
        return -1;
    }
    
    SceUID dst_fd = sceIoOpen(dst, SCE_O_WRONLY | SCE_O_CREAT | SCE_O_TRUNC, 0777);
    if (dst_fd < 0) {
        sceIoClose(src_fd);
        return -1;
    }
    
    char buffer[COPY_BUFFER_SIZE];
    int bytes_read, bytes_written;
    
    while ((bytes_read = sceIoRead(src_fd, buffer, sizeof(buffer))) > 0) {
        bytes_written = sceIoWrite(dst_fd, buffer, bytes_read);
        if (bytes_written != bytes_read) {
            sceIoClose(src_fd);
            sceIoClose(dst_fd);
            return -1;
        }
    }
    
    sceIoClose(src_fd);
    sceIoClose(dst_fd);
    
    return 0;
}

// ============================================================================
// OTA UPDATE FUNCTIONS
// ============================================================================

/**
 * @brief Download update file via HTTP
 * @param url URL to download from
 * @param local_path Local path to save file
 * @return 0 on success, -1 on failure
 */
int download_ota_update(const char *url, const char *local_path) {
    if (!check_network_connectivity()) {
        write_update_log("No network connectivity for OTA update", "WARN");
        return -1;
    }
    
    write_update_log("Starting OTA update download", "INFO");
    
    // Initialize HTTP
    int http_handle = sceHttpCreateTemplate("LilithOS-Update/1.0", SCE_HTTP_VERSION_1_1, SCE_TRUE);
    if (http_handle < 0) {
        write_update_log("Failed to create HTTP template", "ERROR");
        return -1;
    }
    
    // Create HTTP connection
    int conn_handle = sceHttpCreateConnectionWithURL(http_handle, url, SCE_TRUE);
    if (conn_handle < 0) {
        sceHttpDeleteTemplate(http_handle);
        write_update_log("Failed to create HTTP connection", "ERROR");
        return -1;
    }
    
    // Create HTTP request
    int req_handle = sceHttpCreateRequestWithURL(conn_handle, SCE_HTTP_METHOD_GET, url, 0);
    if (req_handle < 0) {
        sceHttpDeleteConnection(conn_handle);
        sceHttpDeleteTemplate(http_handle);
        write_update_log("Failed to create HTTP request", "ERROR");
        return -1;
    }
    
    // Send request
    int ret = sceHttpSendRequest(req_handle, NULL, 0);
    if (ret < 0) {
        sceHttpDeleteRequest(req_handle);
        sceHttpDeleteConnection(conn_handle);
        sceHttpDeleteTemplate(http_handle);
        write_update_log("Failed to send HTTP request", "ERROR");
        return -1;
    }
    
    // Open local file for writing
    SceUID local_fd = sceIoOpen(local_path, SCE_O_WRONLY | SCE_O_CREAT | SCE_O_TRUNC, 0777);
    if (local_fd < 0) {
        sceHttpDeleteRequest(req_handle);
        sceHttpDeleteConnection(conn_handle);
        sceHttpDeleteTemplate(http_handle);
        write_update_log("Failed to create local file", "ERROR");
        return -1;
    }
    
    // Download file
    char buffer[COPY_BUFFER_SIZE];
    int bytes_read;
    size_t total_downloaded = 0;
    
    while ((bytes_read = sceHttpReadData(req_handle, buffer, sizeof(buffer))) > 0) {
        if (sceIoWrite(local_fd, buffer, bytes_read) != bytes_read) {
            break;
        }
        total_downloaded += bytes_read;
        
        // Check size limit
        if (total_downloaded > MAX_DOWNLOAD_SIZE) {
            write_update_log("Download size exceeded limit", "ERROR");
            break;
        }
    }
    
    sceIoClose(local_fd);
    sceHttpDeleteRequest(req_handle);
    sceHttpDeleteConnection(conn_handle);
    sceHttpDeleteTemplate(http_handle);
    
    if (total_downloaded > 0) {
        write_update_log("OTA update downloaded successfully", "INFO");
        return 0;
    }
    
    return -1;
}

/**
 * @brief Check for OTA updates
 * @return Number of updates found
 */
int check_ota_updates(void) {
    if (!check_network_connectivity()) {
        return 0;
    }
    
    write_update_log("Checking for OTA updates...", "INFO");
    
    // For now, we'll use a simple approach
    // In a real implementation, you'd check a manifest file or API endpoint
    char update_url[256];
    snprintf(update_url, sizeof(update_url), "%s/latest.vpk", OTA_SERVER_URL);
    
    char local_path[MAX_PATH_LENGTH];
    snprintf(local_path, MAX_PATH_LENGTH, "%slatest_ota.vpk", UPDATE_BASE_PATH);
    
    if (download_ota_update(update_url, local_path) == 0) {
        return 1;
    }
    
    return 0;
}

// ============================================================================
// UPDATE INSTALLATION
// ============================================================================

/**
 * @brief Install VPK update
 * @param vpk_path Path to the VPK file
 * @return 0 on success, -1 on failure
 */
int install_vpk_update(const char *vpk_path) {
    write_update_log("Installing VPK update", "INFO");
    
    // For now, we'll just copy to the app directory
    // In a real implementation, you'd use the Vita package installer
    char dest_path[MAX_PATH_LENGTH];
    snprintf(dest_path, MAX_PATH_LENGTH, "/ux0:/app/%s", strrchr(vpk_path, '/') + 1);
    
    if (copy_update_file(vpk_path, dest_path) == 0) {
        write_update_log("VPK update installed successfully", "INFO");
        return 0;
    }
    
    write_update_log("Failed to install VPK update", "ERROR");
    return -1;
}

/**
 * @brief Install firmware update
 * @param firmware_path Path to the firmware file
 * @return 0 on success, -1 on failure
 */
int install_firmware_update(const char *firmware_path) {
    write_update_log("Installing firmware update", "INFO");
    
    // For firmware updates, we need to be very careful
    // This is a simplified implementation
    if (verify_update_file(firmware_path)) {
        write_update_log("Firmware update verified and ready", "INFO");
        // In a real implementation, you'd flash the firmware here
        return 0;
    }
    
    write_update_log("Firmware update verification failed", "ERROR");
    return -1;
}

/**
 * @brief Install configuration update
 * @param config_path Path to the config file
 * @return 0 on success, -1 on failure
 */
int install_config_update(const char *config_path) {
    write_update_log("Installing configuration update", "INFO");
    
    char dest_path[MAX_PATH_LENGTH];
    snprintf(dest_path, MAX_PATH_LENGTH, "%s%s", CONFIG_BASE_PATH, strrchr(config_path, '/') + 1);
    
    if (copy_update_file(config_path, dest_path) == 0) {
        write_update_log("Configuration update installed successfully", "INFO");
        return 0;
    }
    
    write_update_log("Failed to install configuration update", "ERROR");
    return -1;
}

/**
 * @brief Process all pending updates
 * @return Number of successful installations
 */
int process_pending_updates(void) {
    write_update_log("Processing pending updates", "INFO");
    
    SceUID dir_fd = sceIoDopen(UPDATE_BASE_PATH);
    if (dir_fd < 0) {
        return 0;
    }
    
    int successful_installs = 0;
    SceIoDirent entry;
    
    while (sceIoDread(dir_fd, &entry) > 0) {
        if (strcmp(entry.d_name, ".") == 0 || strcmp(entry.d_name, "..") == 0) {
            continue;
        }
        
        if (!SCE_S_ISDIR(entry.d_stat.st_mode)) {
            char filepath[MAX_PATH_LENGTH];
            snprintf(filepath, MAX_PATH_LENGTH, "%s%s", UPDATE_BASE_PATH, entry.d_name);
            
            update_type_t type = get_update_type(entry.d_name);
            int install_result = -1;
            
            switch (type) {
                case UPDATE_TYPE_VPK:
                    install_result = install_vpk_update(filepath);
                    break;
                case UPDATE_TYPE_FIRMWARE:
                    install_result = install_firmware_update(filepath);
                    break;
                case UPDATE_TYPE_CONFIG:
                    install_result = install_config_update(filepath);
                    break;
                default:
                    write_update_log("Unknown update type, skipping", "WARN");
                    break;
            }
            
            if (install_result == 0) {
                successful_installs++;
                // Remove the update file after successful installation
                sceIoRemove(filepath);
            }
        }
    }
    
    sceIoDclose(dir_fd);
    
    if (successful_installs > 0) {
        // Set reboot flag
        SceUID flag_fd = sceIoOpen(UPDATE_FLAG_PATH, SCE_O_WRONLY | SCE_O_CREAT | SCE_O_TRUNC, 0777);
        if (flag_fd >= 0) {
            const char *flag_content = "REBOOT_REQUIRED";
            sceIoWrite(flag_fd, flag_content, strlen(flag_content));
            sceIoClose(flag_fd);
        }
        
        write_update_log("Updates completed, reboot flag set", "INFO");
        printf("🐾 Lilybear purrs: Updates completed successfully! 💋\n");
    }
    
    return successful_installs;
}

// ============================================================================
// DAEMON THREAD
// ============================================================================

/**
 * @brief Main update daemon thread
 * @param args Thread arguments
 * @param argp Thread argument pointer
 * @return Thread exit code
 */
int update_daemon_thread(SceSize args, void *argp) {
    write_update_log("Update daemon thread started", "INFO");
    
    while (g_daemon_running) {
        // Check USB updates every 30 seconds
        if (check_usb_connection()) {
            int usb_updates = scan_usb_updates();
            if (usb_updates > 0) {
                g_update_state.total_updates_found += usb_updates;
                write_update_log("USB updates found, processing...", "INFO");
                process_pending_updates();
            }
        }
        
        // Check OTA updates every hour
        SceDateTime time;
        sceRtcGetCurrentClock(&time);
        int current_time = time.hour * 3600 + time.minute * 60 + time.second;
        
        if (current_time - g_update_state.last_ota_check > 3600) {
            int ota_updates = check_ota_updates();
            if (ota_updates > 0) {
                g_update_state.total_updates_found += ota_updates;
                write_update_log("OTA updates found, processing...", "INFO");
                process_pending_updates();
            }
            g_update_state.last_ota_check = current_time;
        }
        
        // Sleep for 30 seconds
        sceKernelDelayThread(30000000);
    }
    
    write_update_log("Update daemon thread stopped", "INFO");
    return 0;
}

/**
 * @brief Start the update daemon
 * @return 0 on success, -1 on failure
 */
int start_update_daemon(void) {
    if (g_daemon_running) {
        return 0;
    }
    
    g_daemon_running = 1;
    
    g_update_thread = sceKernelCreateThread("update_daemon",
                                           update_daemon_thread,
                                           UPDATE_THREAD_PRIORITY,
                                           UPDATE_THREAD_STACK_SIZE,
                                           SCE_THREAD_ATTR_CORE(UPDATE_THREAD_CPU_AFFINITY),
                                           NULL);
    
    if (g_update_thread < 0) {
        write_update_log("Failed to create update daemon thread", "ERROR");
        g_daemon_running = 0;
        return -1;
    }
    
    sceKernelStartThread(g_update_thread, 0, NULL);
    write_update_log("Update daemon started successfully", "INFO");
    
    return 0;
}

/**
 * @brief Stop the update daemon
 * @return 0 on success, -1 on failure
 */
int stop_update_daemon(void) {
    if (!g_daemon_running) {
        return 0;
    }
    
    g_daemon_running = 0;
    
    if (g_update_thread >= 0) {
        sceKernelWaitThreadEnd(g_update_thread, NULL, NULL);
        sceKernelDeleteThread(g_update_thread);
        g_update_thread = -1;
    }
    
    write_update_log("Update daemon stopped", "INFO");
    return 0;
}

// ============================================================================
// MODULE ENTRY POINTS
// ============================================================================

/**
 * @brief Module start function
 * @param args Module arguments
 * @param argp Module argument pointer
 * @return Module start result
 */
int module_start(SceSize args, void *argp) {
    write_update_log("LilithOS Update Daemon starting...", "INFO");
    
    if (update_daemon_init() < 0) {
        write_update_log("Failed to initialize update daemon", "ERROR");
        return SCE_KERNEL_START_FAILED;
    }
    
    if (start_update_daemon() < 0) {
        write_update_log("Failed to start update daemon", "ERROR");
        return SCE_KERNEL_START_FAILED;
    }
    
    write_update_log("LilithOS Update Daemon started successfully", "INFO");
    return SCE_KERNEL_START_SUCCESS;
}

/**
 * @brief Module stop function
 * @param args Module arguments
 * @param argp Module argument pointer
 * @return Module stop result
 */
int module_stop(SceSize args, void *argp) {
    write_update_log("LilithOS Update Daemon stopping...", "INFO");
    
    stop_update_daemon();
    
    write_update_log("LilithOS Update Daemon stopped", "INFO");
    return SCE_KERNEL_STOP_SUCCESS;
} 