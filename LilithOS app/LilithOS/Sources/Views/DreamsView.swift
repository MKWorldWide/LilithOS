import SwiftUI
import LilithOS

struct DreamsView: View {
  @StateObject private var dreamStore = DreamStore()
  @State private var newDream = ""
  @State private var showingAddDream = false
  
  var body: some View {
    ZStack {
      LinearGradient(
        gradient: Gradient(colors: [
          Color(hex: "1a1a1a"),
          Color(hex: "000000")
        ]),
        startPoint: .top,
        endPoint: .bottom
      )
      .ignoresSafeArea()
      StarfieldView().opacity(0.3)
      VStack(spacing: 24) {
        Text("Dreams")
          .font(.system(size: 36, weight: .light, design: .serif))
          .foregroundColor(.white)
          .opacity(0.9)
        ScrollView {
          VStack(spacing: 16) {
            ForEach(dreamStore.dreams) { dream in
              DreamCard(dream: dream)
            }
          }
        }
        Button(action: { showingAddDream = true }) {
          Text("Add Dream")
            .font(.system(size: 18, design: .serif))
            .foregroundColor(.white)
            .padding()
            .background(RoundedRectangle(cornerRadius: 16).fill(Color(hex: "9966cc").opacity(0.2)))
        }
      }
      .padding()
    }
    .sheet(isPresented: $showingAddDream) {
      VStack(spacing: 20) {
        Text("New Dream")
          .font(.title2)
          .foregroundColor(.white)
        TextField("Describe your dream...", text: $newDream)
          .textFieldStyle(RoundedBorderTextFieldStyle())
          .padding()
        Button("Save") {
          dreamStore.addDream(content: newDream)
          newDream = ""
          showingAddDream = false
        }
        .disabled(newDream.isEmpty)
        .padding()
      }
      .padding()
      .background(Color(hex: "1a1a1a"))
    }
  }
}

struct DreamCard: View {
  let dream: Dream
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(dream.content)
        .font(.system(size: 18, design: .serif))
        .foregroundColor(.white)
      Text(dream.timestamp, style: .date)
        .font(.caption)
        .foregroundColor(.gray)
    }
    .padding()
    .background(RoundedRectangle(cornerRadius: 16).fill(Color(hex: "9966cc").opacity(0.1)))
  }
}

#Preview {
  DreamsView()
} 