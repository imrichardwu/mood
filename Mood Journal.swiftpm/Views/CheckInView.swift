import SwiftUI

struct CheckInView: View {
    @EnvironmentObject private var entryStore: EntryStore
    @State private var isPresentingNewEntry = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                header

                if entryStore.entries.isEmpty {
                    emptyState
                } else {
                    entriesList
                }
            }
            .padding()
            .navigationTitle("Check‑In")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isPresentingNewEntry = true
                    } label: {
                        Label("New Entry", systemImage: "plus")
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
            Text("How are you, right now?")
                .font(.title2.weight(.semibold))
            Text("Quick check‑ins build a clearer picture over time. Everything stays on your device.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCard()
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("No entries yet.")
                .font(.headline)
            Text("Start with a 10‑second check‑in. You can add a note if you want.")
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

    private var entriesList: some View {
        List {
            Section("Recent") {
                ForEach(entryStore.entries) { entry in
                    NavigationLink {
                        EntryDetailView(entry: entry)
                    } label: {
                        EntryRow(entry: entry)
                    }
                }
                .onDelete { indexSet in
                    for idx in indexSet {
                        let entry = entryStore.entries[idx]
                        entryStore.delete(entry)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct EntryRow: View {
    let entry: MoodEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(entry.timestamp, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day().hour().minute())
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("Mood \(Int(entry.mood.rounded()))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if !entry.tags.isEmpty {
                Text(entry.tags.map(\.displayName).joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !entry.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(entry.note)
                    .font(.caption)
                    .lineLimit(2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}


