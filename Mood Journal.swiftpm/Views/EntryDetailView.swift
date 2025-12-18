import SwiftUI

struct EntryDetailView: View {
    @EnvironmentObject private var entryStore: EntryStore
    @Environment(\.colorScheme) private var scheme
    @ScaledMetric(relativeTo: .title) private var scoreSize: CGFloat = 42

    let entry: MoodEntry
    @State private var isEditing = false

    // NOTE: This view receives a value-type `MoodEntry`. We refresh by reading from the store on appear.
    @State private var current: MoodEntry?

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: scheme)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    summaryCard
                    scoreCard
                    if let note = current?.note, !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        noteCard(note: note)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Entry")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { isEditing = true }
            }
        }
        .onAppear { refresh() }
        .sheet(isPresented: $isEditing) {
            if let current {
                EntryEditorView(mode: .edit(current)) { updated in
                    entryStore.update(updated)
                    self.current = updated
                }
            }
        }
    }

    private var summaryCard: some View {
        let e = current ?? entry
        return VStack(alignment: .leading, spacing: 12) {
            Text(e.timestamp, format: .dateTime.weekday().month().day().hour().minute())
                .font(.headline)

            HStack(spacing: 12) {
                MetricPill(title: "Mood", value: Int(e.mood.rounded()), tint: .indigo)
                MetricPill(title: "Energy", value: Int(e.energy.rounded()), tint: .teal)
                MetricPill(title: "Stress", value: Int(e.stress.rounded()), tint: .orange)
            }

            if !e.tags.isEmpty {
                Text(e.tags.map(\.displayName).joined(separator: " · "))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .appCard()
    }

    private var scoreCard: some View {
        let e = current ?? entry
        let breakdown = WellBeingScorer().breakdown(for: e)
        return VStack(alignment: .leading, spacing: 8) {
            Text("Well‑Being score")
                .font(.headline)
            HStack(alignment: .firstTextBaseline) {
                Text("\(Int(breakdown.total.rounded()))")
                    .font(.system(size: scoreSize, weight: .semibold, design: .rounded))
                Text("/ 100")
                    .foregroundStyle(.secondary)
                Spacer()
            }
            Text("Includes mood, energy, stress, journal tone (and optional HealthKit context).")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .appCard()
    }

    private func noteCard(note: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Journal")
                .font(.headline)
            Text(note)
                .font(.body)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .appCard()
    }

    private func refresh() {
        current = entryStore.entries.first(where: { $0.id == entry.id }) ?? entry
    }
}

private struct MetricPill: View {
    let title: String
    let value: Int
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("\(value)/10")
                .font(.headline)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}


