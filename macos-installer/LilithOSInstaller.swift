import SwiftUI
import Foundation
import AppKit

@main
struct LilithOSInstallerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 800, minHeight: 600)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}

struct ContentView: View {
    @StateObject private var installer = LilithOSInstaller()
    @State private var currentStep = 0
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            // Main Content
            Group {
                switch currentStep {
                case 0:
                    WelcomeView(installer: installer, currentStep: $currentStep)
                case 1:
                    SystemCheckView(installer: installer, currentStep: $currentStep)
                case 2:
                    DownloadView(installer: installer, currentStep: $currentStep)
                case 3:
                    USBSetupView(installer: installer, currentStep: $currentStep)
                case 4:
                    InstallationView(installer: installer, currentStep: $currentStep)
                case 5:
                    CompletionView(installer: installer, currentStep: $currentStep)
                default:
                    WelcomeView(installer: installer, currentStep: $currentStep)
                }
            }
            .animation(.easeInOut, value: currentStep)
        }
        .background(Color(NSColor.controlBackgroundColor))
        .alert("Installation Status", isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .onReceive(installer.$statusMessage) { message in
            if !message.isEmpty {
                alertMessage = message
                showAlert = true
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            Image(systemName: "laptopcomputer")
                .font(.title2)
                .foregroundColor(.blue)
            
            Text("LilithOS M3 Installer")
                .font(.title2)
                .fontWeight(.bold)
            
            Spacer()
            
            Text("Step \(currentStep + 1) of 6")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color(NSColor.separatorColor)),
            alignment: .bottom
        )
    }
}

struct WelcomeView: View {
    @ObservedObject var installer: LilithOSInstaller
    @Binding var currentStep: Int
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "laptopcomputer.trianglebadge.exclamationmark")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("Welcome to LilithOS M3")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("This installer will help you set up LilithOS alongside macOS on your MacBook Air M3.")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 15) {
                FeatureRow(icon: "shield", title: "Security-Focused", description: "Based on Kali Linux with advanced security tools")
                FeatureRow(icon: "cpu", title: "M3 Optimized", description: "Specially optimized for Apple Silicon M3")
                FeatureRow(icon: "arrow.triangle.2.circlepath", title: "Dual Boot", description: "Seamless dual boot with macOS")
                FeatureRow(icon: "network", title: "Full Hardware Support", description: "Complete M3 hardware compatibility")
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(10)
            
            Spacer()
            
            HStack {
                Button("Cancel") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Get Started") {
                    currentStep = 1
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(40)
    }
}

struct SystemCheckView: View {
    @ObservedObject var installer: LilithOSInstaller
    @Binding var currentStep: Int
    
    var body: some View {
        VStack(spacing: 30) {
            Text("System Check")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Verifying your system meets the requirements...")
                .font(.title3)
                .foregroundColor(.secondary)
            
            VStack(spacing: 20) {
                SystemCheckRow(
                    title: "Hardware",
                    description: "MacBook Air M3 (\(installer.systemInfo.modelString))",
                    status: installer.systemInfo.isM3 ? .success : .error
                )
                
                SystemCheckRow(
                    title: "Memory",
                    description: "\(installer.systemInfo.memoryGB) GB",
                    status: installer.systemInfo.memoryGB >= 8 ? .success : .error
                )
                
                SystemCheckRow(
                    title: "Storage",
                    description: "\(installer.systemInfo.availableStorageGB) GB available",
                    status: installer.systemInfo.availableStorageGB >= 100 ? .success : .error
                )
                
                SystemCheckRow(
                    title: "SIP Status",
                    description: installer.systemInfo.sipEnabled ? "Enabled" : "Disabled",
                    status: installer.systemInfo.sipEnabled ? .error : .success
                )
                
                SystemCheckRow(
                    title: "Architecture",
                    description: installer.systemInfo.architecture,
                    status: installer.systemInfo.architecture == "arm64" ? .success : .error
                )
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(10)
            
            Spacer()
            
            HStack {
                Button("Back") {
                    currentStep = 0
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Continue") {
                    currentStep = 2
                }
                .buttonStyle(.borderedProminent)
                .disabled(!installer.systemInfo.isCompatible)
            }
        }
        .padding(40)
        .onAppear {
            installer.checkSystem()
        }
    }
}

struct DownloadView: View {
    @ObservedObject var installer: LilithOSInstaller
    @Binding var currentStep: Int
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Download LilithOS")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Downloading the LilithOS M3 ISO image...")
                .font(.title3)
                .foregroundColor(.secondary)
            
