import SwiftUI
import LilithOS

@main
struct LilithOSApp: App {
  var body: some Scene {
    WindowGroup {
      HomeView()
        .preferredColorScheme(ColorScheme.dark)
    }
  }
} 