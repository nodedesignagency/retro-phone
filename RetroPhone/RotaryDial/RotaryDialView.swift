import SwiftUI

/// The rotary dial. Put a finger in a hole and pull it round to the stop, or
/// tap a digit to have it dialled for you.
///
/// Built from four aligned photographic layers: the number plate, the chrome
/// finger wheel (the only layer that turns), the finger stop and the centre cap.
struct RotaryDialView: View {
    let engine: RotaryDialEngine

    @State private var isTracking = false
    @GestureState private var isTouching = false

    var body: some View {
        GeometryReader { proxy in
            dial(size: min(proxy.size.width, proxy.size.height))
                .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    /// `size` is the side of the artwork; the wheel's rim sits a little inside it.
    private func dial(size: CGFloat) -> some View {
        ZStack {
            Image("DialPlate")
                .resizable()
                .interpolation(.high)
                .shadow(color: .black.opacity(0.85), radius: size * 0.05, y: size * 0.04)
            HoleShading(engine: engine, size: size)
            TurningWheel(engine: engine)
            Image("DialStop")
                .resizable()
                .interpolation(.high)
            Image("DialCenter")
                .resizable()
                .interpolation(.high)
            DigitTargets(engine: engine, size: size)
        }
        .frame(width: size, height: size)
        .background { DialGlow(engine: engine, size: size) }
        .contentShape(Circle())
        .gesture(drag(size: size))
        .onChange(of: isTouching) { _, touching in
            // A cancelled gesture never calls onEnded; this catches it.
            if !touching { endTouch() }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Rotary dial")
    }

    private func drag(size: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($isTouching) { _, state, _ in state = true }
            .onChanged { value in
                let point = unitPoint(value.location, size: size)
                if isTracking {
                    engine.touchMoved(to: point)
                } else {
                    isTracking = true
                    engine.touchBegan(at: point)
                }
            }
            .onEnded { _ in endTouch() }
    }

    private func endTouch() {
        guard isTracking else { return }
        isTracking = false
        engine.touchEnded()
    }

    private func unitPoint(_ location: CGPoint, size: CGFloat) -> CGPoint {
        let unit = size / 2 / engine.geometry.artworkHalfSize
        return CGPoint(x: (location.x - size / 2) / unit, y: (location.y - size / 2) / unit)
    }
}

/// The finger wheel: the only layer that reads the rotation, so it's the only
/// one redrawn each frame.
private struct TurningWheel: View {
    let engine: RotaryDialEngine

    var body: some View {
        Image("DialWheel")
            .resizable()
            .interpolation(.high)
            .rotationEffect(.degrees(engine.rotation))
    }
}

/// Shade inside each hole, drawn on the plate under the wheel so it only shows
/// through the openings. Holes move but the light doesn't, so each shade is
/// translated with its hole rather than rotated.
private struct HoleShading: View {
    let engine: RotaryDialEngine
    let size: CGFloat

    var body: some View {
        let geometry = engine.geometry
        let rotation = engine.rotation
        let engaged = engine.engagedHole
        let unit = size / 2 / geometry.artworkHalfSize
        let diameter = geometry.holeRadius * 2 * unit

        ZStack {
            ForEach(geometry.holeIndices, id: \.self) { hole in
                let center = geometry.center(ofHole: hole, rotation: rotation)
                HoleShade(diameter: diameter, isEngaged: engaged == hole)
                    .offset(x: center.x * unit, y: center.y * unit)
            }
        }
        .frame(width: size, height: size)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct HoleShade: View {
    let diameter: CGFloat
    let isEngaged: Bool

    var body: some View {
        ZStack {
            // The wheel's lip shadows the plate under the top of the opening.
            Circle()
                .stroke(Color.black.opacity(0.55), lineWidth: diameter * 0.28)
                .frame(width: diameter * 1.25, height: diameter * 1.25)
                .offset(y: diameter * 0.09)
                .blur(radius: diameter * 0.06)
            // A little light in the hole being dialled.
            Circle()
                .fill(RadialGradient(
                    colors: [.white.opacity(0.22), .white.opacity(0)],
                    center: .center,
                    startRadius: 0,
                    endRadius: diameter * 0.5
                ))
                .opacity(isEngaged ? 1 : 0)
                .animation(.easeOut(duration: 0.2), value: isEngaged)
        }
        .frame(width: diameter, height: diameter)
        .clipShape(Circle())
    }
}

/// Soft light spilling round the dial, brightening while it's in use.
private struct DialGlow: View {
    let engine: RotaryDialEngine
    let size: CGFloat

    var body: some View {
        let active = engine.phase != .idle
        Circle()
            .fill(RadialGradient(
                colors: [.white.opacity(0.16), .white.opacity(0)],
                center: .center,
                startRadius: size * 0.36,
                endRadius: size * 0.66
            ))
            .frame(width: size * 1.4, height: size * 1.4)
            .opacity(active ? 1 : 0.6)
            .animation(.easeInOut(duration: 0.6), value: active)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

/// Invisible per-digit buttons over the holes, so VoiceOver can dial.
private struct DigitTargets: View {
    let engine: RotaryDialEngine
    let size: CGFloat

    var body: some View {
        let geometry = engine.geometry
        let unit = size / 2 / geometry.artworkHalfSize
        let diameter = geometry.holeRadius * 2 * unit
        ZStack {
            ForEach(geometry.holeIndices, id: \.self) { hole in
                let center = geometry.center(ofHole: hole)
                let digit = geometry.digit(ofHole: hole)
                Color.clear
                    .frame(width: diameter, height: diameter)
                    .contentShape(Circle())
                    .accessibilityElement()
                    .accessibilityLabel(Text(verbatim: "\(digit)"))
                    .accessibilityAddTraits(.isButton)
                    .accessibilityAction { engine.dial(digit: digit) }
                    .offset(x: center.x * unit, y: center.y * unit)
            }
        }
        .frame(width: size, height: size)
        .allowsHitTesting(false)
    }
}
