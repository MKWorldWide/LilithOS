import SwiftUI

public struct HomeView: View {
  @State private var selectedTab: Tab = .dreams
  @State private var isBreathing = false
  @State private var scale: CGFloat = 1.0
  @State private var showingDreams = false
  @State private var showingFlow = false
  @State private var showingSoul = false
  @State private var showingQuantum = false
  
  public enum Tab {
    case dreams, flow, soul, quantum
  }
  
  public init() {}
  
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
            showingDreams = true
          }
          NavigationButton(title: "Flow", isSelected: selectedTab == .flow) {
            selectedTab = .flow
            showingFlow = true
          }
          NavigationButton(title: "Soul", isSelected: selectedTab == .soul) {
            selectedTab = .soul
            showingSoul = true
          }
          NavigationButton(title: "Quantum", isSelected: selectedTab == .quantum) {
            selectedTab = .quantum
            showingQuantum = true
          }
        }
      }
    }
    .sheet(isPresented: $showingDreams) {
      DreamsView()
    }
    .sheet(isPresented: $showingFlow) {
      FlowView()
    }
    .sheet(isPresented: $showingSoul) {
      SoulView()
    }
    .sheet(isPresented: $showingQuantum) {
      QuantumView()
    }
  }
}

public struct NavigationButton: View {
  let title: String
  let isSelected: Bool
  let action: () -> Void
  
  public init(title: String, isSelected: Bool, action: @escaping () -> Void) {
    self.title = title
    self.isSelected = isSelected
    self.action = action
  }
  
  public var body: some View {
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