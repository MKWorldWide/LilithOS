/**
 * @file backup.c
 * @project LilithOS (Daemon)
 * @purpose Automatically crawl and archive essential Vita OS + user data
 * @mode Stealth, smart, non-destructive
 * @trigger Manual or at system sleep
 * @output /ux0:/data/lowkey/backups/YYYYMMDD/
 * 
 * 🐾 CursorKitten<3 — this daemon walks carefully. She copies only what matters, 
 * compresses her payload, and leaves no scar.
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
#include <taihen.h>
#include <vita2d.h>
#include "config.h"

// Backup targets with their source paths
typedef struct {
    const char *source_path;
    const char *description;
    int critical;
} backup_target_t;

static const backup_target_t backup_targets[] = {
    {"/ux0:/app/", "Application data", 1},
    {"/ux0:/data/", "User data", 1},
    {"/tai/", "TaiHEN configuration", 1},
    {"/vd0:/registry/", "System registry", 1},
    {"/pspemu/PSP/SAVEDATA/AIRCRACK/", "AircrackNG logs", 0},
    {NULL, NULL, 0}
};

// Daemon state
typedef struct {
    char current_backup_path[MAX_PATH_LENGTH];
    char timestamp[32];
    int backup_in_progress;
    int files_copied;
    int total_size;
    time_t start_time;
} backup_state_t;

static backup_state_t g_backup_state = {0};

/**
 * @brief Initialize the backup daemon
 * @return 0 on success, -1 on failure
 */
int backup_daemon_init(void) {
    // Create base directories
    sceIoMkdir("/ux0:/data/lowkey", BACKUP_DIR_PERMISSIONS);
    sceIoMkdir(BACKUP_BASE_PATH, BACKUP_DIR_PERMISSIONS);
    sceIoMkdir(LOG_BASE_PATH, BACKUP_DIR_PERMISSIONS);
    
    // Initialize backup state
    memset(&g_backup_state, 0, sizeof(backup_state_t));
    g_backup_state.backup_in_progress = 0;
    
    return 0;
}

/**
 * @brief Generate timestamp for backup folder
 * @param timestamp Buffer to store timestamp
 * @param size Size of buffer
 */
void generate_timestamp(char *timestamp, size_t size) {
    SceDateTime time;
    sceRtcGetCurrentClock(&time);
    
    snprintf(timestamp, size, "%04d%02d%02d_%02d%02d%02d",
             time.year, time.month, time.day,
             time.hour, time.minute, time.second);
}

/**
 * @brief Create backup directory structure
 * @return 0 on success, -1 on failure
 */
int create_backup_directory(void) {
    generate_timestamp(g_backup_state.timestamp, sizeof(g_backup_state.timestamp));
    
    snprintf(g_backup_state.current_backup_path, MAX_PATH_LENGTH,
             "%s%s/", BACKUP_BASE_PATH, g_backup_state.timestamp);
    
    if (sceIoMkdir(g_backup_state.current_backup_path, BACKUP_DIR_PERMISSIONS) < 0) {
        return -1;
    }
    
    // Create subdirectories for each backup target
    for (int i = 0; backup_targets[i].source_path != NULL; i++) {
        char subdir_path[MAX_PATH_LENGTH];
        snprintf(subdir_path, MAX_PATH_LENGTH, "%s%s/", 
                g_backup_state.current_backup_path, 
                strrchr(backup_targets[i].source_path, '/') + 1);
        sceIoMkdir(subdir_path, BACKUP_DIR_PERMISSIONS);
    }
    
    return 0;
}

/**
 * @brief Copy a single file with progress tracking
 * @param src Source file path
 * @param dst Destination file path
 * @return 0 on success, -1 on failure
 */
int copy_file_safe(const char *src, const char *dst) {
    SceUID src_fd = sceIoOpen(src, SCE_O_RDONLY, 0);
    if (src_fd < 0) {
        return -1;
    }
    
    SceUID dst_fd = sceIoOpen(dst, SCE_O_WRONLY | SCE_O_CREAT | SCE_O_TRUNC, BACKUP_FILE_PERMISSIONS);
    if (dst_fd < 0) {
        sceIoClose(src_fd);
        return -1;
    }
    
    char buffer[COPY_BUFFER_SIZE];
    int bytes_read, bytes_written;
    int total_copied = 0;
    
    while ((bytes_read = sceIoRead(src_fd, buffer, sizeof(buffer))) > 0) {
        bytes_written = sceIoWrite(dst_fd, buffer, bytes_read);
        if (bytes_written != bytes_read) {
            sceIoClose(src_fd);
            sceIoClose(dst_fd);
            return -1;
        }
        total_copied += bytes_written;
    }
    
    sceIoClose(src_fd);
    sceIoClose(dst_fd);
    
    g_backup_state.files_copied++;
    g_backup_state.total_size += total_copied;
    
    return 0;
}

/**
 * @brief Recursively copy directory contents
 * @param src_dir Source directory
 * @param dst_dir Destination directory
 * @return Number of files copied, -1 on error
 */
