/**
 * LilithOS Sensor Echo PRX
 * 
 * Purpose: Stub PRX module for sensor functionality and echo processing
 * 
 * Features:
 * - Placeholder for future sensor integration
 * - Basic module structure for PSP compatibility
 * - Logging and status reporting
 * - Hookable endpoints for Vita integration
 * 
 * @author CursorKitten<3
 * @version 1.0.0
 */

#include <pspkernel.h>
#include <pspdebug.h>
#include <pspthreadman.h>
#include <pspiofilemgr.h>
#include <psprtc.h>
#include <pspctrl.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

// PSP Module Info
PSP_MODULE_INFO("SensorEcho", 0x1000, 1, 0);

// Configuration
#define SENSOR_LOG_PATH "ms0:/LILIDAEMON/OUT/sensor_echo_log.txt"
#define SENSOR_STATUS_PATH "ms0:/LILIDAEMON/OUT/sensor_status.txt"
#define SENSOR_DATA_PATH "ms0:/LILIDAEMON/OUT/sensor_data.txt"

// Global state
static int sensor_running = 0;
static SceUID sensor_thread = -1;
static int sensor_count = 0;

// Debug macros
#define SENSOR_LOG_MSG(fmt, ...) do { \
    char log_msg[256]; \
    snprintf(log_msg, sizeof(log_msg), "[SensorEcho] " fmt, ##__VA_ARGS__); \
    write_sensor_log(log_msg); \
} while(0)

/**
 * Write to sensor echo log file
 */
void write_sensor_log(const char *message) {
    FILE *log_file = fopen(SENSOR_LOG_PATH, "a+");
    if (log_file) {
        // Get timestamp
        pspTime time;
        sceRtcGetCurrentTime(&time);
        
        fprintf(log_file, "[%02d:%02d:%02d] %s\n", 
                time.hour, time.minutes, time.seconds, message);
        fclose(log_file);
    }
}

/**
 * Write sensor status to status file
 */
void write_sensor_status(const char *status) {
    FILE *status_file = fopen(SENSOR_STATUS_PATH, "w");
    if (status_file) {
        fprintf(status_file, "%s", status);
        fclose(status_file);
    }
}

/**
 * Write sensor data to data file
 */
void write_sensor_data(const char *data) {
    FILE *data_file = fopen(SENSOR_DATA_PATH, "a+");
    if (data_file) {
        // Get timestamp
        pspTime time;
        sceRtcGetCurrentTime(&time);
        
        fprintf(data_file, "[%02d:%02d:%02d] %s\n", 
                time.hour, time.minutes, time.seconds, data);
        fclose(data_file);
    }
}

/**
 * Simulate sensor data reading
 */
void simulate_sensor_data() {
    // Stub: Simulate various sensor readings
    char sensor_data[256];
    
    // Simulate accelerometer data
    snprintf(sensor_data, sizeof(sensor_data),
             "ACCEL:X=%d,Y=%d,Z=%d",
             (rand() % 200) - 100,
             (rand() % 200) - 100,
             (rand() % 200) - 100);
    write_sensor_data(sensor_data);
    
    // Simulate gyroscope data
    snprintf(sensor_data, sizeof(sensor_data),
             "GYRO:X=%d,Y=%d,Z=%d",
             (rand() % 360),
             (rand() % 360),
             (rand() % 360));
    write_sensor_data(sensor_data);
    
    // Simulate button state
    SceCtrlData pad;
    sceCtrlReadBufferPositive(&pad, 1);
    snprintf(sensor_data, sizeof(sensor_data),
             "BUTTONS:0x%08X,ANALOG_LX=%d,ANALOG_LY=%d,ANALOG_RX=%d,ANALOG_RY=%d",
             pad.Buttons, pad.Lx, pad.Ly, pad.Rx, pad.Ry);
    write_sensor_data(sensor_data);
    
    sensor_count++;
}

/**
 * Main sensor echo thread function
 */
int sensor_thread_func(SceSize args, void *argp) {
    SENSOR_LOG_MSG("Sensor echo thread started");
    write_sensor_status("SENSOR_ACTIVE");
    
    while (sensor_running) {
        // Simulate sensor data reading
        simulate_sensor_data();
        
        SENSOR_LOG_MSG("Sensor data collected (count: %d)", sensor_count);
        
        // Sleep for sensor reading interval
        sceKernelDelayThread(2000000); // 2 seconds
    }
    
    SENSOR_LOG_MSG("Sensor echo thread stopped");
    write_sensor_status("SENSOR_STOPPED");
    return 0;
}

/**
 * Module start function
 */
int module_start(SceSize args, void *argp) {
    SENSOR_LOG_MSG("SensorEcho PRX starting");
    
    sensor_running = 1;
    
    // Initialize sensor data file
    write_sensor_data("=== LilithOS Sensor Echo Data ===");
    
    // Start sensor echo thread
    sensor_thread = sceKernelCreateThread("SensorEcho", 
                                         sensor_thread_func, 
                                         0x18, 
                                         0x1000, 
                                         0, 
                                         NULL);
    if (sensor_thread >= 0) {
        sceKernelStartThread(sensor_thread, 0, NULL);
        SENSOR_LOG_MSG("SensorEcho PRX started successfully");
        write_sensor_status("SENSOR_READY");
    } else {
        SENSOR_LOG_MSG("Failed to create sensor thread: %d", sensor_thread);
        write_sensor_status("SENSOR_ERROR");
    }
    
    return 0;
}

/**
 * Module stop function
 */
int module_stop(SceSize args, void *argp) {
    SENSOR_LOG_MSG("SensorEcho PRX stopping");
    
    sensor_running = 0;
    
    // Wait for thread to finish
    if (sensor_thread >= 0) {
        sceKernelWaitThreadEnd(sensor_thread, NULL, NULL);
        sceKernelDeleteThread(sensor_thread);
    }
    
    // Write final sensor summary
    char summary[256];
    snprintf(summary, sizeof(summary),
             "=== Sensor Echo Summary ===\nTotal readings: %d\nSession ended",
             sensor_count);
    write_sensor_data(summary);
    
    SENSOR_LOG_MSG("SensorEcho PRX stopped");
    write_sensor_status("SENSOR_STOPPED");
    return 0;
} 