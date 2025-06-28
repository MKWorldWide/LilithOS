import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var ritualVM = RitualViewModel()
    
    var body: some View {
        ZStack {
            CameraView()
                .ignoresSafeArea()
            VStack {
                Spacer()
                Image(nsImage: ritualVM.crest)
                    .resizable()
                    .frame(width: 120, height: 120)
                    .shadow(radius: 10)
                    .padding(.bottom, 20)
                ScrollView {
                    ForEach(ritualVM.logs, id: \ .self) { log in
                        Text(log)
                            .font(.caption)
                            .foregroundColor(.green)
                            .padding(2)
                    }
                }
                .frame(height: 120)
                Button(action: {
                    ritualVM.sendTestCommand()
                }) {
                    Text("Send Ritual Command")
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.bottom, 30)
            }
        }
        .onAppear {
            ritualVM.fetchCrest()
        }
    }
} 