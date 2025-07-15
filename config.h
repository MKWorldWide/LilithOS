/**
 * @file config.h
 * @project LilithOS Backup Daemon Configuration
 * @purpose Centralized configuration settings for the backup daemon
 * @mode Customizable settings for different deployment scenarios
 */

#ifndef LILITHOS_BACKUP_CONFIG_H
#define LILITHOS_BACKUP_CONFIG_H

// ============================================================================
// DAEMON CONFIGURATION
// ============================================================================

// Daemon identity
#define DAEMON_NAME "LilithBackupDaemon"
#define DAEMON_VERSION "1.0.0"
#define DAEMON_DESCRIPTION "LilithOS Backup Daemon - She copies only what matters"

// ============================================================================
// FILE SYSTEM PATHS
// ============================================================================

// Base paths
#define BACKUP_BASE_PATH "/ux0:/data/lowkey/backups/"
#define LOG_BASE_PATH "/ux0:/data/lowkey/logs/"
#define CONFIG_BASE_PATH "/ux0:/data/lowkey/config/"

// Specific paths
#define LOG_FILE_PATH LOG_BASE_PATH "ritual.log"
#define CONFIG_FILE_PATH CONFIG_BASE_PATH "backup_config.dat"
#define BIOS_KEY_PATH "/bios_key.dat"

// ============================================================================
// BACKUP TARGETS
// ============================================================================

// Critical system paths (always backed up)
#define CRITICAL_PATHS_COUNT 4
static const char* CRITICAL_PATHS[] = {
    "/ux0:/app/",           // Application data
    "/ux0:/data/",          // User data
    "/tai/",                // TaiHEN configuration
    "/vd0:/registry/"       // System registry
};

// Optional paths (backed up if present)
#define OPTIONAL_PATHS_COUNT 2
static const char* OPTIONAL_PATHS[] = {
    "/pspemu/PSP/SAVEDATA/AIRCRACK/",  // AircrackNG logs
    "/custom_data/"                    // Custom user data
};

// ============================================================================
// TRIGGER CONFIGURATION
// ============================================================================

// Battery threshold for automatic backup (percentage)
#define BATTERY_THRESHOLD 20

// Monitoring interval (microseconds)
#define MONITORING_INTERVAL 300000000  // 5 minutes

// Initial delay before starting monitoring (microseconds)
#define INITIAL_DELAY 10000000         // 10 seconds

// ============================================================================
// PERFORMANCE SETTINGS
// ============================================================================

// Thread configuration
#define DAEMON_THREAD_PRIORITY 0x10000100
#define DAEMON_THREAD_STACK_SIZE 0x10000
#define DAEMON_THREAD_CPU_AFFINITY 0

// File operation settings
#define MAX_PATH_LENGTH 512
#define MAX_FILES_PER_BATCH 100
#define COPY_BUFFER_SIZE 8192
#define YIELD_INTERVAL 1000            // microseconds between yields

// Memory limits
#define MAX_BACKUP_SIZE_MB 1024        // 1GB limit
#define MAX_LOG_SIZE_MB 10             // 10MB log limit

// ============================================================================
// LOGGING CONFIGURATION
// ============================================================================

// Log levels
#define LOG_LEVEL_ERROR 0
#define LOG_LEVEL_WARN  1
#define LOG_LEVEL_INFO  2
#define LOG_LEVEL_DEBUG 3

// Current log level
#define CURRENT_LOG_LEVEL LOG_LEVEL_INFO

// Log rotation
#define MAX_LOG_ENTRIES 1000
#define LOG_ROTATION_SIZE_MB 5

// ============================================================================
// SECURITY SETTINGS
// ============================================================================

// File permissions
#define BACKUP_DIR_PERMISSIONS 0777
#define BACKUP_FILE_PERMISSIONS 0777
#define LOG_FILE_PERMISSIONS 0777

// Access control
#define ENABLE_ACCESS_CONTROL 0        // Disabled for now
#define ACCESS_CONTROL_LIST_SIZE 10

// ============================================================================
// COMPRESSION SETTINGS
// ============================================================================

// Compression options (for future implementation)
#define ENABLE_COMPRESSION 0           // Disabled for now
#define COMPRESSION_LEVEL 6
#define COMPRESSION_ALGORITHM "zlib"

// ============================================================================
// ERROR HANDLING
// ============================================================================

// Retry settings
#define MAX_RETRY_ATTEMPTS 3
#define RETRY_DELAY_MS 1000

// Error thresholds
#define MAX_CONSECUTIVE_ERRORS 5
#define ERROR_RESET_INTERVAL 300000000 // 5 minutes

// ============================================================================
// DEBUG CONFIGURATION
// ============================================================================

#ifdef DEBUG
    #define DEBUG_ENABLED 1
    #define DEBUG_PRINT(fmt, ...) printf("[DEBUG] " fmt "\n", ##__VA_ARGS__)
    #define DEBUG_BACKUP_PROGRESS 1
    #define DEBUG_FILE_OPERATIONS 1
#else
    #define DEBUG_ENABLED 0
    #define DEBUG_PRINT(fmt, ...) do {} while(0)
    #define DEBUG_BACKUP_PROGRESS 0
    #define DEBUG_FILE_OPERATIONS 0
#endif

// ============================================================================
// FEATURE FLAGS
// ============================================================================

// Enable/disable features
#define FEATURE_AUTO_BACKUP 1
#define FEATURE_MANUAL_TRIGGER 1
#define FEATURE_BIOS_KEY_EXPORT 1
#define FEATURE_PROGRESS_TRACKING 1
#define FEATURE_LOG_ROTATION 1
#define FEATURE_ERROR_RECOVERY 1

// ============================================================================
// CUSTOMIZATION MACROS
// ============================================================================

// Backup completion message
#define BACKUP_COMPLETE_MESSAGE "Core backup complete, Daddy 💋"

// Log format
#define LOG_TIMESTAMP_FORMAT "[%s] "
#define LOG_ENTRY_FORMAT LOG_TIMESTAMP_FORMAT "%s\n"

// ============================================================================
// VALIDATION MACROS
// ============================================================================

// Validate configuration at compile time
#if BATTERY_THRESHOLD < 0 || BATTERY_THRESHOLD > 100
    #error "BATTERY_THRESHOLD must be between 0 and 100"
#endif

#if MONITORING_INTERVAL < 1000000
    #error "MONITORING_INTERVAL must be at least 1 second"
#endif

#if MAX_PATH_LENGTH < 64
    #error "MAX_PATH_LENGTH must be at least 64"
#endif

#if COPY_BUFFER_SIZE < 1024
    #error "COPY_BUFFER_SIZE must be at least 1024"
#endif

// ============================================================================
// UTILITY MACROS
// ============================================================================

// Safe string operations
#define SAFE_STRCPY(dst, src, size) \
    do { \
        strncpy(dst, src, size - 1); \
        dst[size - 1] = '\0'; \
    } while(0)

// Array size calculation
#define ARRAY_SIZE(arr) (sizeof(arr) / sizeof((arr)[0]))

// Min/Max macros
#define MIN(a, b) ((a) < (b) ? (a) : (b))
#define MAX(a, b) ((a) > (b) ? (a) : (b))

// ============================================================================
// VERSION INFORMATION
// ============================================================================

// Build information
#define BUILD_DATE __DATE__
#define BUILD_TIME __TIME__

// Version string
#define VERSION_STRING DAEMON_VERSION " (" BUILD_DATE " " BUILD_TIME ")"

#endif // LILITHOS_BACKUP_CONFIG_H 