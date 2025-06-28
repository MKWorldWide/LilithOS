import SwiftUI

@main
struct LilithOSApp: App {
  var body: some Scene {
    WindowGroup {
      HomeView()
        .preferredColorScheme(.dark)
    }
  }
} 