import SwiftUI

struct SettingsView: View {
    @StateObject private var healthKit = HealthKitManager()
    @AppStorage("healthkitEnabled") private var healthkitEnabled: Bool = false
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient(for: scheme)
                    .ignoresSafeArea()

                List {
                    privacySection
                    healthSection
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

    private var healthSection: some View {
        Section("Health (Optional)") {
            Toggle("Use HealthKit context", isOn: $healthkitEnabled)
                .onChange(of: healthkitEnabled) { isOn in
                    if isOn {
                        Task {
                            await healthKit.requestAuthorization()
                            await healthKit.refreshToday()
                        }
                    } else {
                        // Keep any previously-read values, but don’t refresh.
                    }
                }

            HStack {
                Text("Status")
                Spacer()
                Text(statusText)
                    .foregroundStyle(.secondary)
            }

            if healthkitEnabled {
                Button("Refresh today’s context") {
                    Task { await healthKit.refreshToday() }
                }

                if let steps = healthKit.todaySteps {
                    HStack {
                        Text("Steps today")
                        Spacer()
                        Text("\(Int(steps.rounded()))")
                            .foregroundStyle(.secondary)
                    }
                }

                if let sleep = healthKit.lastNightSleepHours {
                    HStack {
                        Text("Sleep (last night)")
                        Spacer()
                        Text(String(format: "%.1f h", sleep))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if let msg = healthKit.lastErrorMessage {
                Text(msg)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Text("HealthKit is used only to provide optional context for trends and the Well‑Being score.")
                .font(.footnote)
                .foregroundStyle(.secondary)

        }
    }

    private var aboutSection: some View {
        Section("About") {
            Text("Mood Journal is a private, on‑device journal for daily check‑ins.")
                .foregroundStyle(.secondary)

            Text("Write entries, tag what’s going on, and review Trends and Insights over time.")
                .foregroundStyle(.secondary)

            Text("Optional: connect HealthKit to add steps and sleep context to your insights.")
                .foregroundStyle(.secondary)
        }
    }

    private var statusText: String {
        switch healthKit.authState {
        case .unavailable: return "Unavailable"
        case .notDetermined: return "Not requested"
        case .denied: return "Denied"
        case .authorized: return "Authorized"
        }
    }
}


