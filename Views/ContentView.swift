import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            
            WordListView()
                .tabItem {
                    Label("Words", systemImage: "book.fill")
                }
            
            PracticeView()
                .tabItem {
                    Label("Practice", systemImage: "brain.head.profile")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Word.self, Definition.self], inMemory: true)
}
