import SwiftUI

struct BreathingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var phase: Phase = .inhale
    @State private var isAnimating = false

    enum Phase: String {
        case inhale = "Inhale"
        case hold = "Hold"
        case exhale = "Exhale"

        var subtitle: String {
            switch self {
            case .inhale: return "Slowly breathe in"
            case .hold: return "Pause gently"
            case .exhale: return "Slowly breathe out"
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient(for: scheme)
                    .ignoresSafeArea()

                VStack(spacing: 18) {
                    Text(phase.rawValue)
                        .font(.title.weight(.semibold))
                    Text(phase.subtitle)
                        .foregroundStyle(.secondary)

                    ZStack {
                        Circle()
                            .fill(AppTheme.tint.opacity(0.10))
                            .frame(width: 220, height: 220)
                        Circle()
                            .fill(AppTheme.tint.opacity(0.22))
                            .frame(width: isAnimating ? 220 : 140, height: isAnimating ? 220 : 140)
                            .animation(reduceMotion ? nil : .easeInOut(duration: 4), value: isAnimating)
                    }
                    .accessibilityHidden(true)

                    Text(reduceMotion ? "Reduce Motion is enabled—showing a steady visual." : "Follow the circle: expand on inhale, soften on exhale.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Button("Done") { dismiss() }
                        .buttonStyle(.borderedProminent)
                        .padding(.top, 6)
                }
                .padding()
            }
            .navigationTitle("Reset moment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .onAppear { start() }
    }

    private func start() {
        isAnimating = true
        guard !reduceMotion else { return }

        // Simple loop: inhale (expand) -> hold -> exhale (shrink).
        Task { @MainActor in
            while true {
                phase = .inhale
                isAnimating = true
                try? await Task.sleep(nanoseconds: 4_000_000_000)

                phase = .hold
                try? await Task.sleep(nanoseconds: 1_500_000_000)

                phase = .exhale
                isAnimating = false
                try? await Task.sleep(nanoseconds: 4_000_000_000)

                phase = .hold
                try? await Task.sleep(nanoseconds: 1_500_000_000)
            }
        }
    }
}


