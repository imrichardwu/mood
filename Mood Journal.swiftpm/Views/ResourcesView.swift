import SwiftUI

struct ResourcesView: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: scheme)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Disclaimer")
                            .font(.headline)
                        Text("Mood Journal is a reflection tool. It can help you notice patterns, but it is not medical advice and does not diagnose anything.")
                            .foregroundStyle(.secondary)
                        Text("If you feel unsafe or need urgent help, contact local emergency services or a trusted person right now.")
                            .foregroundStyle(.secondary)
                    }
                    .appCard()

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Privacy")
                            .font(.headline)
                        Text("Your entries are stored on this device. Journal text is analyzed on‑device for sentiment and keywords. Nothing is uploaded.")
                            .foregroundStyle(.secondary)
                    }
                    .appCard()

                    VStack(alignment: .leading, spacing: 10) {
                        Text("About trends")
                            .font(.headline)
                        Text("Trends are based on your check‑ins and optional HealthKit context. They are best‑effort summaries and can be noisy—especially with fewer entries.")
                            .foregroundStyle(.secondary)
                    }
                    .appCard()
                }
                .padding()
            }
        }
        .navigationTitle("Resources")
        .navigationBarTitleDisplayMode(.inline)
    }
}


