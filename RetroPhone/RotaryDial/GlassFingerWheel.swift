import SwiftUI

/// The clear acrylic finger wheel.
///
/// Only the wheel's outline turns. Its lighting is drawn in screen space and
/// cut to the turning shape, so highlights stay put relative to the light the
/// way they do on real glass, and each frame only moves a mask and ten rims.
struct GlassFingerWheel: View {
    let engine: RotaryDialEngine
    let size: CGFloat

    var body: some View {
        let geometry = engine.geometry
        let rotation = engine.rotation
        let engaged = engine.engagedHole
        let radius = size / 2

        ZStack {
            // The plate seen through the acrylic: softened and very slightly magnified.
            DialPlate(geometry: geometry, size: size)
                .scaleEffect(1.015)
                .blur(radius: size * 0.009)
                .drawingGroup()
                .mask { WheelCutout(geometry: geometry, rotation: rotation) }

            GlassLighting(size: size)
                .mask { WheelCutout(geometry: geometry, rotation: rotation) }
                .blendMode(.screen)

            WheelEdges(geometry: geometry, size: size)

            ForEach(DialGeometry.digits.indices, id: \.self) { hole in
                let center = geometry.center(ofHole: hole, rotation: rotation)
                HoleRim(diameter: geometry.holeRadius * size, isEngaged: engaged == hole)
                    .offset(x: center.x * radius, y: center.y * radius)
            }
        }
        .frame(width: size, height: size)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Ring with ten finger holes punched through it.
struct FingerWheelShape: Shape {
    let geometry: DialGeometry

    func path(in rect: CGRect) -> Path {
        let radius = min(rect.width, rect.height) / 2
        let center = CGPoint(x: rect.midX, y: rect.midY)
        func circle(_ point: CGPoint, _ r: CGFloat) -> CGRect {
            CGRect(x: point.x - r, y: point.y - r, width: r * 2, height: r * 2)
        }

        var path = Path()
        path.addEllipse(in: circle(center, radius * geometry.wheelOuterRadius))
        path.addEllipse(in: circle(center, radius * geometry.wheelInnerRadius))
        for hole in DialGeometry.digits.indices {
            let unit = geometry.center(ofHole: hole)
            let point = CGPoint(x: center.x + unit.x * radius, y: center.y + unit.y * radius)
            path.addEllipse(in: circle(point, radius * geometry.holeRadius))
        }
        return path
    }
}

private struct WheelCutout: View {
    let geometry: DialGeometry
    let rotation: Double

    var body: some View {
        FingerWheelShape(geometry: geometry)
            .fill(Color.white, style: FillStyle(eoFill: true))
            .rotationEffect(.degrees(rotation))
    }
}

/// Light falling on the acrylic from the top left: a broad sheen, a glare
/// streak, and a prismatic caustic on the far side.
private struct GlassLighting: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            Color.white.opacity(0.05)
            LinearGradient(
                stops: [
                    .init(color: .white.opacity(0.26), location: 0),
                    .init(color: .white.opacity(0.03), location: 0.45),
                    .init(color: .clear, location: 0.62),
                    .init(color: .white.opacity(0.08), location: 1),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Ellipse()
                .fill(Color.white.opacity(0.45))
                .frame(width: size * 0.62, height: size * 0.13)
                .rotationEffect(.degrees(-40))
                .offset(x: -size * 0.2, y: -size * 0.24)
                .blur(radius: size * 0.035)
            Capsule()
                .fill(LinearGradient(colors: Palette.prism, startPoint: .leading, endPoint: .trailing))
                .frame(width: size * 0.62, height: size * 0.06)
                .rotationEffect(.degrees(-40))
                .offset(x: size * 0.24, y: size * 0.24)
                .blur(radius: size * 0.025)
                .opacity(0.4)
        }
        .frame(width: size, height: size)
        .drawingGroup()
    }
}

/// The wheel's polished outer and inner edges. Circles look the same at any
/// rotation, so these never move.
private struct WheelEdges: View {
    let geometry: DialGeometry
    let size: CGFloat

    var body: some View {
        let outer = geometry.wheelOuterRadius * size
        let inner = geometry.wheelInnerRadius * size
        ZStack {
            // Shadow the wheel throws on the plate.
            Circle()
                .stroke(Color.black.opacity(0.55), lineWidth: size * 0.012)
                .frame(width: outer, height: outer)
                .blur(radius: size * 0.008)
                .offset(x: size * 0.004, y: size * 0.007)
            Circle()
                .strokeBorder(
                    LinearGradient(
                        stops: [
                            .init(color: .white.opacity(0.85), location: 0),
                            .init(color: .white.opacity(0.10), location: 0.45),
                            .init(color: .white.opacity(0.45), location: 1),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.2
                )
                .frame(width: outer, height: outer)
            // Holographic fringe along the rim.
            Circle()
                .strokeBorder(
                    AngularGradient(gradient: Gradient(colors: Palette.prismLoop), center: .center, angle: .degrees(30)),
                    lineWidth: size * 0.008
                )
                .frame(width: outer, height: outer)
                .blur(radius: 1.2)
                .opacity(0.4)
                .blendMode(.plusLighter)
            // A concave edge catches the light on its far side.
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.15), .white.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
                .frame(width: inner, height: inner)
        }
    }
}

/// One finger hole's cut edge, lit consistently wherever the hole has turned to.
private struct HoleRim: View {
    let diameter: CGFloat
    let isEngaged: Bool

    var body: some View {
        ZStack {
            // The wheel's thickness shades the plate just inside the near edge.
            Circle()
                .stroke(Color.black.opacity(0.55), lineWidth: diameter * 0.16)
                .blur(radius: diameter * 0.05)
                .offset(x: diameter * 0.05, y: diameter * 0.07)
                .clipShape(Circle())
            // Inner wall, brightest on the far side from the light.
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.06), .white.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: diameter * 0.06
                )
            // Chamfer catching the light on the near lip.
            Circle()
                .strokeBorder(
                    LinearGradient(
                        stops: [
                            .init(color: .white.opacity(0.85), location: 0),
                            .init(color: .white.opacity(0), location: 0.45),
                            .init(color: .white.opacity(0.25), location: 1),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
            // Holographic glow while this hole is being dialled.
            Circle()
                .strokeBorder(
                    AngularGradient(gradient: Gradient(colors: Palette.prismLoop), center: .center),
                    lineWidth: 2
                )
                .blur(radius: 1.5)
                .background { Circle().fill(Color.white.opacity(0.07)) }
                .opacity(isEngaged ? 1 : 0)
                .scaleEffect(isEngaged ? 1 : 0.86)
                .animation(.spring(response: 0.28, dampingFraction: 0.7), value: isEngaged)
        }
        .frame(width: diameter, height: diameter)
    }
}
