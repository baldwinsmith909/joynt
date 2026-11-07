import SwiftUI

enum JoyntTheme {
    // APM poster palette
    static let cream = Color(red: 0.949, green: 0.941, blue: 0.902) // #F2F0E6
    static let creamDeep = Color(red: 0.929, green: 0.918, blue: 0.863)
    static let lime = Color(red: 0.812, green: 0.965, blue: 0.216) // #CFF637-ish
    static let coral = Color(red: 0.902, green: 0.318, blue: 0.192) // #E65131
    static let mint = Color(red: 0.420, green: 0.851, blue: 0.761)
    static let lavender = Color(red: 0.780, green: 0.733, blue: 0.918)
    static let electricBlue = Color(red: 0.180, green: 0.357, blue: 0.949)
    static let stickyYellow = Color(red: 1.0, green: 0.945, blue: 0.620)
    static let stickyPink = Color(red: 1.0, green: 0.820, blue: 0.820)
    static let ink = Color.black
    static let gridLine = Color.black.opacity(0.06)

    static let frameWidth: CGFloat = 3
    static let hardShadow = CGSize(width: 5, height: 5)
    static let noteMaxCharacters = 140

    static func accent(for index: Int) -> Color {
        let accents = [lime, coral, mint, lavender, electricBlue, stickyYellow]
        return accents[abs(index) % accents.count]
    }
}

struct CreamGridBackground: View {
    var spacing: CGFloat = 28

    var body: some View {
        Canvas { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(JoyntTheme.cream))
            var path = Path()
            stride(from: 0, through: size.width, by: spacing).forEach { x in
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
            }
            stride(from: 0, through: size.height, by: spacing).forEach { y in
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
            }
            context.stroke(path, with: .color(JoyntTheme.gridLine), lineWidth: 1)
        }
        .ignoresSafeArea()
    }
}

struct HardShadowModifier: ViewModifier {
    var color: Color = .black
    var offset: CGSize = JoyntTheme.hardShadow

    func body(content: Content) -> some View {
        content
            .background(
                color
                    .offset(x: offset.width, y: offset.height)
            )
    }
}

extension View {
    func joyntHardShadow(color: Color = .black, offset: CGSize = JoyntTheme.hardShadow) -> some View {
        modifier(HardShadowModifier(color: color, offset: offset))
    }

    func joyntPosterType(_ size: CGFloat = 34) -> some View {
        self
            .font(.system(size: size, weight: .black, design: .default))
            .tracking(-0.8)
            .foregroundStyle(JoyntTheme.ink)
    }

    func joyntMetaLabel() -> some View {
        self
            .font(.system(size: 11, weight: .semibold, design: .monospaced))
            .tracking(1.6)
            .textCase(.uppercase)
            .foregroundStyle(JoyntTheme.ink)
    }
}