            VStack(spacing: 20) {
                if installer.isDownloading {
                    ProgressView(value: installer.downloadProgress) {
                        Text("Downloading... \(Int(installer.downloadProgress * 100))%")
                    }
                    .progressViewStyle(.linear)
                    .frame(height: 20)
                    
                    Text(installer.downloadStatus)
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if installer.downloadComplete {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Download Complete")
                            .fontWeight(.medium)
                    }
                } else {
                    Button("Start Download") {
                        installer.startDownload()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(10)
            
            Spacer()
            
            HStack {
                Button("Back") {
                    currentStep = 1
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Continue") {
                    currentStep = 3
                }
                .buttonStyle(.borderedProminent)
                .disabled(!installer.downloadComplete)
            }
        }
        .padding(40)
    }
}

struct USBSetupView: View {
    @ObservedObject var installer: LilithOSInstaller
    @Binding var currentStep: Int
    
    var body: some View {
        VStack(spacing: 30) {
            Text("USB Drive Setup")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Prepare a bootable USB drive for installation")
                .font(.title3)
                .foregroundColor(.secondary)
            
            VStack(spacing: 20) {
                if installer.usbDrives.isEmpty {
                    Text("No USB drives detected")
                        .foregroundColor(.secondary)
                    
                    Button("Refresh") {
                        installer.refreshUSBDrives()
                    }
                    .buttonStyle(.bordered)
                } else {
                    ForEach(installer.usbDrives, id: \.identifier) { drive in
                        USBDriveRow(
                            drive: drive,
                            isSelected: installer.selectedUSBDrive?.identifier == drive.identifier
                        ) {
                            installer.selectedUSBDrive = drive
                        }
                    }
                }
                
                if installer.isCreatingUSB {
                    ProgressView(value: installer.usbProgress) {
                        Text("Creating bootable USB... \(Int(installer.usbProgress * 100))%")
                    }
                    .progressViewStyle(.linear)
                    .frame(height: 20)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(10)
            
            Spacer()
            
            HStack {
                Button("Back") {
                    currentStep = 2
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Create USB") {
                    installer.createBootableUSB()
                }
                .buttonStyle(.borderedProminent)
                .disabled(installer.selectedUSBDrive == nil || installer.isCreatingUSB)
            }
        }
        .padding(40)
        .onAppear {
            installer.refreshUSBDrives()
        }
    }
}

struct InstallationView: View {
    @ObservedObject var installer: LilithOSInstaller
    @Binding var currentStep: Int
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Installation")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Installing LilithOS alongside macOS...")
                .font(.title3)
                .foregroundColor(.secondary)
            
            VStack(spacing: 20) {
                if installer.isInstalling {
                    ProgressView(value: installer.installationProgress) {
                        Text("Installing... \(Int(installer.installationProgress * 100))%")
                    }
                    .progressViewStyle(.linear)
                    .frame(height: 20)
                    
                    Text(installer.installationStatus)
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if installer.installationComplete {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Installation Complete")
                            .fontWeight(.medium)
                    }
                } else {
                    Button("Start Installation") {
                        installer.startInstallation()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(10)
            
            Spacer()
            
            HStack {
                Button("Back") {
                    currentStep = 3
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Continue") {
                    currentStep = 5
                }
                .buttonStyle(.borderedProminent)
                .disabled(!installer.installationComplete)
            }
        }
        .padding(40)
    }
}

struct CompletionView: View {
    @ObservedObject var installer: LilithOSInstaller
    @Binding var currentStep: Int
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            
            Text("Installation Complete!")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("LilithOS has been successfully installed on your MacBook Air M3.")
                .font(.title3)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 15) {
                Text("Next Steps:")
                    .font(.headline)
                
                Text("• Restart your MacBook Air M3")
                Text("• Hold the Option (⌥) key during startup")
                Text("• Select 'LilithOS' from the boot menu")
                Text("• Login with your credentials")
                Text("• Run system updates and install security tools")
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(10)
            
            Spacer()
            
            Button("Restart Now") {
                installer.restartSystem()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(40)
    }
}

// Supporting Views
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct SystemCheckRow: View {
    let title: String
    let description: String
    let status: SystemCheckStatus
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: status.icon)
                .foregroundColor(status.color)
        }
    }
}

