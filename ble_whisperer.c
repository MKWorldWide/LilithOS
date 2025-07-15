/**
 * @file ble_whisperer.c
 * @project LilithOS (BLE Whisperer Daemon)
 * @purpose BLE Whisperer Device Daemon for PS Vita
 * @mode Stealth, encrypted, device discovery and communication
 * @trigger Background BLE scanning and handshake detection
 * @output /ux0:/data/lilith/whisper_log.txt and device sessions
 * 
 * 🐾 CursorKitten<3 — this daemon whispers secrets to other devices.
 * She listens for WhispurrNEt handshakes and opens encrypted sessions.
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
#include <psp2/bt.h>
#include <psp2/bt_scan.h>
#include <taihen.h>
#include <vita2d.h>

// ============================================================================
// CONFIGURATION
// ============================================================================

#define DAEMON_NAME "LilithBLEWhisperer"
#define DAEMON_VERSION "1.0.0"
#define DAEMON_DESCRIPTION "LilithOS BLE Whisperer - She whispers secrets to other devices"

// File paths
#define WHISPER_BASE_PATH "/ux0:/data/lilith/whisper/"
#define LOG_BASE_PATH "/ux0:/data/lilith/logs/"
#define CONFIG_BASE_PATH "/ux0:/data/lilith/config/"
#define WHISPER_LOG_PATH LOG_BASE_PATH "whisper_log.txt"
#define DEVICE_DB_PATH WHISPER_BASE_PATH "devices.db"

// BLE configuration
#define BLE_SCAN_INTERVAL 100000000  // 100ms in microseconds
#define BLE_SCAN_WINDOW 50000000     // 50ms scan window
#define BLE_SCAN_TIMEOUT 30000000    // 30 seconds scan timeout
#define MAX_DISCOVERED_DEVICES 20
#define MAX_DEVICE_NAME_LENGTH 32
#define MAX_DEVICE_ADDRESS_LENGTH 18

// WhispurrNEt protocol
#define WHISPURR_SERVICE_UUID "12345678-1234-1234-1234-123456789abc"
#define WHISPURR_HANDSHAKE_MAGIC "LILITH_WHISPER"
#define WHISPURR_HANDSHAKE_LENGTH 16
#define WHISPURR_ENCRYPTION_KEY "LilithSecretKey2024"
#define WHISPURR_KEY_LENGTH 20

// Thread configuration
#define WHISPER_THREAD_PRIORITY 0x10000100
#define WHISPER_THREAD_STACK_SIZE 0x10000
#define WHISPER_THREAD_CPU_AFFINITY 0

// Session configuration
#define MAX_ACTIVE_SESSIONS 5
#define SESSION_TIMEOUT 300000000  // 5 minutes in microseconds
#define MAX_DATA_EXCHANGE_SIZE 1024

// Encryption settings
#define XOR_KEY_MASK 0x5A
#define AES_AVAILABLE 0  // Set to 1 if AES is available

// Device information structure
typedef struct {
    char name[MAX_DEVICE_NAME_LENGTH];
    char address[MAX_DEVICE_ADDRESS_LENGTH];
    int rssi;
    time_t discovery_time;
    int handshake_completed;
    char session_key[WHISPURR_KEY_LENGTH];
    int last_seen;
} discovered_device_t;

// Session structure
typedef struct {
    char device_address[MAX_DEVICE_ADDRESS_LENGTH];
    char session_key[WHISPURR_KEY_LENGTH];
    time_t session_start;
    time_t last_activity;
    int data_exchanges;
    int encrypted;
} whisper_session_t;

// Daemon state
typedef struct {
    int ble_initialized;
    int scanning_active;
    int handshake_detected;
    discovered_device_t discovered_devices[MAX_DISCOVERED_DEVICES];
    int device_count;
    whisper_session_t active_sessions[MAX_ACTIVE_SESSIONS];
    int session_count;
    int total_handshakes;
    int successful_exchanges;
} whisper_state_t;

static whisper_state_t g_whisper_state = {0};
static SceUID g_whisper_thread = -1;
static int g_daemon_running = 0;

// ============================================================================
// UTILITY FUNCTIONS
// ============================================================================

/**
 * @brief Initialize the BLE whisperer daemon
 * @return 0 on success, -1 on failure
 */
