import SwiftUI

enum AppTheme {
    // Soft, soothing palette that remains readable in both light/dark.
    static let tint = Color(red: 0.20, green: 0.47, blue: 0.27) // rainforest green

    static func backgroundGradient(for scheme: ColorScheme) -> LinearGradient {
        switch scheme {
        case .dark:
            return LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.07, blue: 0.06),
                    Color(red: 0.06, green: 0.09, blue: 0.07),
                    Color(red: 0.07, green: 0.10, blue: 0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            return LinearGradient(
                colors: [
                    Color(red: 0.89, green: 0.94, blue: 0.82),
                    Color(red: 0.86, green: 0.93, blue: 0.80),
                    Color(red: 0.97, green: 0.93, blue: 0.83) // warm paper corner
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    static func cardBackground(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color.white.opacity(0.06)
            : Color(red: 0.97, green: 0.99, blue: 0.95).opacity(0.78)
    }

    static func cardStroke(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color.white.opacity(0.12)
            : Color.black.opacity(0.06)
    }
}

struct AppCard: ViewModifier {
    @Environment(\.colorScheme) private var scheme

    func body(content: Content) -> some View {
        content
            .padding(14)
            .background(AppTheme.cardBackground(for: scheme))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(AppTheme.cardStroke(for: scheme), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

extension View {
    func appCard() -> some View { modifier(AppCard()) }
}


