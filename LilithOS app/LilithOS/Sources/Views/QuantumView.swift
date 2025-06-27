import SwiftUI
// If using Swift packages or modules, import the module containing StarfieldView, e.g.:
// import Utils

public struct QuantumView: View {
  @Environment(\.dismiss) private var dismiss
  @StateObject private var quantumNode = QuantumNode()
  @State private var selectedTab = 0
  @State private var showingConnection = false
  
  public var body: some View {
    ZStack {
      // Quantum background
      LinearGradient(
        gradient: Gradient(colors: [
          Color(hex: "000000"),
          Color(hex: "1a1a1a")
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
          
          Text("Quantum")
            .font(.system(size: 28, weight: .light, design: .serif))
            .foregroundColor(.white)
          
          Spacer()
          
          Button(action: { showingConnection = true }) {
            Image(systemName: "network")
              .font(.system(size: 24))
              .foregroundColor(quantumNode.isConnected ? Color(hex: "9966cc") : .gray)
          }
        }
        .padding()
        
        // Tab navigation
        HStack(spacing: 20) {
          QuantumTab(title: "Network", isSelected: selectedTab == 0) {
            selectedTab = 0
          }
          QuantumTab(title: "Messages", isSelected: selectedTab == 1) {
            selectedTab = 1
          }
          QuantumTab(title: "AI", isSelected: selectedTab == 2) {
            selectedTab = 2
          }
        }
        .padding()
        
        // Content
        TabView(selection: $selectedTab) {
          NetworkView(quantumNode: quantumNode)
            .tag(0)
          MessagesView(quantumNode: quantumNode)
            .tag(1)
          AIView(quantumNode: quantumNode)
            .tag(2)
        }
        .tabViewStyle(.automatic)
      }
    }
    .sheet(isPresented: $showingConnection) {
      ConnectionView(quantumNode: quantumNode)
    }
  }
}

public struct QuantumTab: View {
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

public struct NetworkView: View {
  @ObservedObject var quantumNode: QuantumNode
  
  public var body: some View {
    VStack(spacing: 20) {
      Text("Quantum Network Status")
        .font(.system(size: 24, weight: .medium, design: .serif))
        .foregroundColor(.white)
      
      VStack(spacing: 16) {
        NetworkStatusCard(
          title: "Celestial Network",
          isConnected: quantumNode.celestialConnected,
          action: { quantumNode.connectToCelestialNetwork() }
        )
        
        NetworkStatusCard(
          title: "Terrestrial Network", 
          isConnected: quantumNode.terrestrialConnected,
          action: { quantumNode.connectToTerrestrialNetwork() }
        )
      }
      .padding()
    }
  }
}

public struct NetworkStatusCard: View {
  let title: String
  let isConnected: Bool
  let action: () -> Void
  
  public var body: some View {
    HStack {
      VStack(alignment: .leading) {
        Text(title)
          .font(.system(size: 18, weight: .medium, design: .serif))
          .foregroundColor(.white)
        
        Text(isConnected ? "Connected" : "Disconnected")
          .font(.system(size: 14, design: .serif))
          .foregroundColor(isConnected ? Color(hex: "9966cc") : .gray)
      }
      
      Spacer()
      
      Button(action: action) {
        Text(isConnected ? "Disconnect" : "Connect")
          .font(.system(size: 14, design: .serif))
          .foregroundColor(.white)
          .padding(.horizontal, 16)
          .padding(.vertical, 8)
          .background(
            RoundedRectangle(cornerRadius: 12)
              .fill(isConnected ? Color.red.opacity(0.2) : Color(hex: "9966cc").opacity(0.2))
          )
      }
    }
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color(hex: "1a1a1a"))
        .shadow(color: Color(hex: "9966cc").opacity(0.1), radius: 10)
    )
  }
}

public struct MessagesView: View {
  @ObservedObject var quantumNode: QuantumNode
  @State private var newMessage = ""
  
  public var body: some View {
    VStack(spacing: 20) {
      Text("Quantum Messages")
        .font(.system(size: 24, weight: .medium, design: .serif))
        .foregroundColor(.white)
      
      ScrollView {
        LazyVStack(spacing: 12) {
          ForEach(quantumNode.messages) { message in
            MessageCard(message: message)
          }
        }
        .padding()
      }
      
      HStack {
        TextField("Enter message...", text: $newMessage)
          .textFieldStyle(RoundedBorderTextFieldStyle())
          .font(.system(size: 16, design: .serif))
        
        Button(action: {
          quantumNode.sendMessage(content: newMessage)
          newMessage = ""
        }) {
          Image(systemName: "paperplane.fill")
            .foregroundColor(Color(hex: "9966cc"))
        }
        .disabled(newMessage.isEmpty)
      }
      .padding()
    }
  }
}

public struct MessageCard: View {
  let message: QuantumMessage
  
  public var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(message.content)
        .font(.system(size: 16, design: .serif))
        .foregroundColor(.white)
      
      HStack {
        Text(message.timestamp, style: .time)
          .font(.system(size: 12, design: .serif))
          .foregroundColor(.gray)
        
        Spacer()
        
        Text(message.type.rawValue)
          .font(.system(size: 12, design: .serif))
          .foregroundColor(Color(hex: "9966cc"))
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
          .background(
            Capsule()
              .fill(Color(hex: "9966cc").opacity(0.2))
          )
      }
    }
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(Color(hex: "1a1a1a"))
    )
  }
}

public struct AIView: View {
  @ObservedObject var quantumNode: QuantumNode
  @State private var aiResponse = ""
  @State private var isProcessing = false
  
  public var body: some View {
    VStack(spacing: 20) {
      Text("AI Processing")
        .font(.system(size: 24, weight: .medium, design: .serif))
        .foregroundColor(.white)
      
      if isProcessing {
        ProgressView()
          .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "9966cc")))
          .scaleEffect(1.5)
      } else if !aiResponse.isEmpty {
        ScrollView {
          Text(aiResponse)
            .font(.system(size: 16, design: .serif))
            .foregroundColor(.white)
            .padding()
            .background(
              RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "1a1a1a"))
            )
        }
      } else {
        Text("No AI response yet")
          .font(.system(size: 16, design: .serif))
          .foregroundColor(.gray)
      }
      
      Spacer()
    }
    .padding()
  }
}

public struct ConnectionView: View {
  @ObservedObject var quantumNode: QuantumNode
  @Environment(\.dismiss) private var dismiss
  
  public var body: some View {
    NavigationView {
      VStack(spacing: 20) {
        Text("Quantum Network Connection")
          .font(.system(size: 24, weight: .medium, design: .serif))
          .foregroundColor(.white)
        
        VStack(spacing: 16) {
          Button("Connect to Celestial Network") {
            quantumNode.connectToCelestialNetwork()
          }
          .buttonStyle(.borderedProminent)
          .tint(Color(hex: "9966cc"))
          
          Button("Connect to Terrestrial Network") {
            quantumNode.connectToTerrestrialNetwork()
          }
          .buttonStyle(.borderedProminent)
          .tint(Color(hex: "9966cc"))
        }
        
        Spacer()
      }
      .padding()
      .navigationTitle("Connection")
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Done") {
            dismiss()
          }
        }
      }
    }
  }
}

#Preview {
  QuantumView()
} 