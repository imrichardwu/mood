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
    @FocusState private var isNoteFocused: Bool

    let mode: Mode
    let onSave: (MoodEntry) -> Void
    private let prefillNote: String?

    @State private var timestamp: Date = .now
    @State private var mood: Double = 6
    @State private var energy: Double = 6
    @State private var stress: Double = 4
    @State private var selectedTags: Set<Tag> = []
    @State private var note: String = ""

    init(mode: Mode, prefillNote: String? = nil, onSave: @escaping (MoodEntry) -> Void) {
        self.mode = mode
        self.prefillNote = prefillNote
        self.onSave = onSave

        if case let .edit(entry) = mode {
            _timestamp = State(initialValue: entry.timestamp)
            _mood = State(initialValue: entry.mood)
            _energy = State(initialValue: entry.energy)
            _stress = State(initialValue: entry.stress)
            _selectedTags = State(initialValue: Set(entry.tags))
            _note = State(initialValue: entry.note)
        } else if let prefillNote, !prefillNote.isEmpty {
            _note = State(initialValue: prefillNote)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        noteCard
                        metricsCard
                        tagsCard
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
        .onAppear {
            // Make it feel like a journal: put the cursor in the page.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                isNoteFocused = true
            }
        }
    }

    private var metricsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How did you feel?")
                .font(.headline)

            DatePicker("Time", selection: $timestamp, displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.compact)

            MetricSlider(title: "Mood", value: $mood, tint: AppTheme.tint, icon: "face.smiling")
            MetricSlider(title: "Energy", value: $energy, tint: AppTheme.energyTint, icon: "bolt.fill")
            MetricSlider(title: "Stress", value: $stress, tint: AppTheme.stressTint, icon: "waveform.path.ecg")

            Text("Tip: write first, then add numbers if you want.")
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
            Text("Journal")
                .font(.headline)

            ZStack(alignment: .topLeading) {
                TextEditor(text: $note)
                    .focused($isNoteFocused)
                    .frame(minHeight: 180)
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

                if note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("What happened today?\nWhat did you notice in your body?\nWhat do you need right now?")
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 18)
                        .allowsHitTesting(false)
                }
            }

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
                derived: existing.derived
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


