#include <psp2/kernel/processmgr.h>
#include <psp2/kernel/threadmgr.h>
#include <psp2/io/fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "memory_sniff.h"

int main(int argc, char *argv[]) {
    printf("🧠 LilithOS Memory Scanner\n");
    printf("📱 PlayStation Vita Edition\n");
    printf("==============================\n");
    
    // Initialize memory scanner
    if (init_memory_scanner() != 0) {
        printf("❌ Failed to initialize memory scanner\n");
        return -1;
    }
    
    printf("✅ Memory scanner initialized\n");
    printf("🔍 Starting memory scan...\n");
    
    // Start scanning loop
    while (1) {
        perform_memory_scan();
        sceKernelDelayThread(5000000); // 5 seconds
    }
    
    return 0;
}
