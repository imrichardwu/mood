import SwiftUI

struct SettingsView: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                    .ignoresSafeArea()

                List {
                    privacySection
                    aboutSection
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
        }
    }

    private var privacySection: some View {
        Section("Privacy") {
            Label("On‑device by default", systemImage: "lock.shield")
            Text("No accounts. No tracking. No uploads.")
                .foregroundStyle(.secondary)
        }
    }

    private var aboutSection: some View {
        Section("About") {
            Text("Mood Journal is a private, on‑device journal for daily check‑ins.")
                .foregroundStyle(.secondary)

            Text("Write entries, tag what’s going on, and review Trends and Insights over time.")
                .foregroundStyle(.secondary)
        }
    }
}


