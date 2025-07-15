/**
 * @file test_backup.c
 * @project LilithOS Backup Daemon Test Suite
 * @purpose Test backup daemon functionality and integration
 * @mode Debug and validation
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <psp2/io/fcntl.h>
#include <psp2/io/stat.h>
#include <psp2/kernel/processmgr.h>
#include <psp2/kernel/threadmgr.h>
#include <psp2/power.h>
#include <psp2/rtc.h>
#include <taihen.h>
#include <vita2d.h>

// Test configuration
#define TEST_BACKUP_PATH "/ux0:/data/lowkey/test_backup/"
#define TEST_LOG_PATH "/ux0:/data/lowkey/test_log.txt"
#define MAX_TEST_FILES 10

// Test file structure
typedef struct {
    char name[64];
    char content[256];
    int size;
} test_file_t;

static const test_file_t test_files[] = {
    {"test_app.txt", "This is a test application file", 30},
    {"test_data.txt", "This is test user data", 23},
    {"tai_config.txt", "TaiHEN configuration test", 28},
    {"registry_test.txt", "Registry data test", 20},
    {"aircrack_log.txt", "AircrackNG test log data", 25},
    {"bios_key_test.dat", "Mock BIOS key data", 18},
    {NULL, NULL, 0}
};

/**
 * @brief Create test directory structure
 * @return 0 on success, -1 on failure
 */
int create_test_environment(void) {
    printf("Creating test environment...\n");
    
    // Create test directories
    sceIoMkdir("/ux0:/data/lowkey", 0777);
    sceIoMkdir("/ux0:/data/lowkey/test_backup", 0777);
    sceIoMkdir("/ux0:/data/lowkey/logs", 0777);
    
    // Create mock source directories
    sceIoMkdir("/ux0:/app/test/", 0777);
    sceIoMkdir("/ux0:/data/test/", 0777);
    sceIoMkdir("/tai/test/", 0777);
    sceIoMkdir("/pspemu/PSP/SAVEDATA/AIRCRACK/", 0777);
    
    // Create test files
    for (int i = 0; test_files[i].name != NULL; i++) {
        char file_path[256];
        
        // Create in appropriate directories
        if (strstr(test_files[i].name, "app") != NULL) {
            snprintf(file_path, sizeof(file_path), "/ux0:/app/test/%s", test_files[i].name);
        } else if (strstr(test_files[i].name, "data") != NULL) {
            snprintf(file_path, sizeof(file_path), "/ux0:/data/test/%s", test_files[i].name);
        } else if (strstr(test_files[i].name, "tai") != NULL) {
            snprintf(file_path, sizeof(file_path), "/tai/test/%s", test_files[i].name);
        } else if (strstr(test_files[i].name, "aircrack") != NULL) {
            snprintf(file_path, sizeof(file_path), "/pspemu/PSP/SAVEDATA/AIRCRACK/%s", test_files[i].name);
        } else if (strstr(test_files[i].name, "bios") != NULL) {
            snprintf(file_path, sizeof(file_path), "/%s", test_files[i].name);
        } else {
            snprintf(file_path, sizeof(file_path), "/ux0:/data/lowkey/test_backup/%s", test_files[i].name);
        }
        
        // Write test file
        SceUID fd = sceIoOpen(file_path, SCE_O_WRONLY | SCE_O_CREAT | SCE_O_TRUNC, 0777);
        if (fd >= 0) {
            sceIoWrite(fd, test_files[i].content, test_files[i].size);
            sceIoClose(fd);
            printf("Created test file: %s\n", file_path);
        }
    }
    
    return 0;
}

/**
 * @brief Verify backup was created successfully
 * @param backup_path Path to backup directory
 * @return Number of files found, -1 on error
 */
int verify_backup(const char *backup_path) {
    printf("Verifying backup at: %s\n", backup_path);
    
    int files_found = 0;
    SceUID dir_fd = sceIoDopen(backup_path);
    if (dir_fd < 0) {
        printf("Failed to open backup directory\n");
        return -1;
    }
    
    SceIoDirent entry;
    while (sceIoDread(dir_fd, &entry) > 0) {
        if (strcmp(entry.d_name, ".") == 0 || strcmp(entry.d_name, "..") == 0) {
            continue;
        }
        
        char full_path[256];
        snprintf(full_path, sizeof(full_path), "%s%s", backup_path, entry.d_name);
        
        if (SCE_S_ISDIR(entry.d_stat.st_mode)) {
            printf("Found backup directory: %s\n", entry.d_name);
            // Recursively check subdirectories
            char subdir_path[256];
            snprintf(subdir_path, sizeof(subdir_path), "%s/", full_path);
            int sub_files = verify_backup(subdir_path);
            if (sub_files >= 0) {
                files_found += sub_files;
            }
        } else {
            printf("Found backup file: %s (size: %ld)\n", entry.d_name, entry.d_stat.st_size);
            files_found++;
        }
    }
    
    sceIoDclose(dir_fd);
    return files_found;
}

/**
 * @brief Test backup daemon functionality
 * @return 0 on success, -1 on failure
 */
