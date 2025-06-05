import Foundation

struct Dream: Identifiable, Codable {
  let id: UUID
  let content: String
  let timestamp: Date
  
  init(content: String) {
    self.id = UUID()
    self.content = content
    self.timestamp = Date()
  }
}

class DreamStore: ObservableObject {
  @Published var dreams: [Dream] = [] {
    didSet { save() }
  }
  
  init() {
    load()
  }
  
  func addDream(content: String) {
    let dream = Dream(content: content)
    dreams.insert(dream, at: 0)
  }
  
  private func save() {
    if let data = try? JSONEncoder().encode(dreams) {
      UserDefaults.standard.set(data, forKey: "dreams")
    }
  }
  
  private func load() {
    if let data = UserDefaults.standard.data(forKey: "dreams"),
       let saved = try? JSONDecoder().decode([Dream].self, from: data) {
      dreams = saved
    }
  }
} 