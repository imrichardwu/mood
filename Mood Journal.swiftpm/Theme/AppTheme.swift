import SwiftUI

enum AppTheme {
    // Soft, soothing palette that remains readable in both light/dark.
    static let tint = Color(red: 0.20, green: 0.47, blue: 0.27) // rainforest green
    static let energyTint = Color(red: 0.20, green: 0.62, blue: 0.40)
    static let stressTint = Color(red: 0.79, green: 0.48, blue: 0.18)
    static let nightInk = Color(red: 0.07, green: 0.09, blue: 0.05) // warm-olive ink (no blue cast)

    static func backgroundGradient(for scheme: ColorScheme) -> LinearGradient {
        switch scheme {
        case .dark:
            return LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.06, blue: 0.03),
                    Color(red: 0.06, green: 0.08, blue: 0.04),
                    Color(red: 0.07, green: 0.09, blue: 0.05)
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
            ? Color(red: 0.08, green: 0.11, blue: 0.07).opacity(0.92)
            : Color(red: 0.97, green: 0.99, blue: 0.95).opacity(0.78)
    }

    static func cardStroke(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? tint.opacity(0.22)
            : Color.black.opacity(0.06)
    }
}

/// Shared app background: rainforest gradient + subtle illustration overlay.
struct AppBackground: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: scheme)
            RainforestOverlay()
        }
        .allowsHitTesting(false)
    }
}

private struct RainforestOverlay: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                // Speckle texture
                Canvas { context, size in
                    let count = scheme == .dark ? 220 : 320
                    for i in 0..<count {
                        let x = pseudo(i, mod: 10_000) / 10_000.0 * size.width
                        let y = pseudo(i + 999, mod: 10_000) / 10_000.0 * size.height
                        let r = (pseudo(i + 4242, mod: 1000) / 1000.0) * (scheme == .dark ? 1.3 : 1.8)
                        let alpha = scheme == .dark ? 0.08 : 0.10
                        context.fill(
                            Path(ellipseIn: CGRect(x: x, y: y, width: r, height: r)),
                            with: .color(Color.white.opacity(alpha))
                        )
                    }
                }

                // Large leaf blobs (top-right / bottom-right)
                LeafBlob()
                    .fill(scheme == .dark ? Color(red: 0.12, green: 0.22, blue: 0.12).opacity(0.75)
                                         : Color(red: 0.22, green: 0.45, blue: 0.22).opacity(0.22))
                    .frame(width: w * 0.70, height: h * 0.42)
                    .rotationEffect(.degrees(-18))
                    .offset(x: w * 0.40, y: -h * 0.16)

                LeafBlob()
                    .fill(scheme == .dark ? Color(red: 0.10, green: 0.18, blue: 0.10).opacity(0.70)
                                         : Color(red: 0.18, green: 0.38, blue: 0.18).opacity(0.20))
                    .frame(width: w * 0.78, height: h * 0.46)
                    .rotationEffect(.degrees(14))
                    .offset(x: w * 0.34, y: h * 0.30)

                // Simple flower cluster (top-left)
                FlowerCluster()
                    .frame(width: w * 0.38, height: h * 0.22)
                    .offset(x: -w * 0.30, y: -h * 0.34)
                    .opacity(scheme == .dark ? 0.55 : 0.85)
            }
            .opacity(scheme == .dark ? 0.30 : 0.55)
        }
    }

    private func pseudo(_ seed: Int, mod: Int) -> Double {
        // Tiny deterministic pseudo-random for speckles.
        let a = 1103515245
        let c = 12345
        let x = (a &* seed &+ c) % max(mod, 1)
        return Double(abs(x))
    }
}

private struct LeafBlob: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height
        let x0 = rect.minX
        let y0 = rect.minY

        p.move(to: CGPoint(x: x0 + w * 0.10, y: y0 + h * 0.55))
        p.addCurve(
            to: CGPoint(x: x0 + w * 0.55, y: y0 + h * 0.10),
            control1: CGPoint(x: x0 + w * 0.18, y: y0 + h * 0.20),
            control2: CGPoint(x: x0 + w * 0.38, y: y0 + h * 0.08)
        )
        p.addCurve(
            to: CGPoint(x: x0 + w * 0.92, y: y0 + h * 0.55),
            control1: CGPoint(x: x0 + w * 0.76, y: y0 + h * 0.12),
            control2: CGPoint(x: x0 + w * 0.94, y: y0 + h * 0.30)
        )
        p.addCurve(
            to: CGPoint(x: x0 + w * 0.55, y: y0 + h * 0.92),
            control1: CGPoint(x: x0 + w * 0.90, y: y0 + h * 0.84),
            control2: CGPoint(x: x0 + w * 0.74, y: y0 + h * 0.96)
        )
        p.addCurve(
            to: CGPoint(x: x0 + w * 0.10, y: y0 + h * 0.55),
            control1: CGPoint(x: x0 + w * 0.30, y: y0 + h * 0.88),
            control2: CGPoint(x: x0 + w * 0.06, y: y0 + h * 0.78)
        )
        p.closeSubpath()
        return p
    }
}

private struct FlowerCluster: View {
    var body: some View {
        ZStack {
            SingleFlower()
                .offset(x: -40, y: -10)
            SingleFlower(scale: 0.85)
                .offset(x: 10, y: -24)
            SingleFlower(scale: 0.70)
                .offset(x: -8, y: 18)
        }
    }
}

private struct SingleFlower: View {
    var scale: CGFloat = 1.0

    var body: some View {
        ZStack {
            ForEach(0..<6) { i in
                Capsule()
                    .fill(Color.white.opacity(0.95))
                    .frame(width: 10 * scale, height: 26 * scale)
                    .offset(y: -10 * scale)
                    .rotationEffect(.degrees(Double(i) * 60))
            }
            Circle()
                .fill(Color(red: 0.98, green: 0.78, blue: 0.82).opacity(0.95))
                .frame(width: 10 * scale, height: 10 * scale)
        }
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


