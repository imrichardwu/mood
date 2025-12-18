import SwiftUI

struct TabShell: View {
    @Environment(\.colorScheme) private var scheme
    @EnvironmentObject private var entryStore: EntryStore
    @State private var selectedTab: Tab = .journal

    enum Tab: Hashable {
        case journal
        case trends
        case insights
        case settings
    }

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: scheme)
                .ignoresSafeArea()

            TabView(selection: $selectedTab) {
                JournalView()
                    .tabItem { Label("Journal", systemImage: "book.closed") }
                    .tag(Tab.journal)

                TrendsView()
                    .tabItem { Label("Trends", systemImage: "chart.xyaxis.line") }
                    .tag(Tab.trends)

                InsightsView()
                    .tabItem { Label("Insights", systemImage: "sparkles") }
                    .tag(Tab.insights)

                SettingsView()
                    .tabItem { Label("Settings", systemImage: "gearshape") }
                    .tag(Tab.settings)
            }
        }
        .tint(AppTheme.tint)
    }
}
