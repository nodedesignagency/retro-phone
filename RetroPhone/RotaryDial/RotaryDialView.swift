import SwiftUI

/// The complete rotary dial. Put a finger in a hole and pull it round to the
/// stop, or tap a digit to have it dialled for you.
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

    private func dial(size: CGFloat) -> some View {
        let geometry = engine.geometry
        return ZStack {
            DialBase(geometry: geometry, size: size)
            GlassFingerWheel(engine: engine, size: size)
            FingerStop(geometry: geometry, size: size)
            CenterLabel(diameter: geometry.labelRadius * size)
            glints(size: size)
            DigitTargets(engine: engine, size: size)
        }
        .frame(width: size, height: size)
        .background { PrismHalo(engine: engine, size: size) }
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
        let radius = size / 2
        return CGPoint(x: (location.x - radius) / radius, y: (location.y - radius) / radius)
    }

    /// Light catching the wheel's rim and the tip of the stop.
    private func glints(size: CGFloat) -> some View {
        let radius = size / 2
        let rim = DialGeometry.point(angle: -52, radius: engine.geometry.wheelOuterRadius)
        let tip = DialGeometry.point(angle: engine.geometry.fingerStopAngle, radius: 0.66)
        return ZStack {
            Glint(size: size * 0.085, cycle: 6.5)
                .offset(x: rim.x * radius, y: rim.y * radius)
            Glint(size: size * 0.05, cycle: 8.3)
                .offset(x: tip.x * radius, y: tip.y * radius)
        }
    }
}

/// Invisible per-digit buttons over the holes, so VoiceOver can dial.
private struct DigitTargets: View {
    let engine: RotaryDialEngine
    let size: CGFloat

    var body: some View {
        let geometry = engine.geometry
        let radius = size / 2
        ZStack {
            ForEach(DialGeometry.digits.indices, id: \.self) { hole in
                let center = geometry.center(ofHole: hole)
                let digit = geometry.digit(ofHole: hole)
                Color.clear
                    .frame(width: geometry.holeRadius * size, height: geometry.holeRadius * size)
                    .contentShape(Circle())
                    .accessibilityElement()
                    .accessibilityLabel(Text(verbatim: "\(digit)"))
                    .accessibilityAddTraits(.isButton)
                    .accessibilityAction { engine.dial(digit: digit) }
                    .offset(x: center.x * radius, y: center.y * radius)
            }
        }
        .frame(width: size, height: size)
        .allowsHitTesting(false)
    }
}
