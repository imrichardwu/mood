import SwiftUI

struct EntryEditorView: View {
    enum Mode: Hashable {
        case new
        case edit(MoodEntry)

        var title: String {
            switch self {
            case .new: return "New Entry"
            case .edit: return "Edit Entry"
            }
        }
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme

    let mode: Mode
    let onSave: (MoodEntry) -> Void

    @State private var timestamp: Date = .now
    @State private var mood: Double = 6
    @State private var energy: Double = 6
    @State private var stress: Double = 4
    @State private var selectedTags: Set<Tag> = []
    @State private var note: String = ""

    init(mode: Mode, onSave: @escaping (MoodEntry) -> Void) {
        self.mode = mode
        self.onSave = onSave

        if case let .edit(entry) = mode {
            _timestamp = State(initialValue: entry.timestamp)
            _mood = State(initialValue: entry.mood)
            _energy = State(initialValue: entry.energy)
            _stress = State(initialValue: entry.stress)
            _selectedTags = State(initialValue: Set(entry.tags))
            _note = State(initialValue: entry.note)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient(for: scheme)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        metricsCard
                        tagsCard
                        noteCard
                    }
                    .padding()
                }
            }
            .navigationTitle(mode.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private var metricsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Check‑In")
                .font(.headline)

            DatePicker("Time", selection: $timestamp, displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.compact)

            MetricSlider(title: "Mood", value: $mood, tint: .indigo, icon: "face.smiling")
            MetricSlider(title: "Energy", value: $energy, tint: .teal, icon: "bolt.fill")
            MetricSlider(title: "Stress", value: $stress, tint: .orange, icon: "waveform.path.ecg")

            Text("Tip: keep it simple—your first instinct is usually enough.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .appCard()
    }

    private var tagsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Tags (optional)")
                .font(.headline)

            let cols = [GridItem(.adaptive(minimum: 92), spacing: 10)]
            LazyVGrid(columns: cols, alignment: .leading, spacing: 10) {
                ForEach(Tag.allCases) { tag in
                    Toggle(isOn: Binding(
                        get: { selectedTags.contains(tag) },
                        set: { isOn in
                            if isOn { selectedTags.insert(tag) } else { selectedTags.remove(tag) }
                        }
                    )) {
                        Text(tag.displayName)
                            .font(.callout)
                    }
                    .toggleStyle(.button)
                }
            }

            Text("Tags help your Trends and Insights tabs spot patterns.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .appCard()
    }

    private var noteCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Journal (optional)")
                .font(.headline)

            TextEditor(text: $note)
                .frame(minHeight: 120)
                .scrollContentBackground(.hidden)
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(AppTheme.cardBackground(for: scheme).opacity(0.55))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(AppTheme.cardStroke(for: scheme), lineWidth: 1)
                )

            Text("We’ll analyze tone on-device to support trend insights—nothing is uploaded.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .appCard()
    }

    private func save() {
        let clippedMood = mood.clamped(to: 0...10)
        let clippedEnergy = energy.clamped(to: 0...10)
        let clippedStress = stress.clamped(to: 0...10)

        let entry: MoodEntry
        switch mode {
        case .new:
            entry = MoodEntry(
                timestamp: timestamp,
                mood: clippedMood,
                energy: clippedEnergy,
                stress: clippedStress,
                tags: selectedTags.sorted(by: { $0.displayName < $1.displayName }),
                note: note
            )
        case let .edit(existing):
            entry = MoodEntry(
                id: existing.id,
                timestamp: timestamp,
                mood: clippedMood,
                energy: clippedEnergy,
                stress: clippedStress,
                tags: selectedTags.sorted(by: { $0.displayName < $1.displayName }),
                note: note,
                derived: existing.derived,
                health: existing.health
            )
        }

        onSave(entry)
        dismiss()
    }
}

private struct MetricSlider: View {
    let title: String
    @Binding var value: Double
    let tint: Color
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label(title, systemImage: icon)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(Int(value.rounded())) / 10")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Slider(value: $value, in: 0...10, step: 1)
                .tint(tint)
        }
    }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}


