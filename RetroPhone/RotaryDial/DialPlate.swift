import SwiftUI

/// Everything under the finger wheel that never moves: shadow, plate, bezel.
struct DialBase: View {
    let geometry: DialGeometry
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.black)
                .shadow(color: .black, radius: size * 0.07, x: 0, y: size * 0.05)
            DialPlate(geometry: geometry, size: size)
            Bezel(size: size)
        }
        .frame(width: size, height: size)
        .allowsHitTesting(false)
    }
}

/// The machined gunmetal plate, with the digits printed on silver wells that
/// show through the finger holes at rest.
struct DialPlate: View {
    let geometry: DialGeometry
    let size: CGFloat

    var body: some View {
        let radius = size / 2
        ZStack {
            Circle().fill(Finish.gunmetal)
            LatheGrain(seed: 7)
            Circle()
                .fill(RadialGradient(
                    colors: [.clear, .black.opacity(0.5)],
                    center: .center,
                    startRadius: radius * 0.55,
                    endRadius: radius
                ))
            ForEach(DialGeometry.digits.indices, id: \.self) { hole in
                let center = geometry.center(ofHole: hole)
                NumberWell(digit: geometry.digit(ofHole: hole), diameter: geometry.wellRadius * size)
                    .offset(x: center.x * radius, y: center.y * radius)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .drawingGroup()
        .accessibilityHidden(true)
    }
}

private struct NumberWell: View {
    let digit: Int
    let diameter: CGFloat

    var body: some View {
        ZStack {
            Circle().fill(Finish.silver)
            LatheGrain(seed: UInt64(digit + 11), intensity: 0.8)
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [.black.opacity(0.45), .white.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: max(diameter * 0.03, 1)
                )
            Text(verbatim: "\(digit)")
                .font(.custom("GillSans-SemiBold", size: diameter * 0.62))
                .foregroundStyle(Palette.ink)
                .offset(y: diameter * 0.02)
        }
        .frame(width: diameter, height: diameter)
        .clipShape(Circle())
    }
}

private struct Bezel: View {
    let size: CGFloat

    var body: some View {
        let width = size * 0.018
        ZStack {
            Circle().strokeBorder(Finish.chrome, lineWidth: width)
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.8), .white.opacity(0.05), .white.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.75
                )
            Circle()
                .strokeBorder(Color.black.opacity(0.7), lineWidth: 1)
                .padding(width)
        }
    }
}
