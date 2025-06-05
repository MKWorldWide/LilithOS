import Foundation

enum Secrets {
  static var appStoreSharedSecret: String? {
    ProcessInfo.processInfo.environment["APPSTORE_SHARED_SECRET"]
  }
} 