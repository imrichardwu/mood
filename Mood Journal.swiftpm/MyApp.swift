import SwiftUI

@main
struct MyApp: App {
    @StateObject private var entryStore = EntryStore()
    @StateObject private var goalStore = GoalStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(entryStore)
                .environmentObject(goalStore)
                .tint(AppTheme.tint)
        }
    }
}
