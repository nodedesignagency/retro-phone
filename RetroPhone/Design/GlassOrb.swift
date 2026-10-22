import SwiftUI

/// A round glass button body: tinted like coloured glass, or clear with a
/// holographic rim when there's no tint.
struct GlassOrb: View {
    var tint: Color?
    let diameter: CGFloat

    var body: some View {
        ZStack {
            if let tint {
                Circle()
                    .fill(RadialGradient(
                        colors: [tint, tint.opacity(0.62)],
                        center: UnitPoint(x: 0.5, y: 0.72),
                        startRadius: 0,
                        endRadius: diameter * 0.62
                    ))
                Circle()
                    .fill(LinearGradient(colors: [.clear, .black.opacity(0.28)], startPoint: .center, endPoint: .bottom))
            } else {
                Circle()
                    .fill(Color.white.opacity(0.07))
                Circle()
                    .fill(RadialGradient(
                        colors: [.white.opacity(0.10), .clear],
                        center: UnitPoint(x: 0.5, y: 0.9),
                        startRadius: 0,
                        endRadius: diameter * 0.5
                    ))
            }

            // Gloss on the upper curve.
            Ellipse()
                .fill(LinearGradient(
                    colors: [.white.opacity(tint == nil ? 0.26 : 0.5), .white.opacity(0)],
                    startPoint: .top,
                    endPoint: .bottom
                ))
                .frame(width: diameter * 0.7, height: diameter * 0.42)
                .offset(y: -diameter * 0.22)

            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.75), .white.opacity(0.06), .white.opacity(0.32)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
            Circle()
                .strokeBorder(
                    AngularGradient(gradient: Gradient(colors: Palette.prismLoop), center: .center),
                    lineWidth: 1.5
                )
                .blur(radius: 0.6)
                .opacity(tint == nil ? 0.55 : 0.25)
                .blendMode(.plusLighter)
        }
        .frame(width: diameter, height: diameter)
        .shadow(
            color: (tint ?? .white).opacity(tint == nil ? 0.06 : 0.42),
            radius: diameter * 0.2,
            y: diameter * 0.08
        )
    }
}
