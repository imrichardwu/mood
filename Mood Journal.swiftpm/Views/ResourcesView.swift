import SwiftUI

struct ResourcesView: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ZStack {
            AppBackground()
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Privacy")
                            .font(.headline)
                        Text("Your entries are stored on this device. Journal text is analyzed on‑device for sentiment and keywords. Nothing is uploaded.")
                            .foregroundStyle(.secondary)
                    }
                    .appCard()

                    VStack(alignment: .leading, spacing: 10) {
                        Text("How it works")
                            .font(.headline)
                        Text("Write entries, add tags, and review Trends and Insights over time. Trends are best‑effort summaries and can be noisy—especially with fewer entries.")
                            .foregroundStyle(.secondary)
                    }
                    .appCard()
                }
                .padding()
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}


