import SwiftUI

struct GoalEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme

    let existing: Goal?
    let onSave: (Goal, /*isEdit*/ Bool) -> Void

    @State private var title: String = ""
    @State private var kind: Goal.Kind = .entriesToday
    @State private var target: Double = Goal.Kind.entriesToday.defaultTarget
    @State private var isActive: Bool = true

    init(existing: Goal?, onSave: @escaping (Goal, Bool) -> Void) {
        self.existing = existing
        self.onSave = onSave

        if let existing {
            _title = State(initialValue: existing.title)
            _kind = State(initialValue: existing.kind)
            _target = State(initialValue: existing.target)
            _isActive = State(initialValue: existing.isActive)
        } else {
            _title = State(initialValue: "")
            _kind = State(initialValue: .entriesToday)
            _target = State(initialValue: Goal.Kind.entriesToday.defaultTarget)
            _isActive = State(initialValue: true)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient(for: scheme)
                    .ignoresSafeArea()

                Form {
                    Section("Goal") {
                        TextField("Title", text: $title)

                        Picker("Type", selection: $kind) {
                            ForEach(Goal.Kind.allCases) { k in
                                Text(k.displayName).tag(k)
                            }
                        }
                        .onChange(of: kind) { newKind in
                            // Keep targets sensible when switching types.
                            let clamped = min(max(target, newKind.targetBounds.lowerBound), newKind.targetBounds.upperBound)
                            if clamped == target { return }
                            target = clamped
                        }

                        targetPicker
                        Toggle("Active", isOn: $isActive)
                    }

                    Section {
                        Text(helperText)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(existing == nil ? "New Goal" : "Edit Goal")
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

    @ViewBuilder
    private var targetPicker: some View {
        switch kind {
        case .sleepLastNight:
            Stepper(value: $target, in: kind.targetBounds, step: kind.targetStep) {
                Text(String(format: "Target: %.1f %@", target, kind.unitLabel))
            }
        case .stepsToday:
            Stepper(value: $target, in: kind.targetBounds, step: kind.targetStep) {
                Text("Target: \(Int(target.rounded())) \(kind.unitLabel)")
            }
        default:
            Stepper(value: $target, in: kind.targetBounds, step: kind.targetStep) {
                Text("Target: \(Int(target.rounded())) \(kind.unitLabel)")
            }
        }
    }

    private var helperText: String {
        switch kind {
        case .entriesToday:
            return "Counts how many entries you write today."
        case .entriesThisWeek:
            return "Counts how many entries you write this week."
        case .daysThisWeek:
            return "Counts how many days this week you journal at least once."
        case .stepsToday:
            return "Uses HealthKit steps today (enable HealthKit in Settings)."
        case .sleepLastNight:
            return "Uses HealthKit sleep from last night (enable HealthKit in Settings)."
        }
    }

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalTitle = trimmedTitle.isEmpty ? kind.displayName : trimmedTitle

        let clampedTarget = min(max(target, kind.targetBounds.lowerBound), kind.targetBounds.upperBound)

        if var existing {
            existing.title = finalTitle
            existing.kind = kind
            existing.target = clampedTarget
            existing.isActive = isActive
            onSave(existing, true)
        } else {
            let g = Goal(title: finalTitle, kind: kind, target: clampedTarget, isActive: isActive)
            onSave(g, false)
        }
        dismiss()
    }
}

