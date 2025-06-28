import SwiftUI

struct FlowView: View {
  @State private var energyLevel: Double = 0.7
  @State private var isBreathing = false
  @State private var selectedTab = 0
  @State private var ideas: [FlowIdea] = []
  @State private var showingNewIdea = false
  
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
      VStack(spacing: 20) {
        EnergyCircle(energyLevel: energyLevel, isBreathing: $isBreathing)
          .frame(height: 200)
          .padding(.top, 20)
        HStack(spacing: 30) {
          FlowTab(title: "Ideas", isSelected: selectedTab == 0) {
            selectedTab = 0
          }
          FlowTab(title: "Energy", isSelected: selectedTab == 1) {
            selectedTab = 1
          }
          FlowTab(title: "Flow", isSelected: selectedTab == 2) {
            selectedTab = 2
          }
        }
        .padding(.vertical)
        TabView(selection: $selectedTab) {
          IdeasView(ideas: $ideas, showingNewIdea: $showingNewIdea)
            .tag(0)
          EnergyView(energyLevel: $energyLevel)
            .tag(1)
          FlowStateView()
            .tag(2)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
      }
    }
    .sheet(isPresented: $showingNewIdea) {
      NewIdeaView(ideas: $ideas)
    }
  }
}

struct EnergyCircle: View {
  let energyLevel: Double
  @Binding var isBreathing: Bool
  @State private var scale: CGFloat = 1.0
  
