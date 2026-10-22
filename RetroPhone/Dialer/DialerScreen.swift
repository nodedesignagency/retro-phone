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
            let dialSize = max(min(proxy.size.width - 32, proxy.size.height - 290, 420), 200)
            VStack(spacing: 0) {
                NumberDisplay(model: model)
                    .padding(.top, 28)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : -12)
                Spacer(minLength: 16)
                RotaryDialView(engine: engine)
                    .frame(width: dialSize, height: dialSize)
                    .scaleEffect(appeared ? 1 : 0.88)
                    .opacity(appeared ? 1 : 0)
                Spacer(minLength: 16)
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

/// Near-black with a faint pool of light where the dial sits.
private struct Backdrop: View {
    var body: some View {
        ZStack {
            Color.black
            RadialGradient(
                colors: [Color(white: 0.11), Color(white: 0.03), .black],
                center: UnitPoint(x: 0.5, y: 0.55),
                startRadius: 0,
                endRadius: 520
            )
        }
        .ignoresSafeArea()
    }
}

#Preview {
    DialerScreen(engine: RotaryDialEngine())
        .preferredColorScheme(.dark)
}
