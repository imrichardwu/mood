import SwiftUI

struct TabShell: View {
    @Environment(\.colorScheme) private var scheme
    @EnvironmentObject private var entryStore: EntryStore
    @State private var selectedTab: Tab = .checkIn

    enum Tab: Hashable {
        case checkIn
        case trends
        case insights
        case settings
    }

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: scheme)
                .ignoresSafeArea()

            TabView(selection: $selectedTab) {
                CheckInView()
                    .tabItem { Label("Check‑In", systemImage: "square.and.pencil") }
                    .tag(Tab.checkIn)

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