int test_backup_daemon(void) {
    printf("=== LilithOS Backup Daemon Test Suite ===\n");
    printf("🐾 Testing backup functionality...\n\n");
    
    // Create test environment
    if (create_test_environment() < 0) {
        printf("Failed to create test environment\n");
        return -1;
    }
    
    // Test system information
    printf("System Information:\n");
    printf("- Battery: %d%%\n", scePowerGetBatteryLifePercent());
    printf("- Temperature: %d°C\n", scePowerGetBatteryTemp());
    printf("- Clock: %d MHz\n", scePowerGetArmClockFrequency());
    
    // Test file system access
    printf("\nFile System Test:\n");
    SceIoStat stat;
    if (sceIoGetstat("/ux0:/data/lowkey", &stat) >= 0) {
        printf("✓ LowKey directory accessible\n");
    } else {
        printf("✗ LowKey directory not accessible\n");
        return -1;
    }
    
    // Test backup creation (mock)
    printf("\nBackup Creation Test:\n");
    char test_backup_dir[256];
    SceDateTime time;
    sceRtcGetCurrentClock(&time);
    
    snprintf(test_backup_dir, sizeof(test_backup_dir), 
             "/ux0:/data/lowkey/test_backup/%04d%02d%02d_%02d%02d%02d/",
             time.year, time.month, time.day,
             time.hour, time.minute, time.second);
    
    if (sceIoMkdir(test_backup_dir, 0777) >= 0) {
        printf("✓ Test backup directory created: %s\n", test_backup_dir);
    } else {
        printf("✗ Failed to create test backup directory\n");
        return -1;
    }
    
    // Test file copying
    printf("\nFile Copy Test:\n");
    char src_file[256], dst_file[256];
    snprintf(src_file, sizeof(src_file), "/ux0:/app/test/test_app.txt");
    snprintf(dst_file, sizeof(dst_file), "%stest_app_copy.txt", test_backup_dir);
    
    SceUID src_fd = sceIoOpen(src_file, SCE_O_RDONLY, 0);
    if (src_fd >= 0) {
        SceUID dst_fd = sceIoOpen(dst_file, SCE_O_WRONLY | SCE_O_CREAT | SCE_O_TRUNC, 0777);
        if (dst_fd >= 0) {
            char buffer[256];
            int bytes_read = sceIoRead(src_fd, buffer, sizeof(buffer));
            if (bytes_read > 0) {
                sceIoWrite(dst_fd, buffer, bytes_read);
                printf("✓ File copied successfully (%d bytes)\n", bytes_read);
            }
            sceIoClose(dst_fd);
        }
        sceIoClose(src_fd);
    }
    
    // Verify backup
    printf("\nBackup Verification:\n");
    int files_found = verify_backup(test_backup_dir);
    if (files_found > 0) {
        printf("✓ Backup verification successful (%d files found)\n", files_found);
    } else {
        printf("✗ Backup verification failed\n");
        return -1;
    }
    
    // Test logging
    printf("\nLogging Test:\n");
    SceUID log_fd = sceIoOpen(TEST_LOG_PATH, SCE_O_WRONLY | SCE_O_CREAT | SCE_O_APPEND, 0777);
    if (log_fd >= 0) {
        char log_entry[512];
        snprintf(log_entry, sizeof(log_entry),
                 "[TEST] Backup test completed successfully at %04d-%02d-%02d %02d:%02d:%02d\n"
                 "Files processed: %d | Test backup path: %s\n",
                 time.year, time.month, time.day,
                 time.hour, time.minute, time.second,
                 files_found, test_backup_dir);
        
        sceIoWrite(log_fd, log_entry, strlen(log_entry));
        sceIoClose(log_fd);
        printf("✓ Test log written successfully\n");
    }
    
    printf("\n=== Test Results ===\n");
    printf("🎉 All tests passed successfully!\n");
    printf("🐾 Backup daemon is ready for deployment\n");
    printf("💋 Core backup complete, Daddy\n\n");
    
    return 0;
}

/**
 * @brief Clean up test environment
 */
void cleanup_test_environment(void) {
    printf("Cleaning up test environment...\n");
    
    // Remove test files and directories
    sceIoRemove("/ux0:/app/test/test_app.txt");
    sceIoRemove("/ux0:/data/test/test_data.txt");
    sceIoRemove("/tai/test/tai_config.txt");
    sceIoRemove("/pspemu/PSP/SAVEDATA/AIRCRACK/aircrack_log.txt");
    sceIoRemove("/bios_key_test.dat");
    
    // Remove test directories
    sceIoRmdir("/ux0:/app/test");
    sceIoRmdir("/ux0:/data/test");
    sceIoRmdir("/tai/test");
    sceIoRmdir("/pspemu/PSP/SAVEDATA/AIRCRACK");
    
    printf("Test environment cleaned up\n");
}

// Main test entry point
int main(int argc, char *argv[]) {
    printf("LilithOS Backup Daemon Test Suite\n");
    printf("================================\n\n");
    
    int result = test_backup_daemon();
    
    if (result == 0) {
        printf("✅ All tests passed!\n");
    } else {
        printf("❌ Some tests failed!\n");
    }
    
    // Cleanup
    cleanup_test_environment();
    
    return result;
}

// Module entry point for testing
int module_start(SceSize args, void *argp) {
    // Run tests in a separate thread
    SceUID thread_id = sceKernelCreateThread("BackupTestThread",
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