import SwiftUI

struct SettingsView: View {
    @AppStorage("openAIKey") private var openAIKey = ""
    @AppStorage("dailyGoal") private var dailyGoal = 20
    
    var body: some View {
        NavigationStack {
            Form {
                Section("API Configuration") {
                    SecureField("OpenAI API Key", text: $openAIKey)
                }
                
                Section("Learning") {
                    Stepper("Daily goal: \(dailyGoal) words", value: $dailyGoal, in: 5...100, step: 5)
                }
                
                Section("Data") {
                    Button("Export Progress") {
                        // Export
                    }
                    
                    Button("Reset All Data", role: .destructive) {
                        // Reset
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}