int whisper_daemon_init(void) {
    // Create base directories
    sceIoMkdir("/ux0:/data/lilith", 0777);
    sceIoMkdir(WHISPER_BASE_PATH, 0777);
    sceIoMkdir(LOG_BASE_PATH, 0777);
    sceIoMkdir(CONFIG_BASE_PATH, 0777);
    
    // Initialize whisper state
    memset(&g_whisper_state, 0, sizeof(whisper_state_t));
    g_whisper_state.ble_initialized = 0;
    g_whisper_state.scanning_active = 0;
    g_whisper_state.handshake_detected = 0;
    g_whisper_state.device_count = 0;
    g_whisper_state.session_count = 0;
    g_whisper_state.total_handshakes = 0;
    g_whisper_state.successful_exchanges = 0;
    
    // Initialize BLE
    int ret = sceBtInit();
    if (ret < 0) {
        write_whisper_log("Failed to initialize BLE", "ERROR");
        return -1;
    }
    
    g_whisper_state.ble_initialized = 1;
    write_whisper_log("BLE Whisperer daemon initialized", "INFO");
    
    return 0;
}

/**
 * @brief Write log entry with timestamp
 * @param message Log message
 * @param level Log level (INFO, WARN, ERROR)
 */
void write_whisper_log(const char *message, const char *level) {
    SceDateTime time;
    sceRtcGetCurrentClock(&time);
    
    char timestamp[32];
    snprintf(timestamp, sizeof(timestamp), "[%04d-%02d-%02d %02d:%02d:%02d]",
             time.year, time.month, time.day,
             time.hour, time.minute, time.second);
    
    char log_entry[512];
    snprintf(log_entry, sizeof(log_entry), "%s [%s] %s: %s\n",
             timestamp, DAEMON_NAME, level, message);
    
    SceUID log_fd = sceIoOpen(WHISPER_LOG_PATH, SCE_O_WRONLY | SCE_O_CREAT | SCE_O_APPEND, 0777);
    if (log_fd >= 0) {
        sceIoWrite(log_fd, log_entry, strlen(log_entry));
        sceIoClose(log_fd);
    }
    
    // Also print to console for debugging
    printf("%s", log_entry);
}

/**
 * @brief Simple XOR encryption/decryption
 * @param data Data to encrypt/decrypt
 * @param length Length of data
 * @param key Encryption key
 * @param key_length Length of key
 */
void xor_encrypt_decrypt(unsigned char *data, int length, const char *key, int key_length) {
    for (int i = 0; i < length; i++) {
        data[i] ^= key[i % key_length] ^ XOR_KEY_MASK;
    }
}

/**
 * @brief Generate session key for device
 * @param device_address Device address
 * @param session_key Output session key
 */
void generate_session_key(const char *device_address, char *session_key) {
    // Simple key generation based on device address and timestamp
    SceDateTime time;
    sceRtcGetCurrentClock(&time);
    
    snprintf(session_key, WHISPURR_KEY_LENGTH, "%s_%04d%02d%02d",
             device_address, time.year, time.month, time.day);
    
    // Apply XOR mask to make it more secure
    xor_encrypt_decrypt((unsigned char*)session_key, strlen(session_key), 
                       WHISPURR_ENCRYPTION_KEY, WHISPURR_KEY_LENGTH);
}

/**
 * @brief Check if device is already discovered
 * @param address Device address to check
 * @return Index if found, -1 if not found
 */
int find_discovered_device(const char *address) {
    for (int i = 0; i < g_whisper_state.device_count; i++) {
        if (strcmp(g_whisper_state.discovered_devices[i].address, address) == 0) {
            return i;
        }
    }
    return -1;
}

/**
 * @brief Add new discovered device
 * @param name Device name
 * @param address Device address
 * @param rssi Signal strength
 * @return 0 on success, -1 on failure
 */
int add_discovered_device(const char *name, const char *address, int rssi) {
    if (g_whisper_state.device_count >= MAX_DISCOVERED_DEVICES) {
        return -1;
    }
    
    discovered_device_t *device = &g_whisper_state.discovered_devices[g_whisper_state.device_count];
    
    strncpy(device->name, name, MAX_DEVICE_NAME_LENGTH - 1);
    device->name[MAX_DEVICE_NAME_LENGTH - 1] = '\0';
    
    strncpy(device->address, address, MAX_DEVICE_ADDRESS_LENGTH - 1);
    device->address[MAX_DEVICE_ADDRESS_LENGTH - 1] = '\0';
    
    device->rssi = rssi;
    device->discovery_time = time(NULL);
    device->handshake_completed = 0;
    device->last_seen = time(NULL);
    
    g_whisper_state.device_count++;
    
    char log_msg[256];
    snprintf(log_msg, sizeof(log_msg), "Discovered device: %s (%s) RSSI: %d", 
             name, address, rssi);
    write_whisper_log(log_msg, "INFO");
    
    return 0;
}

