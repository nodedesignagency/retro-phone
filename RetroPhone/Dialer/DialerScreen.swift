import SwiftUI

struct DialerScreen: View {
    let engine: RotaryDialEngine

    @State private var model = DialerModel()
    @State private var appeared = false
    @State private var deletions = 0
    @State private var refusals = 0
    @State private var calls = 0

    @Environment(\.openURL) private var openURL
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            // The artwork has a transparent margin round the wheel, so it may run
            // a touch wider than the screen.
            let dialSize = max(min(proxy.size.width + 10, proxy.size.height - 250, 450), 220)
            VStack(spacing: 0) {
                NumberDisplay(model: model)
                    .padding(.top, 44)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : -8)
                Spacer(minLength: 8)
                RotaryDialView(engine: engine)
                    .frame(width: dialSize, height: dialSize)
                    .scaleEffect(appeared ? 1 : 0.94)
                    .opacity(appeared ? 1 : 0)
                Spacer(minLength: 8)
                DialerControls(
                    hasDigits: !model.isEmpty,
                    refusals: refusals,
                    onCall: call,
                    onDelete: deleteLast,
                    onClear: clearAll
                )
                .padding(.bottom, 16)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 16)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .background { Backdrop() }
        .sensoryFeedback(.impact(weight: .light, intensity: 0.6), trigger: deletions)
        .sensoryFeedback(.impact(weight: .medium), trigger: calls)
        .sensoryFeedback(.error, trigger: refusals)
        .onAppear {
            engine.reduceMotion = reduceMotion
            engine.onDial = { [model] digit in
                withAnimation(.snappy(duration: 0.3)) { model.append(digit) }
            }
            withAnimation(.spring(duration: 0.9, bounce: 0.22)) { appeared = true }
        }
        .onChange(of: reduceMotion) { _, newValue in
            engine.reduceMotion = newValue
        }
    }

    private func call() {
        guard let url = model.callURL else {
            if model.lastDialed != nil {
                withAnimation(.snappy) { _ = model.recallLastDialed() }
            } else {
                refuse()
            }
            return
        }
        calls += 1
        openURL(url) { accepted in
            if accepted {
                model.noteCallPlaced()
            } else {
                refuse()
            }
        }
    }

    private func refuse() {
        withAnimation(.linear(duration: 0.4)) { refusals += 1 }
    }

    private func deleteLast() {
        guard !model.isEmpty else { return }
        withAnimation(.snappy(duration: 0.25)) { model.deleteLast() }
        deletions += 1
    }

    private func clearAll() {
        guard !model.isEmpty else { return }
        withAnimation(.smooth(duration: 0.35)) { model.clear() }
        deletions += 1
    }
}

/// Black, with a soft studio light falling from above onto the dial.
private struct Backdrop: View {
    var body: some View {
        ZStack {
            Color.black
            RadialGradient(
                stops: [
                    .init(color: .white.opacity(0.19), location: 0),
                    .init(color: .white.opacity(0.075), location: 0.4),
                    .init(color: .white.opacity(0), location: 1),
                ],
                center: UnitPoint(x: 0.5, y: 0.22),
                startRadius: 0,
                endRadius: 460
            )
        }
        .ignoresSafeArea()
    }
}

#Preview {
    DialerScreen(engine: RotaryDialEngine())
        .preferredColorScheme(.dark)
}
