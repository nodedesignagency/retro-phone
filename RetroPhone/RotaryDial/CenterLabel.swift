import SwiftUI

/// The printed number card under its domed glass, held by a chrome ring.
struct CenterLabel: View {
    let diameter: CGFloat

    var body: some View {
        let ring = diameter * 0.075
        ZStack {
            Circle().fill(Finish.chrome)
            Circle()
                .strokeBorder(
                    LinearGradient(colors: [.white.opacity(0.8), .black.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 0.75
                )
            LabelCard(diameter: diameter - ring * 2)
        }
        .frame(width: diameter, height: diameter)
        .shadow(color: .black.opacity(0.55), radius: diameter * 0.04, x: diameter * 0.01, y: diameter * 0.03)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct LabelCard: View {
    let diameter: CGFloat

    private let typeface = "GillSans-SemiBold"

    var body: some View {
        ZStack {
            Circle().fill(Finish.silver)
            LatheGrain(seed: 42, intensity: 0.6)
            // The retaining ring's shadow falling on the card.
            Circle()
                .stroke(Color.black.opacity(0.45), lineWidth: diameter * 0.05)
                .blur(radius: diameter * 0.02)
                .offset(x: diameter * 0.008, y: diameter * 0.016)
            printing
            // Domed glass over the card.
            Ellipse()
                .fill(LinearGradient(colors: [.white.opacity(0.38), .white.opacity(0)], startPoint: .top, endPoint: .bottom))
                .frame(width: diameter * 0.78, height: diameter * 0.42)
                .offset(y: -diameter * 0.24)
            Circle()
                .strokeBorder(
                    LinearGradient(colors: [.white.opacity(0.6), .white.opacity(0.05)], startPoint: .top, endPoint: .bottom),
                    lineWidth: 1
                )
        }
        .frame(width: diameter, height: diameter)
        .clipShape(Circle())
    }

    private var printing: some View {
        ZStack {
            CurvedText(
                text: "LISTEN BEFORE CALLING",
                fontName: typeface,
                fontSize: diameter * 0.062,
                radius: diameter * 0.38,
                tracking: diameter * 0.006
            )
            VStack(spacing: diameter * 0.015) {
                Text("PULL DIAL ROUND")
                Text("TO STOP & LET GO")
            }
            .font(.custom(typeface, size: diameter * 0.082))
            .tracking(diameter * 0.004)
            .offset(y: diameter * 0.02)
            HStack(alignment: .lastTextBaseline, spacing: diameter * 0.02) {
                Text("No.")
                Rectangle()
                    .frame(width: diameter * 0.30, height: max(diameter * 0.007, 0.75))
            }
            .font(.custom(typeface, size: diameter * 0.072))
            .offset(y: diameter * 0.27)
        }
        .foregroundStyle(Palette.ink)
        // Letterpress: a hairline of light under the ink.
        .shadow(color: .white.opacity(0.5), radius: 0, x: 0, y: 0.6)
    }
}
