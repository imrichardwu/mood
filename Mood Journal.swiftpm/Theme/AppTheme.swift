import SwiftUI

enum AppTheme {
    // Soft, soothing palette that remains readable in both light/dark.
    static let tint = Color.indigo

    static func backgroundGradient(for scheme: ColorScheme) -> LinearGradient {
        switch scheme {
        case .dark:
            return LinearGradient(
                colors: [
                    Color(red: 0.06, green: 0.07, blue: 0.10),
                    Color(red: 0.07, green: 0.09, blue: 0.14),
                    Color(red: 0.08, green: 0.10, blue: 0.16)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            return LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.97, blue: 1.00),
                    Color(red: 0.95, green: 0.96, blue: 0.99),
                    Color(red: 0.96, green: 0.95, blue: 0.99)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    static func cardBackground(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color.white.opacity(0.06)
            : Color.white.opacity(0.70)
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


