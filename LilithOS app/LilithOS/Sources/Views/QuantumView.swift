import SwiftUI
import LilithOS
// If using Swift packages or modules, import the module containing StarfieldView, e.g.:
// import Utils

struct QuantumView: View {
  @StateObject private var quantumNode: QuantumNode
  @StateObject private var celestialTracker = CelestialTracker()
  @State private var message = ""
  @State private var isProcessing = false
  @State private var selectedProtocol: QuantumProtocol = .celestial
  @State private var showingResponse = false
  @State private var aiResponse = ""
  @State private var scale: CGFloat = 1.0
  @State private var rotation: Double = 0
  @State private var showingCelestialAnalysis = false
  
  init() {
    let config = NodeConfig(
      id: UUID(),
      qprotocol: .celestial,
      encryptionLevel: 9,
      celestialCoordinates: .init(rightAscension: 0, declination: 0, epoch: 2000),
      quantumEntanglement: true,
      timestamp: Date()
    )
    _quantumNode = StateObject(wrappedValue: QuantumNode(config: config))
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
      
      // Celestial bodies
      ForEach(celestialTracker.getVisibleBodies()) { body in
        CelestialBodyView(celestialBody: body)
          .position(
            x: CGFloat(body.position.rightAscension * 100),
            y: CGFloat(body.position.declination * 100)
          )
      }
      
      VStack(spacing: 30) {
        // Quantum circle with celestial integration
        ZStack {
          // Outer glow
          Circle()
            .fill(Color(hex: "9966cc").opacity(0.2))
            .frame(width: 180, height: 180)
            .blur(radius: 20)
            .scaleEffect(scale)
          
          // Quantum flux rings
          ForEach(0..<3) { i in
            Circle()
              .stroke(
                Color(hex: "9966cc").opacity(0.3 - Double(i) * 0.1),
                lineWidth: 2
              )
              .frame(width: 160 + CGFloat(i * 20), height: 160 + CGFloat(i * 20))
              .rotationEffect(.degrees(rotation))
          }
          
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
          
          // Quantum symbol
          Text("Ψ")
            .font(.system(size: 60, weight: .light, design: .serif))
            .foregroundColor(Color(hex: "9966cc"))
            .opacity(0.8)
        }
        .onAppear {
          withAnimation(Animation.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
            scale = 1.1
          }
          withAnimation(Animation.linear(duration: 20).repeatForever(autoreverses: false)) {
            rotation = 360
          }
        }
        
        // Celestial analysis button
        Button(action: { showingCelestialAnalysis = true }) {
          Text("Analyze Celestial Alignment")
            .font(.system(size: 16, design: .serif))
            .foregroundColor(.white)
            .padding()
            .background(
              RoundedRectangle(cornerRadius: 20)
                .fill(Color(hex: "9966cc").opacity(0.2))
            )
        }
        
        // Protocol selection
        Picker("Protocol", selection: $selectedProtocol) {
          Text("Celestial").tag(QuantumProtocol.celestial)
          Text("Terrestrial").tag(QuantumProtocol.terrestrial)
          Text("Ethereal").tag(QuantumProtocol.ethereal)
        }
        .pickerStyle(.segmented)
        .padding()
        
        // Message input
        TextEditor(text: $message)
          .font(.system(size: 16, design: .serif))
          .foregroundColor(.white)
          .frame(height: 100)
          .padding()
          .background(
            RoundedRectangle(cornerRadius: 16)
              .fill(Color(hex: "1a1a1a"))
              .shadow(color: Color(hex: "9966cc").opacity(0.1), radius: 10)
          )
          .padding()
        
        // Send button
        Button(action: sendMessage) {
          Text("Transmit")
            .font(.system(size: 18, design: .serif))
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(
              RoundedRectangle(cornerRadius: 20)
                .fill(Color(hex: "9966cc").opacity(0.2))
            )
        }
        .disabled(message.isEmpty || isProcessing)
        .padding(.horizontal)
        
        if isProcessing {
          ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "9966cc")))
        }
      }
    }
    .alert("Quantum Response", isPresented: $showingResponse) {
      Button("OK", role: .cancel) { }
    } message: {
      Text(aiResponse)
    }
    .sheet(isPresented: $showingCelestialAnalysis) {
      CelestialAnalysisView(analysis: celestialTracker.analyzeQuantumImplications())
    }
    .task {
      try? await quantumNode.connect()
    }
  }
  
  private func sendMessage() {
    guard !message.isEmpty else { return }
    
    isProcessing = true
    
    Task {
      do {
        let destination = NodeConfig(
          id: UUID(),
          qprotocol: selectedProtocol,
          encryptionLevel: 9,
          celestialCoordinates: .init(rightAscension: 0, declination: 0, epoch: 2000),
          quantumEntanglement: true,
          timestamp: Date()
        )
        
        let quantumMessage = QuantumMessage(
          id: UUID(),
          content: message,
          source: quantumNode.nodeConfig,
          destination: destination,
          timestamp: Date(),
          encryptionKey: "",
          quantumSignature: ""
        )
        
        aiResponse = try await quantumNode.processWithAI(quantumMessage)
        showingResponse = true
        message = ""
      } catch {
        aiResponse = "Error: \(error.localizedDescription)"
        showingResponse = true
      }
      
      isProcessing = false
    }
  }
}

struct CelestialBodyView: View {
  let celestialBody: CelestialBody
  @State private var isGlowing = false
  
  var body: some View {
    Circle()
      .fill(bodyColor)
      .frame(width: bodySize, height: bodySize)
      .blur(radius: isGlowing ? 2 : 0)
      .onAppear {
        withAnimation(Animation.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
          isGlowing = true
        }
      }
  }
  
  private var bodyColor: Color {
    switch celestialBody.type {
    case .star:
      return Color(hex: "FFD700")
    case .planet:
      return Color(hex: "4169E1")
    case .nebula:
      return Color(hex: "FF69B4")
    case .galaxy:
      return Color(hex: "9370DB")
    case .blackHole:
      return Color(hex: "000000")
    }
  }
  
  private var bodySize: CGFloat {
    switch celestialBody.type {
    case .star:
      return 8
    case .planet:
      return 6
    case .nebula:
      return 12
    case .galaxy:
      return 10
    case .blackHole:
      return 4
    }
  }
}

struct CelestialAnalysisView: View {
  let analysis: String
  
  var body: some View {
    ScrollView {
      Text(analysis)
        .font(.system(size: 16, design: .serif))
        .foregroundColor(.white)
        .padding()
    }
    .background(Color(hex: "1a1a1a"))
  }
}

#Preview {
  QuantumView()
} 