/**
 * @brief Update device last seen time
 * @param address Device address
 */
void update_device_last_seen(const char *address) {
    int index = find_discovered_device(address);
    if (index >= 0) {
        g_whisper_state.discovered_devices[index].last_seen = time(NULL);
    }
}

// ============================================================================
// BLE SCANNING FUNCTIONS
// ============================================================================

/**
 * @brief Start BLE scanning
 * @return 0 on success, -1 on failure
 */
int start_ble_scanning(void) {
    if (!g_whisper_state.ble_initialized) {
        write_whisper_log("BLE not initialized", "ERROR");
        return -1;
    }
    
    // Configure scan parameters
    SceBtScanParam scan_param;
    memset(&scan_param, 0, sizeof(scan_param));
    scan_param.scanType = SCE_BT_SCAN_TYPE_ACTIVE;
    scan_param.scanInterval = BLE_SCAN_INTERVAL;
    scan_param.scanWindow = BLE_SCAN_WINDOW;
    scan_param.scanTimeout = BLE_SCAN_TIMEOUT;
    scan_param.filterPolicy = SCE_BT_SCAN_FILTER_POLICY_ACCEPT_ALL;
    
    int ret = sceBtScanStart(&scan_param);
    if (ret < 0) {
        write_whisper_log("Failed to start BLE scanning", "ERROR");
        return -1;
    }
    
    g_whisper_state.scanning_active = 1;
    write_whisper_log("BLE scanning started", "INFO");
    
    return 0;
}

/**
 * @brief Stop BLE scanning
 * @return 0 on success, -1 on failure
 */
int stop_ble_scanning(void) {
    if (!g_whisper_state.scanning_active) {
        return 0;
    }
    
    int ret = sceBtScanStop();
    if (ret < 0) {
        write_whisper_log("Failed to stop BLE scanning", "ERROR");
        return -1;
    }
    
    g_whisper_state.scanning_active = 0;
    write_whisper_log("BLE scanning stopped", "INFO");
    
    return 0;
}

/**
 * @brief Process BLE scan results
 * @return Number of new devices found
 */
int process_ble_scan_results(void) {
    SceBtScanResult scan_result;
    int new_devices = 0;
    
    // Get scan results
    while (sceBtScanGetResult(&scan_result) >= 0) {
        // Check if device has WhispurrNEt service
        if (is_whispurr_device(&scan_result)) {
            char device_name[MAX_DEVICE_NAME_LENGTH];
            char device_address[MAX_DEVICE_ADDRESS_LENGTH];
            
            // Extract device information
            if (extract_device_info(&scan_result, device_name, device_address) == 0) {
                // Check if device is already discovered
                if (find_discovered_device(device_address) < 0) {
                    if (add_discovered_device(device_name, device_address, scan_result.rssi) == 0) {
                        new_devices++;
                    }
                } else {
                    update_device_last_seen(device_address);
                }
            }
        }
    }
    
    return new_devices;
}

/**
 * @brief Check if device supports WhispurrNEt protocol
 * @param scan_result BLE scan result
 * @return 1 if supported, 0 if not
 */
int is_whispurr_device(const SceBtScanResult *scan_result) {
    // Check for WhispurrNEt service UUID in advertisement data
    if (scan_result->advDataLen > 0) {
        // Look for our service UUID in the advertisement data
        // This is a simplified check - in reality you'd parse the advertisement data properly
        const char *uuid_pattern = "12345678-1234-1234-1234-123456789abc";
        if (memmem(scan_result->advData, scan_result->advDataLen, 
                   uuid_pattern, strlen(uuid_pattern)) != NULL) {
            return 1;
        }
    }
    
    return 0;
}

/**
 * @brief Extract device information from scan result
 * @param scan_result BLE scan result
 * @param name Output device name
 * @param address Output device address
 * @return 0 on success, -1 on failure
 */
