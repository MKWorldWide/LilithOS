import SwiftUI

public struct DreamsView: View {
  @Environment(\.dismiss) private var dismiss
  @State private var dreams: [Dream] = [
    Dream(title: "Digital Garden", content: "A sacred space where code flows like breath...", tags: ["creative", "digital"]),
    Dream(title: "Quantum Interface", content: "Where consciousness meets computation...", tags: ["quantum", "interface"]),
    Dream(title: "Ethereal Algorithms", content: "Algorithms that dance with the soul...", tags: ["algorithms", "spiritual"])
  ]
  @State private var showingNewDream = false
  
  public var body: some View {
    ZStack {
      // Ethereal background
      LinearGradient(
        gradient: Gradient(colors: [
          Color(hex: "1a1a1a"),
          Color(hex: "000000")
        ]),
        startPoint: .top,
        endPoint: .bottom
      )
      .ignoresSafeArea()
      
      VStack {
        // Header
        HStack {
          Button(action: { dismiss() }) {
            Image(systemName: "xmark.circle.fill")
              .font(.system(size: 24))
              .foregroundColor(.gray)
          }
          
          Spacer()
          
          Text("Dreams")
            .font(.system(size: 28, weight: .light, design: .serif))
            .foregroundColor(.white)
          
          Spacer()
          
          Button(action: { showingNewDream = true }) {
            Image(systemName: "plus.circle.fill")
              .font(.system(size: 24))
              .foregroundColor(Color(hex: "9966cc"))
          }
        }
        .padding()
        
        // Dreams list
        ScrollView {
          LazyVStack(spacing: 16) {
            ForEach(dreams) { dream in
              DreamCard(dream: dream)
                .transition(AnyTransition.scale.combined(with: .opacity))
            }
          }
          .padding()
        }
      }
    }
    .sheet(isPresented: $showingNewDream) {
      NewDreamView(dreams: $dreams)
    }
  }
}

public struct DreamCard: View {
  let dream: Dream
  @State private var isHovered = false
  
  public var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(dream.title)
        .font(.system(size: 20, weight: .medium, design: .serif))
        .foregroundColor(.white)
      
      Text(dream.content)
        .font(.system(size: 16, design: .serif))
        .foregroundColor(.gray)
        .lineLimit(3)
      
      HStack {
        ForEach(dream.tags, id: \.self) { tag in
          Text(tag)
            .font(.system(size: 12, design: .serif))
            .foregroundColor(Color(hex: "9966cc"))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
              Capsule()
                .fill(Color(hex: "9966cc").opacity(0.2))
            )
        }
      }
    }
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color(hex: "1a1a1a"))
        .shadow(color: Color(hex: "9966cc").opacity(0.1), radius: 10)
    )
    .scaleEffect(isHovered ? 1.02 : 1.0)
    .animation(.spring(response: 0.3), value: isHovered)
    .onHover { hovering in
      isHovered = hovering
    }
  }
}

struct NewDreamView: View {
  @Binding var dreams: [Dream]
  @Environment(\.dismiss) private var dismiss
  @State private var title = ""
  @State private var content = ""
  @State private var tags = ""
  
  var body: some View {
    NavigationView {
      VStack(spacing: 20) {
        TextField("Title", text: $title)
          .textFieldStyle(RoundedBorderTextFieldStyle())
          .font(.system(size: 18, design: .serif))
        
        TextField("Dream", text: $content, axis: .vertical)
          .textFieldStyle(RoundedBorderTextFieldStyle())
          .font(.system(size: 16, design: .serif))
          .lineLimit(6...12)
        
        TextField("Tags (comma separated)", text: $tags)
          .textFieldStyle(RoundedBorderTextFieldStyle())
          .font(.system(size: 16, design: .serif))
        
        Spacer()
      }
      .padding()
      .navigationTitle("New Dream")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Save") {
            let newDream = Dream(
              title: title,
              content: content,
              tags: tags.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }
            )
            dreams.append(newDream)
            dismiss()
          }
          .disabled(title.isEmpty || content.isEmpty)
        }
      }
    }
  }
}

struct Dream: Identifiable {
  let id = UUID()
  let title: String
  let content: String
  let tags: [String]
}

#Preview {
  DreamsView()
} 