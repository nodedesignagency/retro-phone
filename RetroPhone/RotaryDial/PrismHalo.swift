import SwiftUI

/// A soft holographic light leak behind the dial that slowly turns, and
/// brightens while the dial is in use.
struct PrismHalo: View {
    let engine: RotaryDialEngine
    let size: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let active = engine.phase != .idle
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: reduceMotion)) { timeline in
            let turn = timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 60) * 6
            Circle()
                .fill(AngularGradient(gradient: Gradient(colors: Palette.prismLoop), center: .center))
                .frame(width: size * 0.9, height: size * 0.9)
                .padding(size * 0.3)
                .blur(radius: size * 0.14)
                .drawingGroup()
                .rotationEffect(.degrees(turn))
        }
        .scaleEffect(active ? 1.05 : 1)
        .opacity(active ? 0.36 : 0.18)
        .animation(.easeInOut(duration: 0.9), value: active)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
