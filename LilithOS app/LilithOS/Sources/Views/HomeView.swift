import SwiftUI

struct HomeView: View {
  @State private var selectedTab: Tab = .dreams
  @State private var isBreathing = false
  @State private var scale: CGFloat = 1.0
  
  enum Tab {
    case dreams, flow, soul, quantum
  }
  
  var body: some View {
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
      
      VStack(spacing: 40) {
        // Title
        Text("LilithOS")
          .font(.system(size: 48, weight: .light, design: .serif))
          .foregroundColor(.white)
          .opacity(0.9)
        
        // Breathing circle
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
            lineWidth: 2
          )
          .frame(width: 200, height: 200)
          .scaleEffect(scale)
          .onAppear {
            withAnimation(Animation.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
              scale = 1.1
            }
          }
        
        // Navigation
        HStack(spacing: 40) {
          NavigationButton(title: "Dreams", isSelected: selectedTab == .dreams) {
            selectedTab = .dreams
          }
          NavigationButton(title: "Flow", isSelected: selectedTab == .flow) {
            selectedTab = .flow
          }
          NavigationButton(title: "Soul", isSelected: selectedTab == .soul) {
            selectedTab = .soul
          }
          NavigationButton(title: "Quantum", isSelected: selectedTab == .quantum) {
            selectedTab = .quantum
          }
        }
      }
    }
    .fullScreenCover(isPresented: Binding(
      get: { selectedTab == .dreams },
      set: { if !$0 { selectedTab = .flow } }
    )) {
      DreamsView()
    }
    .fullScreenCover(isPresented: Binding(
      get: { selectedTab == .flow },
      set: { if !$0 { selectedTab = .soul } }
    )) {
      FlowView()
    }
    .fullScreenCover(isPresented: Binding(
      get: { selectedTab == .soul },
      set: { if !$0 { selectedTab = .quantum } }
    )) {
      SoulView()
    }
    .fullScreenCover(isPresented: Binding(
      get: { selectedTab == .quantum },
      set: { if !$0 { selectedTab = .dreams } }
    )) {
      QuantumView()
    }
  }
}

struct NavigationButton: View {
  let title: String
  let isSelected: Bool
  let action: () -> Void
  
  var body: some View {
    Button(action: action) {
      Text(title)
        .font(.system(size: 20, weight: .medium, design: .serif))
        .foregroundColor(isSelected ? Color(hex: "9966cc") : .gray)
        .padding(.vertical, 12)
        .padding(.horizontal, 24)
        .background(
          RoundedRectangle(cornerRadius: 25)
            .fill(isSelected ? Color(hex: "9966cc").opacity(0.2) : Color.clear)
        )
    }
  }
}

#Preview {
  HomeView()
} 