  var body: some View {
    ZStack {
      // Outer glow
      Circle()
        .fill(Color(hex: "9966cc").opacity(0.2))
        .frame(width: 180, height: 180)
        .blur(radius: 20)
        .scaleEffect(scale)
      
      // Main circle
      Circle()
        .stroke(
          LinearGradient(
            gradient: Gradient(colors: [
              Color(hex: "9966cc"),
              Color(hex: "9966cc").opacity(0.5)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          ),
          lineWidth: 4
        )
        .frame(width: 160, height: 160)
        .scaleEffect(scale)
      
      // Energy level indicator
      Circle()
        .trim(from: 0, to: energyLevel)
        .stroke(
          Color(hex: "9966cc"),
          style: StrokeStyle(lineWidth: 8, lineCap: .round)
        )
        .frame(width: 140, height: 140)
        .rotationEffect(.degrees(-90))
        .scaleEffect(scale)
    }
    .onAppear {
      withAnimation(Animation.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
        scale = 1.1
      }
    }
  }
}

struct FlowTab: View {
  let title: String
  let isSelected: Bool
  let action: () -> Void
  
  var body: some View {
    Button(action: action) {
      Text(title)
        .font(.system(size: 18, weight: .medium, design: .serif))
        .foregroundColor(isSelected ? Color(hex: "9966cc") : .gray)
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(
          RoundedRectangle(cornerRadius: 20)
            .fill(isSelected ? Color(hex: "9966cc").opacity(0.2) : Color.clear)
        )
    }
  }
}

struct IdeasView: View {
  @Binding var ideas: [FlowIdea]
  @Binding var showingNewIdea: Bool
  
  var body: some View {
    ScrollView {
      LazyVStack(spacing: 16) {
        ForEach(ideas) { idea in
          IdeaCard(idea: idea)
            .transition(.scale.combined(with: .opacity))
        }
      }
      .padding()
    }
    .overlay(
      Button(action: { showingNewIdea = true }) {
        Image(systemName: "plus.circle.fill")
          .font(.system(size: 44))
          .foregroundColor(Color(hex: "9966cc"))
          .shadow(color: Color(hex: "9966cc").opacity(0.3), radius: 10)
      }
      .padding(),
      alignment: .bottomTrailing
    )
  }
}

struct IdeaCard: View {
  let idea: FlowIdea
  @State private var isHovered = false
  
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(idea.title)
        .font(.system(size: 20, weight: .medium, design: .serif))
        .foregroundColor(.white)
      
      Text(idea.description)
        .font(.system(size: 16, design: .serif))
        .foregroundColor(.gray)
        .lineLimit(3)
      
      HStack {
        ForEach(idea.tags, id: \.self) { tag in
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

struct EnergyView: View {
  @Binding var energyLevel: Double
  
  var body: some View {
    VStack(spacing: 30) {
      Text("Energy Level")
        .font(.system(size: 24, weight: .medium, design: .serif))
        .foregroundColor(.white)
      
      Slider(value: $energyLevel, in: 0...1)
        .accentColor(Color(hex: "9966cc"))
        .padding(.horizontal)
      
      Text("\(Int(energyLevel * 100))%")
        .font(.system(size: 36, weight: .light, design: .serif))
        .foregroundColor(Color(hex: "9966cc"))
    }
    .padding()
  }
}

struct FlowStateView: View {
  @State private var flowState = "Deep Focus"
  @State private var isAnimating = false
  
  let states = ["Deep Focus", "Creative Flow", "Meditative", "Energetic"]
  
  var body: some View {
    VStack(spacing: 30) {
      Text(flowState)
        .font(.system(size: 36, weight: .light, design: .serif))
        .foregroundColor(Color(hex: "9966cc"))
        .opacity(isAnimating ? 0.5 : 1.0)
        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)
        .onAppear {
          isAnimating = true
        }
      
      Button(action: {
        withAnimation {
          flowState = states.randomElement() ?? flowState
        }
      }) {
        Text("Change State")
          .font(.system(size: 18, design: .serif))
          .foregroundColor(.white)
          .padding()
          .background(
            RoundedRectangle(cornerRadius: 20)
              .fill(Color(hex: "9966cc").opacity(0.2))
          )
      }
    }
  }
}

struct NewIdeaView: View {
  @Environment(\.dismiss) var dismiss
  @Binding var ideas: [FlowIdea]
  @State private var title = ""
  @State private var description = ""
  @State private var tags: [String] = []
  @State private var newTag = ""
  
  var body: some View {
    NavigationView {
      Form {
        Section(header: Text("Idea Details")) {
          TextField("Title", text: $title)
            .font(.system(size: 18, design: .serif))
          
          TextEditor(text: $description)
            .font(.system(size: 16, design: .serif))
            .frame(height: 100)
        }
        
        Section(header: Text("Tags")) {
          HStack {
            TextField("New Tag", text: $newTag)
              .font(.system(size: 16, design: .serif))
            
            Button(action: {
              if !newTag.isEmpty {
                tags.append(newTag)
                newTag = ""
              }
            }) {
              Image(systemName: "plus.circle.fill")
                .foregroundColor(Color(hex: "9966cc"))
            }
          }
          
          FlowWrap(tags: tags) { tag in
            Text(tag)
              .font(.system(size: 14, design: .serif))
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
      .navigationTitle("New Idea")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Save") {
            let idea = FlowIdea(
              title: title,
              description: description,
              tags: tags
            )
            ideas.append(idea)
            dismiss()
          }
          .disabled(title.isEmpty)
        }
      }
    }
  }
}

struct FlowWrap<Content: View>: View {
  let tags: [String]
  let content: (String) -> Content
  
  var body: some View {
    GeometryReader { geometry in
      self.generateContent(in: geometry)
    }
  }
  
  private func generateContent(in geometry: GeometryProxy) -> some View {
    var width = CGFloat.zero
    var height = CGFloat.zero
    
    return ZStack(alignment: .topLeading) {
      ForEach(tags, id: \.self) { tag in
        content(tag)
          .padding(.horizontal, 4)
          .padding(.vertical, 4)
          .alignmentGuide(.leading) { dimension in
            if abs(width - dimension.width) > geometry.size.width {
              width = 0
              height -= dimension.height
            }
            let result = width
            if tag == tags.last {
              width = 0
            } else {
              width -= dimension.width
            }
            return result
          }
          .alignmentGuide(.top) { _ in
            let result = height
            if tag == tags.last {
              height = 0
            }
            return result
          }
      }
    }
  }
}

struct FlowIdea: Identifiable {
  let id = UUID()
  let title: String
  let description: String
  let tags: [String]
  let timestamp = Date()
}

#Preview {
  FlowView()
} 