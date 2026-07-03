import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(red: 0.05, green: 0.05, blue: 0.1)
                    .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    Text("Game Hub")
                        .font(.system(size: 50, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.bottom, 30)
                    
                    // Button for Tap Frenzy
                    NavigationLink(destination: ContentView()) {
                        Text("Tap Frenzy")
                            .font(.title2)
                            .bold()
                            .frame(maxWidth: 250)
                            .padding()
                            .background(
                                LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
                            )
                            .foregroundColor(.white)
                            .cornerRadius(15)
                            .shadow(color: .purple.opacity(0.5), radius: 10)
                    }
                    
                    // Button for Light It Up
                    NavigationLink(destination: LightItUpView()) {
                        Text("Light It Up")
                            .font(.title2)
                            .bold()
                            .frame(maxWidth: 250)
                            .padding()
                            .background(
                                LinearGradient(colors: [.orange, .red], startPoint: .leading, endPoint: .trailing)
                            )
                            .foregroundColor(.white)
                            .cornerRadius(15)
                            .shadow(color: .red.opacity(0.5), radius: 10)
                    }
                }
            }
        }
    }
}

#Preview {
    HomeView()
}
