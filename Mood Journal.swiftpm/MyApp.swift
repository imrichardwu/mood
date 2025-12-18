import SwiftUI

@main
struct MyApp: App {
    @StateObject private var entryStore = EntryStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(entryStore)
        }
    }
}