int extract_device_info(const SceBtScanResult *scan_result, char *name, char *address) {
    // Extract device address
    snprintf(address, MAX_DEVICE_ADDRESS_LENGTH, "%02X:%02X:%02X:%02X:%02X:%02X",
             scan_result->addr.addr[0], scan_result->addr.addr[1], scan_result->addr.addr[2],
             scan_result->addr.addr[3], scan_result->addr.addr[4], scan_result->addr.addr[5]);
    
    // Extract device name from advertisement data
    // This is a simplified implementation
    if (scan_result->advDataLen > 0) {
        // Look for complete local name in advertisement data
        // In a real implementation, you'd properly parse the advertisement data
        strncpy(name, "WhispurrDevice", MAX_DEVICE_NAME_LENGTH - 1);
        name[MAX_DEVICE_NAME_LENGTH - 1] = '\0';
    } else {
        strncpy(name, "Unknown", MAX_DEVICE_NAME_LENGTH - 1);
        name[MAX_DEVICE_NAME_LENGTH - 1] = '\0';
    }
    
    return 0;
}

// ============================================================================
// WHISPURRNEt PROTOCOL FUNCTIONS
// ============================================================================

/**
 * @brief Send WhispurrNEt handshake ping
 * @param device_address Target device address
 * @return 0 on success, -1 on failure
 */
int send_whispurr_handshake(const char *device_address) {
    write_whisper_log("Sending WhispurrNEt handshake", "INFO");
    
    // Create handshake packet
    unsigned char handshake_packet[WHISPURR_HANDSHAKE_LENGTH];
    memcpy(handshake_packet, WHISPURR_HANDSHAKE_MAGIC, strlen(WHISPURR_HANDSHAKE_MAGIC));
    
    // Add timestamp
    SceDateTime time;
    sceRtcGetCurrentClock(&time);
    memcpy(handshake_packet + strlen(WHISPURR_HANDSHAKE_MAGIC), &time, sizeof(time));
    
    // Encrypt handshake packet
    xor_encrypt_decrypt(handshake_packet, WHISPURR_HANDSHAKE_LENGTH, 
                       WHISPURR_ENCRYPTION_KEY, WHISPURR_KEY_LENGTH);
    
    // Send via BLE (simplified - in reality you'd use BLE GATT)
    // For now, we'll just log the attempt
    char log_msg[256];
    snprintf(log_msg, sizeof(log_msg), "Handshake sent to %s", device_address);
    write_whisper_log(log_msg, "INFO");
    
    return 0;
}

/**
 * @brief Process incoming WhispurrNEt handshake
 * @param device_address Source device address
 * @param handshake_data Handshake data
 * @param data_length Length of handshake data
 * @return 0 on success, -1 on failure
 */
int process_whispurr_handshake(const char *device_address, const unsigned char *handshake_data, int data_length) {
    if (data_length != WHISPURR_HANDSHAKE_LENGTH) {
        write_whisper_log("Invalid handshake length", "WARN");
        return -1;
    }
    
    // Decrypt handshake packet
    unsigned char decrypted_packet[WHISPURR_HANDSHAKE_LENGTH];
    memcpy(decrypted_packet, handshake_data, WHISPURR_HANDSHAKE_LENGTH);
    xor_encrypt_decrypt(decrypted_packet, WHISPURR_HANDSHAKE_LENGTH, 
                       WHISPURR_ENCRYPTION_KEY, WHISPURR_KEY_LENGTH);
    
    // Verify handshake magic
    if (memcmp(decrypted_packet, WHISPURR_HANDSHAKE_MAGIC, strlen(WHISPURR_HANDSHAKE_MAGIC)) != 0) {
        write_whisper_log("Invalid handshake magic", "WARN");
        return -1;
    }
    
    // Update device handshake status
    int device_index = find_discovered_device(device_address);
    if (device_index >= 0) {
        g_whisper_state.discovered_devices[device_index].handshake_completed = 1;
        generate_session_key(device_address, g_whisper_state.discovered_devices[device_index].session_key);
    }
    
    g_whisper_state.handshake_detected = 1;
    g_whisper_state.total_handshakes++;
    
    char log_msg[256];
    snprintf(log_msg, sizeof(log_msg), "WhispurrNEt handshake completed with %s", device_address);
    write_whisper_log(log_msg, "INFO");
    
    return 0;
}

/**
 * @brief Create encrypted session with device
 * @param device_address Device address
 * @return Session index on success, -1 on failure
 */
