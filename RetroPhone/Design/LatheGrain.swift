import SwiftUI

/// Fine concentric tool marks, like metal turned on a lathe.
struct LatheGrain: View {
    var seed: UInt64 = 1
    var intensity: Double = 1

    var body: some View {
        Canvas { context, size in
            var random = SeededRandom(seed: seed)
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let limit = min(size.width, size.height) / 2
            var radius: CGFloat = 1.5
            while radius < limit {
                let alpha = Double.random(in: 0.015...0.08, using: &random) * intensity
                let tone: Color = Bool.random(using: &random) ? .white : .black
                let ring = Path(ellipseIn: CGRect(
                    x: center.x - radius,
                    y: center.y - radius,
                    width: radius * 2,
                    height: radius * 2
                ))
                context.stroke(ring, with: .color(tone.opacity(alpha)), lineWidth: 0.5)
                radius += CGFloat.random(in: 0.7...2.0, using: &random)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
