import SwiftUI

struct JournalView: View {
    @EnvironmentObject private var entryStore: EntryStore
    @State private var isPresentingNewEntry = false
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient(for: scheme)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        header
                        writeCard

                        if entryStore.entries.isEmpty {
                            emptyState
                        } else {
                            journalTimeline
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Journal")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isPresentingNewEntry = true
                    } label: {
                        Label("Write", systemImage: "square.and.pencil")
                    }
                }
            }
        }
        .sheet(isPresented: $isPresentingNewEntry) {
            EntryEditorView(mode: .new) { saved in
                entryStore.add(saved)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(Date.now, format: .dateTime.weekday(.wide).month(.wide).day())
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Write what’s on your mind.")
                .font(.title2.weight(.semibold))
            Text("This is your private space—kept on-device.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCard()
    }

    private var writeCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("New entry")
                .font(.headline)
            Text("A few lines is enough. You can also just log how you felt.")
                .font(.callout)
                .foregroundStyle(.secondary)

            Button {
                isPresentingNewEntry = true
            } label: {
                Text("Write")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .appCard()
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("No entries yet.")
                .font(.headline)
            Text("Start with a few lines about today, or just a quick mood check‑in.")
                .foregroundStyle(.secondary)
            Button {
                isPresentingNewEntry = true
            } label: {
                Text("Add your first entry")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .appCard()
    }

    private var journalTimeline: some View {
        LazyVStack(alignment: .leading, spacing: 14) {
            ForEach(groupedEntries, id: \.day) { section in
                DaySection(
                    day: section.day,
                    entries: section.entries,
                    onDelete: { entryStore.delete($0) }
                )
            }
        }
    }

    private var groupedEntries: [(day: Date, entries: [MoodEntry])] {
        let cal = Calendar.current
        let grouped = Dictionary(grouping: entryStore.entries) { cal.startOfDay(for: $0.timestamp) }
        return grouped.keys
            .sorted(by: >)
            .map { day in
                let items = (grouped[day] ?? []).sorted(by: { $0.timestamp > $1.timestamp })
                return (day: day, entries: items)
            }
    }
}

private struct DaySection: View {
    let day: Date
    let entries: [MoodEntry]
    let onDelete: (MoodEntry) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(day, format: .dateTime.month(.wide).day().year())
                .font(.headline)

            VStack(spacing: 10) {
                ForEach(entries) { entry in
                    NavigationLink {
                        EntryDetailView(entry: entry)
                    } label: {
                        JournalEntryCard(entry: entry)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(role: .destructive) {
                            onDelete(entry)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .appCard()
    }
}

private struct JournalEntryCard: View {
    let entry: MoodEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(entry.timestamp, format: .dateTime.hour().minute())
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("Mood \(Int(entry.mood.rounded()))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if !entry.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(entry.note)
                    .font(.body)
                    .lineLimit(4)
                    .foregroundStyle(.primary)
            } else {
                Text("No text for this entry.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            if !entry.tags.isEmpty {
                Text(entry.tags.map(\.displayName).joined(separator: " · "))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }
}