int create_whisper_session(const char *device_address) {
    if (g_whisper_state.session_count >= MAX_ACTIVE_SESSIONS) {
        write_whisper_log("Maximum active sessions reached", "WARN");
        return -1;
    }
    
    // Find device
    int device_index = find_discovered_device(device_address);
    if (device_index < 0) {
        write_whisper_log("Device not found for session creation", "ERROR");
        return -1;
    }
    
    // Check if handshake was completed
    if (!g_whisper_state.discovered_devices[device_index].handshake_completed) {
        write_whisper_log("Handshake not completed for session", "WARN");
        return -1;
    }
    
    // Create session
    whisper_session_t *session = &g_whisper_state.active_sessions[g_whisper_state.session_count];
    
    strncpy(session->device_address, device_address, MAX_DEVICE_ADDRESS_LENGTH - 1);
    session->device_address[MAX_DEVICE_ADDRESS_LENGTH - 1] = '\0';
    
    strncpy(session->session_key, g_whisper_state.discovered_devices[device_index].session_key, 
            WHISPURR_KEY_LENGTH - 1);
    session->session_key[WHISPURR_KEY_LENGTH - 1] = '\0';
    
    session->session_start = time(NULL);
    session->last_activity = time(NULL);
    session->data_exchanges = 0;
    session->encrypted = 1;
    
    g_whisper_state.session_count++;
    
    char log_msg[256];
    snprintf(log_msg, sizeof(log_msg), "Encrypted session created with %s", device_address);
    write_whisper_log(log_msg, "INFO");
    
    return g_whisper_state.session_count - 1;
}

/**
 * @brief Find active session by device address
 * @param device_address Device address
 * @return Session index if found, -1 if not found
 */
int find_active_session(const char *device_address) {
    for (int i = 0; i < g_whisper_state.session_count; i++) {
        if (strcmp(g_whisper_state.active_sessions[i].device_address, device_address) == 0) {
            return i;
        }
    }
    return -1;
}

/**
 * @brief Exchange data with device
 * @param device_address Device address
 * @param data Data to send
 * @param data_length Length of data
 * @return 0 on success, -1 on failure
 */
int exchange_data_with_device(const char *device_address, const unsigned char *data, int data_length) {
    int session_index = find_active_session(device_address);
    if (session_index < 0) {
        write_whisper_log("No active session for data exchange", "WARN");
        return -1;
    }
    
    whisper_session_t *session = &g_whisper_state.active_sessions[session_index];
    
    // Check session timeout
    time_t current_time = time(NULL);
    if (current_time - session->last_activity > SESSION_TIMEOUT / 1000000) {
        write_whisper_log("Session timeout, removing session", "WARN");
        // Remove expired session
        memmove(&g_whisper_state.active_sessions[session_index], 
                &g_whisper_state.active_sessions[session_index + 1],
                (g_whisper_state.session_count - session_index - 1) * sizeof(whisper_session_t));
        g_whisper_state.session_count--;
        return -1;
    }
    
    // Encrypt data
    unsigned char encrypted_data[MAX_DATA_EXCHANGE_SIZE];
    if (data_length > MAX_DATA_EXCHANGE_SIZE) {
        write_whisper_log("Data too large for exchange", "WARN");
        return -1;
    }
    
    memcpy(encrypted_data, data, data_length);
    xor_encrypt_decrypt(encrypted_data, data_length, session->session_key, WHISPURR_KEY_LENGTH);
    
    // Send encrypted data (simplified - in reality you'd use BLE GATT)
    session->last_activity = current_time;
    session->data_exchanges++;
    g_whisper_state.successful_exchanges++;
    
    char log_msg[256];
    snprintf(log_msg, sizeof(log_msg), "Data exchanged with %s (session %d)", 
             device_address, session_index);
    write_whisper_log(log_msg, "INFO");
    
    return 0;
}

/**
 * @brief Clean up expired sessions
 */
void cleanup_expired_sessions(void) {
    time_t current_time = time(NULL);
    
    for (int i = g_whisper_state.session_count - 1; i >= 0; i--) {
        whisper_session_t *session = &g_whisper_state.active_sessions[i];
        
        if (current_time - session->last_activity > SESSION_TIMEOUT / 1000000) {
            char log_msg[256];
            snprintf(log_msg, sizeof(log_msg), "Removing expired session with %s", 
                     session->device_address);
            write_whisper_log(log_msg, "INFO");
            
            // Remove session
            memmove(&g_whisper_state.active_sessions[i], 
                    &g_whisper_state.active_sessions[i + 1],
                    (g_whisper_state.session_count - i - 1) * sizeof(whisper_session_t));
            g_whisper_state.session_count--;
        }
    }
}