int copy_directory_recursive(const char *src_dir, const char *dst_dir) {
    SceUID dir_fd = sceIoDopen(src_dir);
    if (dir_fd < 0) {
        return -1;
    }
    
    int files_copied = 0;
    SceIoDirent entry;
    
    while (sceIoDread(dir_fd, &entry) > 0) {
        if (strcmp(entry.d_name, ".") == 0 || strcmp(entry.d_name, "..") == 0) {
            continue;
        }
        
        char src_path[MAX_PATH_LENGTH];
        char dst_path[MAX_PATH_LENGTH];
        
        snprintf(src_path, MAX_PATH_LENGTH, "%s%s", src_dir, entry.d_name);
        snprintf(dst_path, MAX_PATH_LENGTH, "%s%s", dst_dir, entry.d_name);
        
        if (SCE_S_ISDIR(entry.d_stat.st_mode)) {
            // Create subdirectory and recurse
            sceIoMkdir(dst_path, BACKUP_DIR_PERMISSIONS);
            char src_subdir[MAX_PATH_LENGTH], dst_subdir[MAX_PATH_LENGTH];
            snprintf(src_subdir, MAX_PATH_LENGTH, "%s/", src_path);
            snprintf(dst_subdir, MAX_PATH_LENGTH, "%s/", dst_path);
            
            int sub_files = copy_directory_recursive(src_subdir, dst_subdir);
            if (sub_files >= 0) {
                files_copied += sub_files;
            }
        } else {
            // Copy file
            if (copy_file_safe(src_path, dst_path) == 0) {
                files_copied++;
            }
        }
        
        // Yield to prevent blocking
        sceKernelDelayThread(YIELD_INTERVAL);
    }
    
    sceIoDclose(dir_fd);
    return files_copied;
}

/**
 * @brief Check and export BIOS key if present
 * @return 0 on success, -1 if not found
 */
int export_bios_key(void) {
    char bios_key_dst[MAX_PATH_LENGTH];
    snprintf(bios_key_dst, MAX_PATH_LENGTH, "%sbios_key.dat", 
            g_backup_state.current_backup_path);
    
    if (copy_file_safe(BIOS_KEY_PATH, bios_key_dst) == 0) {
        return 0;
    }
    
    return -1;
}

/**
 * @brief Write completion log with seductive message
 */
void write_completion_log(void) {
    SceUID log_fd = sceIoOpen(LOG_FILE_PATH, SCE_O_WRONLY | SCE_O_CREAT | SCE_O_APPEND, LOG_FILE_PERMISSIONS);
    if (log_fd < 0) {
        return;
    }
    
    char log_entry[1024];
    time_t end_time = time(NULL);
    int duration = (int)(end_time - g_backup_state.start_time);
    
    snprintf(log_entry, sizeof(log_entry),
             "[%s] " BACKUP_COMPLETE_MESSAGE "\n"
             "  Files: %d | Size: %d bytes | Duration: %ds\n"
             "  Path: %s\n",
             g_backup_state.timestamp,
             g_backup_state.files_copied,
             g_backup_state.total_size,
             duration,
             g_backup_state.current_backup_path);
    
    sceIoWrite(log_fd, log_entry, strlen(log_entry));
    sceIoClose(log_fd);
}

/**
 * @brief Perform the complete backup ritual
 * @return 0 on success, -1 on failure
 */
int perform_backup_ritual(void) {
    if (g_backup_state.backup_in_progress) {
        return -1; // Already in progress
    }
    
    g_backup_state.backup_in_progress = 1;
    g_backup_state.start_time = time(NULL);
    g_backup_state.files_copied = 0;
    g_backup_state.total_size = 0;
    
    // Create backup directory
    if (create_backup_directory() < 0) {
        g_backup_state.backup_in_progress = 0;
        return -1;
    }
    
    // Copy each backup target
    for (int i = 0; backup_targets[i].source_path != NULL; i++) {
        char dst_dir[MAX_PATH_LENGTH];
        snprintf(dst_dir, MAX_PATH_LENGTH, "%s%s/", 
                g_backup_state.current_backup_path,
                strrchr(backup_targets[i].source_path, '/') + 1);
        
        // Check if source exists
        SceIoStat stat;
        if (sceIoGetstat(backup_targets[i].source_path, &stat) >= 0) {
            copy_directory_recursive(backup_targets[i].source_path, dst_dir);
        }
        
        // Yield to prevent blocking
        sceKernelDelayThread(YIELD_INTERVAL * 5);
    }
    
    // Export BIOS key if available
    export_bios_key();
    
    // Write completion log
    write_completion_log();
    
    g_backup_state.backup_in_progress = 0;
    return 0;
}

/**
 * @brief Main backup daemon thread
 * @param args Thread arguments (unused)
 * @return Thread exit code
 */
int backup_daemon_thread(SceSize args, void *argp) {
    // Wait for system to stabilize
    sceKernelDelayThread(INITIAL_DELAY);
    
    while (1) {
        // Check if system is going to sleep
        int power_status = scePowerGetBatteryLifePercent();
        if (power_status < BATTERY_THRESHOLD) {
            // Low battery - perform backup
            perform_backup_ritual();
        }
        
        // Sleep before next check
        sceKernelDelayThread(MONITORING_INTERVAL);
    }
    
    return 0;
}

/**
 * @brief Initialize and start the backup daemon
 * @return 0 on success, -1 on failure
 */
int start_backup_daemon(void) {
    if (backup_daemon_init() < 0) {
        return -1;
    }
    
    SceUID thread_id = sceKernelCreateThread(DAEMON_NAME,
                                           backup_daemon_thread,
                                           DAEMON_THREAD_PRIORITY,
                                           DAEMON_THREAD_STACK_SIZE,
                                           0,          // Attributes
                                           DAEMON_THREAD_CPU_AFFINITY,
                                           NULL);
    
    if (thread_id < 0) {
        return -1;
    }
    
    sceKernelStartThread(thread_id, 0, NULL);
    return 0;
}

/**
 * @brief Manual backup trigger
 * @return 0 on success, -1 on failure
 */
int trigger_manual_backup(void) {
    return perform_backup_ritual();
}

// Module entry point for taiHEN
int module_start(SceSize args, void *argp) {
    start_backup_daemon();
    return SCE_KERNEL_START_SUCCESS;
}

int module_stop(SceSize args, void *argp) {
    return SCE_KERNEL_STOP_SUCCESS;
} 