import SwiftUI

struct SettingsView: View {
    @Environment(\.colorScheme) private var scheme
    @AppStorage("displayName") private var displayName: String = ""

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                    .ignoresSafeArea()

                List {
                    profileSection
                    aboutSection
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
        }
    }

    private var profileSection: some View {
        Section("Profile") {
            TextField("Your name", text: $displayName)
                .textContentType(.givenName)
                .autocorrectionDisabled()
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