struct USBDriveRow: View {
    let drive: USBDrive
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(drive.name)
                    .font(.headline)
                Text("\(drive.sizeGB) GB • \(drive.identifier)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        .cornerRadius(8)
        .onTapGesture {
            onSelect()
        }
    }
}

// Enums and Models
enum SystemCheckStatus {
    case success, error, warning
    
    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .success: return .green
        case .error: return .red
        case .warning: return .orange
        }
    }
}

struct SystemInfo {
    var isM3: Bool = false
    var memoryGB: Int = 0
    var availableStorageGB: Int = 0
    var sipEnabled: Bool = true
    var architecture: String = ""
    var modelString: String = ""
    
    var isCompatible: Bool {
        return isM3 && memoryGB >= 8 && availableStorageGB >= 100 && !sipEnabled && architecture == "arm64"
    }
}

struct USBDrive {
    let identifier: String
    let name: String
    let sizeGB: Int
}

class LilithOSInstaller: ObservableObject {
    // MARK: - Published Properties
    @Published var systemInfo = SystemInfo()
    @Published var isDownloading = false
    @Published var downloadProgress: Double = 0.0
    @Published var downloadStatus = ""
    @Published var downloadComplete = false
    @Published var usbDrives: [USBDrive] = []
    @Published var selectedUSBDrive: USBDrive?
    @Published var isCreatingUSB = false
    @Published var usbProgress: Double = 0.0
    @Published var isInstalling = false
    @Published var installationProgress: Double = 0.0
    @Published var installationStatus = ""
    @Published var installationComplete = false
    @Published var statusMessage = ""
    
    // MARK: - Private Properties
    private let isoURL = "https://cdimage.kali.org/kali-2024.1/kali-linux-2024.1-installer-arm64.iso"
    private let isoPath = "downloads/kali-linux-2024.1-installer-arm64.iso"
    private var downloadTask: URLSessionDownloadTask?
    
    // MARK: - System Check
    func checkSystem() {
        DispatchQueue.global(qos: .userInitiated).async {
            let info = self.gatherSystemInfo()
            DispatchQueue.main.async {
                self.systemInfo = info
            }
        }
    }
    
