import SwiftUI

/// The mode dial: a semicircle of hairline ticks with an index at the top,
/// and a ring of digits that turns under it.
struct ModeDialView: View {
    let engine: ModeDialEngine
    /// The dial's width; its height follows from the geometry.
    let width: CGFloat

    @State private var isTracking = false
    @GestureState private var isTouching = false

    var body: some View {
        let geometry = engine.geometry
        let layout = geometry.layout(width: width)
        ZStack(alignment: .topLeading) {
            TickScale(layout: layout)
            IndexWindow(entries: engine.entries)
                .frame(width: layout.windowSize.width, height: layout.windowSize.height)
                .position(x: layout.center.x, y: layout.center.y - layout.itemRadius)
            ItemsLayer(engine: engine, layout: layout)
            DigitTargets(engine: engine, layout: layout)
        }
        .frame(width: layout.width, height: layout.height)
        .contentShape(Rectangle())
        .gesture(drag(geometry: geometry, layout: layout))
        .onChange(of: isTouching) { _, touching in
            // A cancelled gesture never calls onEnded; this catches it.
            if !touching, isTracking {
                isTracking = false
                engine.touchCancelled()
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Dial")
    }

    private func drag(geometry: ModeDialGeometry, layout: ModeDialGeometry.Layout) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($isTouching) { _, state, _ in state = true }
            .onChanged { value in
                let angle = geometry.angle(of: value.location, in: layout)
                if isTracking {
                    // Near the centre the angle swings wildly; hold the ring there.
                    let fromCenter = hypot(value.location.x - layout.center.x, value.location.y - layout.center.y)
                    if fromCenter > layout.itemRadius * 0.3 {
                        engine.touchMoved(angle: angle)
                    }
                } else {
                    isTracking = true
                    let item = geometry.item(at: value.location, offset: engine.offset, in: layout)
                    engine.touchBegan(angle: angle, item: item)
                }
            }
            .onEnded { _ in
                guard isTracking else { return }
                isTracking = false
                engine.touchEnded()
            }
    }
}

/// Hairline ticks over the top half, fading towards the horizon, with the
/// amber index at twelve o'clock.
private struct TickScale: View {
    let layout: ModeDialGeometry.Layout

    var body: some View {
        Canvas { context, _ in
            var angle = -96.0
            while angle <= 96.01 {
                if abs(angle) > 0.01 {
                    let fade = 1 - pow(abs(angle) / 96, 3)
                    var tick = Path()
                    tick.move(to: ModeDialGeometry.point(angle: angle, radius: layout.tickInner, center: layout.center))
                    tick.addLine(to: ModeDialGeometry.point(angle: angle, radius: layout.tickOuter, center: layout.center))
                    context.stroke(
                        tick,
                        with: .color(.white.opacity(0.12 + 0.5 * fade)),
                        style: StrokeStyle(lineWidth: 1.2, lineCap: .round)
                    )
                }
                angle += 4
            }
            var index = Path()
            index.move(to: ModeDialGeometry.point(angle: 0, radius: layout.tickInner - 8, center: layout.center))
            index.addLine(to: ModeDialGeometry.point(angle: 0, radius: layout.tickOuter + 10, center: layout.center))
            context.stroke(index, with: .color(Palette.accent), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        }
        .frame(width: layout.width, height: layout.height)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// The capsule under the index that frames the armed digit, flashing amber
/// each time a digit is entered.
private struct IndexWindow: View {
    let entries: Int

    @State private var flash = false

    var body: some View {
        Capsule()
            .fill(.clear)
            .glass(Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(flash ? Palette.accent : .white.opacity(0.9), lineWidth: 1.5)
            }
            .shadow(color: Palette.accent.opacity(flash ? 0.6 : 0), radius: 10)
            .scaleEffect(flash ? 1.06 : 1)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .onChange(of: entries) { _, _ in
                withAnimation(.easeOut(duration: 0.1)) { flash = true }
                Task {
                    try? await Task.sleep(for: .milliseconds(220))
                    withAnimation(.easeInOut(duration: 0.4)) { flash = false }
                }
            }
    }
}

/// The digits on the ring: plain near the ends, on white discs near the
/// index, and bare again inside the window.
private struct ItemsLayer: View {
    let engine: ModeDialEngine
    let layout: ModeDialGeometry.Layout

    var body: some View {
        let geometry = engine.geometry
        let offset = engine.offset
        let pressed = engine.pressedItem
        Canvas { context, _ in
            for item in geometry.digits.indices {
                let angle = geometry.screenAngle(ofItem: item, offset: offset)
                let visibility = geometry.visibility(atAngle: angle)
                guard visibility > 0.001 else { continue }
                let disc = geometry.discWeight(atAngle: angle)
                let window = geometry.windowWeight(atAngle: angle)
                let position = ModeDialGeometry.point(angle: angle, radius: layout.itemRadius, center: layout.center)

                context.drawLayer { layer in
                    layer.translateBy(x: position.x, y: position.y)
                    layer.rotate(by: .degrees(angle))
                    layer.opacity = visibility
                    if pressed == item {
                        layer.scaleBy(x: 1.1, y: 1.1)
                    }
                    if disc > 0.001 {
                        let radius = layout.itemDiscRadius * (0.85 + 0.15 * disc)
                        let circle = Path(ellipseIn: CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2))
                        layer.fill(circle, with: .color(.white.opacity(disc)))
                    }
                    let size = 19 + 3 * window - 2 * disc
                    let ink = Color(white: 1 - disc)
                    let text = Text(verbatim: "\(geometry.digit(ofItem: item))")
                        .font(.system(size: size, weight: .medium))
                        .foregroundStyle(ink)
                    layer.draw(text, at: .zero, anchor: .center)
                }
            }
        }
        .frame(width: layout.width, height: layout.height)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Invisible per-digit buttons, so VoiceOver can dial.
private struct DigitTargets: View {
    let engine: ModeDialEngine
    let layout: ModeDialGeometry.Layout

    var body: some View {
        let geometry = engine.geometry
        ZStack(alignment: .topLeading) {
            ForEach(geometry.digits.indices, id: \.self) { item in
                let angle = geometry.screenAngle(ofItem: item, offset: engine.offset)
                if geometry.visibility(atAngle: angle) > 0.3 {
                    let digit = geometry.digit(ofItem: item)
                    Color.clear
                        .frame(width: 44, height: 44)
                        .contentShape(Circle())
                        .accessibilityElement()
                        .accessibilityLabel(Text(verbatim: "\(digit)"))
                        .accessibilityAddTraits(.isButton)
                        .accessibilityAction { engine.dial(digit: digit) }
                        .position(geometry.position(ofItem: item, offset: engine.offset, in: layout))
                }
            }
        }
        .frame(width: layout.width, height: layout.height)
        .allowsHitTesting(false)
    }
}