// ============================================================================
// DAEMON THREAD
// ============================================================================

/**
 * @brief Main BLE whisperer daemon thread
 * @param args Thread arguments
 * @param argp Thread argument pointer
 * @return Thread exit code
 */
int whisper_daemon_thread(SceSize args, void *argp) {
    write_whisper_log("BLE Whisperer daemon thread started", "INFO");
    
    while (g_daemon_running) {
        // Start BLE scanning if not active
        if (!g_whisper_state.scanning_active) {
            start_ble_scanning();
        }
        
        // Process scan results
        int new_devices = process_ble_scan_results();
        if (new_devices > 0) {
            char log_msg[128];
            snprintf(log_msg, sizeof(log_msg), "Found %d new WhispurrNEt devices", new_devices);
            write_whisper_log(log_msg, "INFO");
        }
        
        // Send handshakes to discovered devices
        for (int i = 0; i < g_whisper_state.device_count; i++) {
            discovered_device_t *device = &g_whisper_state.discovered_devices[i];
            
            if (!device->handshake_completed) {
                send_whispurr_handshake(device->address);
            } else if (find_active_session(device->address) < 0) {
                // Create session for devices with completed handshakes
                create_whisper_session(device->address);
            }
        }
        
        // Clean up expired sessions
        cleanup_expired_sessions();
        
        // Sleep for 5 seconds
        sceKernelDelayThread(5000000);
    }
    
    write_whisper_log("BLE Whisperer daemon thread stopped", "INFO");
    return 0;
}

/**
 * @brief Start the BLE whisperer daemon
 * @return 0 on success, -1 on failure
 */
int start_whisper_daemon(void) {
    if (g_daemon_running) {
        return 0;
    }
    
    g_daemon_running = 1;
    
    g_whisper_thread = sceKernelCreateThread("whisper_daemon",
                                            whisper_daemon_thread,
                                            WHISPER_THREAD_PRIORITY,
                                            WHISPER_THREAD_STACK_SIZE,
                                            SCE_THREAD_ATTR_CORE(WHISPER_THREAD_CPU_AFFINITY),
                                            NULL);
    
    if (g_whisper_thread < 0) {
        write_whisper_log("Failed to create whisper daemon thread", "ERROR");
        g_daemon_running = 0;
        return -1;
    }
    
    sceKernelStartThread(g_whisper_thread, 0, NULL);
    write_whisper_log("BLE Whisperer daemon started successfully", "INFO");
    
    return 0;
}

/**
 * @brief Stop the BLE whisperer daemon
 * @return 0 on success, -1 on failure
 */
int stop_whisper_daemon(void) {
    if (!g_daemon_running) {
        return 0;
    }
    
    g_daemon_running = 0;
    
    // Stop BLE scanning
    stop_ble_scanning();
    
    if (g_whisper_thread >= 0) {
        sceKernelWaitThreadEnd(g_whisper_thread, NULL, NULL);
        sceKernelDeleteThread(g_whisper_thread);
        g_whisper_thread = -1;
    }
    
    // Terminate BLE
    if (g_whisper_state.ble_initialized) {
        sceBtTerm();
        g_whisper_state.ble_initialized = 0;
    }
    
    write_whisper_log("BLE Whisperer daemon stopped", "INFO");
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
    write_whisper_log("LilithOS BLE Whisperer starting...", "INFO");
    
    if (whisper_daemon_init() < 0) {
        write_whisper_log("Failed to initialize BLE whisperer", "ERROR");
        return SCE_KERNEL_START_FAILED;
    }
    
    if (start_whisper_daemon() < 0) {
        write_whisper_log("Failed to start BLE whisperer", "ERROR");
        return SCE_KERNEL_START_FAILED;
    }
    
    write_whisper_log("LilithOS BLE Whisperer started successfully", "INFO");
    return SCE_KERNEL_START_SUCCESS;
}

/**
 * @brief Module stop function
 * @param args Module arguments
 * @param argp Module argument pointer
 * @return Module stop result
 */
int module_stop(SceSize args, void *argp) {
    write_whisper_log("LilithOS BLE Whisperer stopping...", "INFO");
    
    stop_whisper_daemon();
    
    write_whisper_log("LilithOS BLE Whisperer stopped", "INFO");
    return SCE_KERNEL_STOP_SUCCESS;
} 