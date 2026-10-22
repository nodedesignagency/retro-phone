import SwiftUI

/// A four-pointed sparkle that catches the light every few seconds.
struct Glint: View {
    let size: CGFloat
    /// Seconds between twinkles; give each glint a different cycle so they drift apart.
    var cycle: Double = 6

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if !reduceMotion {
            ZStack {
                Circle()
                    .fill(.white)
                    .frame(width: size * 0.25, height: size * 0.25)
                    .blur(radius: size * 0.12)
                SparkleShape()
                    .fill(.white)
                    .frame(width: size, height: size)
            }
            .keyframeAnimator(initialValue: 0.0, repeating: true) { content, value in
                content
                    .scaleEffect(0.3 + 0.7 * value)
                    .rotationEffect(.degrees(value * 45))
                    .opacity(value)
            } keyframes: { _ in
                KeyframeTrack {
                    LinearKeyframe(0.0, duration: max(cycle - 1.3, 0.5))
                    CubicKeyframe(1.0, duration: 0.35)
                    CubicKeyframe(0.0, duration: 0.95)
                }
            }
            .blendMode(.plusLighter)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }
}

struct SparkleShape: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var path = Path()
        path.move(to: CGPoint(x: center.x, y: center.y - radius))
        path.addQuadCurve(to: CGPoint(x: center.x + radius, y: center.y), control: center)
        path.addQuadCurve(to: CGPoint(x: center.x, y: center.y + radius), control: center)
        path.addQuadCurve(to: CGPoint(x: center.x - radius, y: center.y), control: center)
        path.addQuadCurve(to: CGPoint(x: center.x, y: center.y - radius), control: center)
        path.closeSubpath()
        return path
    }
}
