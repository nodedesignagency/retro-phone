import SwiftUI

/// The polished metal claw the finger is pulled round to.
struct FingerStop: View {
    let geometry: DialGeometry
    let size: CGFloat

    /// Unit radii the claw spans, from its tip over the holes out to the bezel.
    private let tipRadius = 0.64
    private let baseRadius = 1.0

    var body: some View {
        let radius = size / 2
        FingerStopShape()
            .fill(Finish.chromeBar)
            .overlay {
                FingerStopShape()
                    .stroke(
                        LinearGradient(colors: [.white.opacity(0.9), .white.opacity(0.1)], startPoint: .top, endPoint: .bottom),
                        lineWidth: 0.8
                    )
            }
            .frame(width: radius * 0.14, height: radius * (baseRadius - tipRadius))
            .offset(y: -radius * (baseRadius + tipRadius) / 2)
            .rotationEffect(.degrees(geometry.fingerStopAngle))
            .shadow(color: .black.opacity(0.65), radius: size * 0.008, x: size * 0.006, y: size * 0.01)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

/// Drawn pointing down: the top edge mounts on the bezel, the rounded tip
/// reaches in over the finger holes.
private struct FingerStopShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + w * 0.10, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + w * 0.90, y: rect.minY))
        path.addCurve(
            to: CGPoint(x: rect.minX + w * 0.80, y: rect.minY + h * 0.86),
            control1: CGPoint(x: rect.minX + w * 0.95, y: rect.minY + h * 0.35),
            control2: CGPoint(x: rect.minX + w * 0.90, y: rect.minY + h * 0.70)
        )
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + w * 0.30, y: rect.minY + h * 0.92),
            control: CGPoint(x: rect.minX + w * 0.62, y: rect.minY + h * 1.06)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX + w * 0.10, y: rect.minY),
            control1: CGPoint(x: rect.minX + w * 0.12, y: rect.minY + h * 0.70),
            control2: CGPoint(x: rect.minX + w * 0.02, y: rect.minY + h * 0.30)
        )
        path.closeSubpath()
        return path
    }
}