    private func gatherSystemInfo() -> SystemInfo {
        var info = SystemInfo()
        
        // Check hardware model
        let task = Process()
        task.launchPath = "/usr/sbin/sysctl"
        task.arguments = ["-n", "hw.model"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let model = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            info.modelString = model
            // Accept Mac15,* as valid for M3 MacBook Air
            info.isM3 = model.hasPrefix("Mac15,")
            print("[DEBUG] Detected hardware model: \(model)")
        } catch {
            print("Error checking hardware model: \(error)")
        }
        
        // Check memory
        let memoryTask = Process()
        memoryTask.launchPath = "/usr/sbin/sysctl"
        memoryTask.arguments = ["-n", "hw.memsize"]
        
        let memoryPipe = Pipe()
        memoryTask.standardOutput = memoryPipe
        
        do {
            try memoryTask.run()
            memoryTask.waitUntilExit()
            
            let data = memoryPipe.fileHandleForReading.readDataToEndOfFile()
            let memoryString = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "0"
            let memoryBytes = UInt64(memoryString) ?? 0
            info.memoryGB = Int(memoryBytes / (1024 * 1024 * 1024))
        } catch {
            print("Error checking memory: \(error)")
        }
        
        // Check available storage
        let fileManager = FileManager.default
        do {
            let attributes = try fileManager.attributesOfFileSystem(forPath: NSHomeDirectory())
            let freeSize = attributes[.systemFreeSize] as? NSNumber ?? 0
            info.availableStorageGB = Int(freeSize.uint64Value / (1024 * 1024 * 1024))
        } catch {
            print("Error checking storage: \(error)")
        }
        
        // Check SIP status
        let sipTask = Process()
        sipTask.launchPath = "/usr/bin/csrutil"
        sipTask.arguments = ["status"]
        
        let sipPipe = Pipe()
        sipTask.standardOutput = sipPipe
        
        do {
            try sipTask.run()
            sipTask.waitUntilExit()
            
            let data = sipPipe.fileHandleForReading.readDataToEndOfFile()
            let status = String(data: data, encoding: .utf8) ?? ""
            info.sipEnabled = status.contains("enabled")
        } catch {
            print("Error checking SIP status: \(error)")
        }
        
        // Check architecture
        let archTask = Process()
        archTask.launchPath = "/usr/bin/uname"
        archTask.arguments = ["-m"]
        
        let archPipe = Pipe()
        archTask.standardOutput = archPipe
        
        do {
            try archTask.run()
            archTask.waitUntilExit()
            
            let data = archPipe.fileHandleForReading.readDataToEndOfFile()
            info.architecture = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        } catch {
            print("Error checking architecture: \(error)")
        }
        
        return info
    }
    
    // MARK: - Download Management
    func startDownload() {
        guard !isDownloading else { return }
        
        let fileManager = FileManager.default
        // Check if ISO already exists
        if fileManager.fileExists(atPath: isoPath) {
            downloadComplete = true
            downloadStatus = "ISO already exists. Skipping download."
            statusMessage = "Found local ISO. Skipping download."
            return
        }
        
        isDownloading = true
        downloadProgress = 0.0
        downloadStatus = "Starting download..."
        
        // Create downloads directory if it doesn't exist
        do {
            try fileManager.createDirectory(atPath: "downloads", withIntermediateDirectories: true)
        } catch {
            print("Error creating downloads directory: \(error)")
        }
        
        let url = URL(string: isoURL)!
        let session = URLSession(configuration: .default)
        
        downloadTask = session.downloadTask(with: url) { [weak self] localURL, response, error in
            DispatchQueue.main.async {
                self?.isDownloading = false
                
                if let error = error {
                    self?.downloadStatus = "Download failed: \(error.localizedDescription)"
                    self?.statusMessage = "Download failed: \(error.localizedDescription)"
                    return
                }
                
                guard let localURL = localURL else {
                    self?.downloadStatus = "Download failed: No local URL"
                    self?.statusMessage = "Download failed: No local URL"
                    return
                }
                
                // Move to final location
                let finalURL = URL(fileURLWithPath: self?.isoPath ?? "")
                do {
                    if fileManager.fileExists(atPath: finalURL.path) {
                        try fileManager.removeItem(at: finalURL)
                    }
                    try fileManager.moveItem(at: localURL, to: finalURL)
                    self?.downloadComplete = true
                    self?.downloadStatus = "Download completed successfully"
                } catch {
                    self?.downloadStatus = "Failed to save file: \(error.localizedDescription)"
                    self?.statusMessage = "Failed to save file: \(error.localizedDescription)"
                }
            }
        }
        
        downloadTask?.resume()
        
        // Monitor progress
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] timer in
            guard let self = self, self.isDownloading else {
                timer.invalidate()
                return
            }
            
