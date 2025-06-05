import Foundation
import SwiftUI

class RitualViewModel: ObservableObject {
    @Published var crest: NSImage = NSImage(systemSymbolName: "shield", accessibilityDescription: nil) ?? NSImage()
    @Published var logs: [String] = ["LilithOS Companion Ritual Ready"]
    private var lastGesture: String? = nil
    private var lastGestureTime: Date = .distantPast
    
    func fetchCrest() {
        // Simulate fetching crest image
        // In a real app, you would fetch this from your API
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.crest = NSImage(systemSymbolName: "shield.fill", accessibilityDescription: nil) ?? NSImage()
        }
    }
    
    func sendTestCommand() {
        let log = "Test command sent at \(Date())"
        logs.append(log)
        // Here you would send a test command to your Mac API
    }
    
    func sendGestureCommand(_ gesture: String) {
        // Prevent duplicate rapid-fire logs
        let now = Date()
        if gesture == lastGesture && now.timeIntervalSince(lastGestureTime) < 1.0 { return }
        lastGesture = gesture
        lastGestureTime = now
        let log = "Gesture detected: \(gesture)"
        logs.append(log)
        // Here you would send the gesture to your Mac API
    }
} 