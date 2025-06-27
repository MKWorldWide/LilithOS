import SwiftUI

public struct SoulView: View {
  @State private var selectedTab = 0
  @State private var reflection = ""
  @State private var showingNewReflection = false
  @State private var reflections: [SoulReflection] = []
  @State private var isBreathing = false
  @State private var scale: CGFloat = 1.0
  
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
      
      // Starfield effect
      StarfieldView()
        .opacity(0.3)
      
      VStack(spacing: 20) {
        // Sacred circle
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
          
          // Sacred symbol
          Text("∞")
            .font(.system(size: 60, weight: .light, design: .serif))
            .foregroundColor(Color(hex: "9966cc"))
            .opacity(0.8)
        }
        .onAppear {
          withAnimation(Animation.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
            scale = 1.1
          }
        }
        
        // Soul tabs
        HStack(spacing: 30) {
          SoulTab(title: "Reflections", isSelected: selectedTab == 0) {
            selectedTab = 0
          }
          SoulTab(title: "Meditation", isSelected: selectedTab == 1) {
            selectedTab = 1
          }
          SoulTab(title: "Sacred", isSelected: selectedTab == 2) {
            selectedTab = 2
          }
        }
        .padding(.vertical)
        
        // Content area
        TabView(selection: $selectedTab) {
          ReflectionsView(reflections: $reflections, showingNewReflection: $showingNewReflection)
            .tag(0)
          
          MeditationView()
            .tag(1)
          
          SacredView()
            .tag(2)
        }
        .tabViewStyle(.automatic)
      }
    }
    .sheet(isPresented: $showingNewReflection) {
      NewReflectionView(reflections: $reflections)
    }
  }
}

public struct SoulTab: View {
  let title: String
  let isSelected: Bool
  let action: () -> Void
  
  public var body: some View {
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

public struct ReflectionsView: View {
  @Binding var reflections: [SoulReflection]
  @Binding var showingNewReflection: Bool
  
  public var body: some View {
    ScrollView {
      LazyVStack(spacing: 16) {
        ForEach(reflections) { reflection in
          ReflectionCard(reflection: reflection)
            .transition(.scale.combined(with: .opacity))
        }
      }
      .padding()
    }
    .overlay(
      Button(action: { showingNewReflection = true }) {
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

public struct ReflectionCard: View {
  let reflection: SoulReflection
  @State private var isHovered = false
  
  public var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(reflection.title)
        .font(.system(size: 20, weight: .medium, design: .serif))
        .foregroundColor(.white)
      
      Text(reflection.content)
        .font(.system(size: 16, design: .serif))
        .foregroundColor(.gray)
        .lineLimit(3)
      
      HStack {
        ForEach(reflection.tags, id: \.self) { tag in
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

public struct MeditationView: View {
  @State private var isBreathing = false
  @State private var scale: CGFloat = 1.0
  @State private var selectedDuration = 5
  
  let durations = [5, 10, 15, 20, 30]
  
  public var body: some View {
    VStack(spacing: 30) {
      Text("Sacred Breath")
        .font(.system(size: 24, weight: .medium, design: .serif))
        .foregroundColor(.white)
      
      ZStack {
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
          .frame(width: 200, height: 200)
          .scaleEffect(scale)
          .onAppear {
            withAnimation(Animation.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
              scale = 1.1
            }
          }
        
        Text("Breathe")
          .font(.system(size: 36, weight: .light, design: .serif))
          .foregroundColor(Color(hex: "9966cc"))
      }
      
      Picker("Duration", selection: $selectedDuration) {
        ForEach(durations, id: \.self) { duration in
          Text("\(duration) min").tag(duration)
        }
      }
      .pickerStyle(.segmented)
      .padding()
      
      Button(action: {
        // Start meditation
      }) {
        Text("Begin")
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

public struct SacredView: View {
  @State private var selectedAffirmation = 0
  @State private var isAnimating = false
  
  let affirmations = [
    "I am infinite potential",
    "My soul flows with divine wisdom",
    "I am a vessel of sacred light",
    "My essence is eternal",
    "I am one with the cosmic dance"
  ]
  
  public var body: some View {
    VStack(spacing: 30) {
      Text(affirmations[selectedAffirmation])
        .font(.system(size: 36, weight: .light, design: .serif))
        .foregroundColor(Color(hex: "9966cc"))
        .multilineTextAlignment(.center)
        .padding()
        .opacity(isAnimating ? 0.5 : 1.0)
        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)
        .onAppear {
          isAnimating = true
        }
      
      Button(action: {
        withAnimation {
          selectedAffirmation = (selectedAffirmation + 1) % affirmations.count
        }
      }) {
        Text("New Affirmation")
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

struct NewReflectionView: View {
  @Binding var reflections: [SoulReflection]
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
        
        TextField("Reflection", text: $content, axis: .vertical)
          .textFieldStyle(RoundedBorderTextFieldStyle())
          .font(.system(size: 16, design: .serif))
          .lineLimit(6...12)
        
        TextField("Tags (comma separated)", text: $tags)
          .textFieldStyle(RoundedBorderTextFieldStyle())
          .font(.system(size: 16, design: .serif))
        
        Spacer()
      }
      .padding()
      .navigationTitle("New Reflection")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Save") {
            let newReflection = SoulReflection(
              title: title,
              content: content,
              tags: tags.split(separator: ",").map { String($0.trimmingCharacters(in: .whitespaces)) }
            )
            reflections.append(newReflection)
            dismiss()
          }
          .disabled(title.isEmpty || content.isEmpty)
        }
      }
    }
  }
}

struct SoulReflection: Identifiable {
  let id = UUID()
  let title: String
  let content: String
  let tags: [String]
  let timestamp = Date()
}

#Preview {
  SoulView()
} 