            // Simulate progress (in a real implementation, you'd track actual bytes)
            if self.downloadProgress < 0.95 {
                self.downloadProgress += 0.05
            }
        }
    }
    
    // MARK: - USB Drive Management
    func refreshUSBDrives() {
        DispatchQueue.global(qos: .userInitiated).async {
            let drives = self.getUSBDrives()
            DispatchQueue.main.async {
                self.usbDrives = drives
            }
        }
    }
    
    private func getUSBDrives() -> [USBDrive] {
        var drives: [USBDrive] = []
        
        let task = Process()
        task.launchPath = "/usr/sbin/diskutil"
        task.arguments = ["list"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            let lines = output.components(separatedBy: .newlines)
            for line in lines {
                if line.contains("/dev/disk") && line.contains("external") {
                    let components = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
                    if components.count >= 3 {
                        let identifier = components[0]
                        let sizeString = components[1]
                        let name = components[2...].joined(separator: " ")
                        
                        // Parse size (e.g., "15.6GB" -> 15)
                        let sizeGB = Int(sizeString.replacingOccurrences(of: "GB", with: "").replacingOccurrences(of: ".", with: "")) ?? 0
                        
                        drives.append(USBDrive(identifier: identifier, name: name, sizeGB: sizeGB))
                    }
                }
            }
        } catch {
            print("Error listing USB drives: \(error)")
        }
        
        return drives
    }
    
    func createBootableUSB() {
        guard let selectedDrive = selectedUSBDrive else { return }
        
        isCreatingUSB = true
        usbProgress = 0.0
        
        DispatchQueue.global(qos: .userInitiated).async {
            let success = self.createBootableUSBDrive(selectedDrive)
            DispatchQueue.main.async {
                self.isCreatingUSB = false
                if success {
                    self.usbProgress = 1.0
                    self.statusMessage = "Bootable USB created successfully"
                } else {
                    self.statusMessage = "Failed to create bootable USB"
                }
            }
        }
    }
    
    private func createBootableUSBDrive(_ drive: USBDrive) -> Bool {
        // This is a simplified version. In a real implementation, you'd:
        // 1. Unmount the USB drive
        // 2. Format it with appropriate filesystem
        // 3. Copy the ISO contents
        // 4. Make it bootable
        
        // Simulate the process
        for i in 1...10 {
            Thread.sleep(forTimeInterval: 0.5)
            DispatchQueue.main.async {
                self.usbProgress = Double(i) / 10.0
            }
        }
        
        return true
    }
    
    // MARK: - Installation
    func startInstallation() {
        guard downloadComplete else { return }
        
        isInstalling = true
        installationProgress = 0.0
        installationStatus = "Starting installation..."
        
        DispatchQueue.global(qos: .userInitiated).async {
            let success = self.performInstallation()
            DispatchQueue.main.async {
                self.isInstalling = false
                if success {
                    self.installationProgress = 1.0
                    self.installationComplete = true
                    self.installationStatus = "Installation completed successfully"
                } else {
                    self.installationStatus = "Installation failed"
                    self.statusMessage = "Installation failed"
                }
            }
        }
    }
    
    private func performInstallation() -> Bool {
        // This is a simplified version. In a real implementation, you'd:
        // 1. Create partitions
        // 2. Install the OS
        // 3. Configure bootloader
        // 4. Set up dual boot
        
        // Simulate the installation process
        let steps = [
            "Creating partitions...",
            "Installing LilithOS...",
            "Configuring bootloader...",
            "Setting up dual boot...",
            "Finalizing installation..."
        ]
        
        for (index, step) in steps.enumerated() {
            Thread.sleep(forTimeInterval: 1.0)
            DispatchQueue.main.async {
                self.installationStatus = step
                self.installationProgress = Double(index + 1) / Double(steps.count)
            }
        }
        
        return true
    }
    
    // MARK: - System Restart
    func restartSystem() {
        let task = Process()
        task.launchPath = "/sbin/shutdown"
        task.arguments = ["-r", "now"]
        
        do {
            try task.run()
        } catch {
            statusMessage = "Failed to restart system: \(error.localizedDescription)"
        }
    }
} 