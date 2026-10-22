import SwiftUI

struct DialerScreen: View {
    let engine: ModeDialEngine

    @State private var model = DialerModel()
    @State private var appeared = false
    @State private var deletions = 0
    @State private var refusals = 0
    @State private var calls = 0

    @Environment(\.openURL) private var openURL
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            let dialWidth = min(proxy.size.width - 24, 400)
            VStack(spacing: 0) {
                NumberBoxes(model: model)
                    .padding(.top, 36)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : -8)

                Text("Spin the dial, or tap a digit")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.4))
                    .padding(.top, 16)
                    .opacity(model.isEmpty && appeared ? 1 : 0)
                    .animation(.easeInOut(duration: 0.3), value: model.isEmpty)
                    .accessibilityHidden(!model.isEmpty)

                Spacer(minLength: 12)

                ModeDialView(engine: engine, width: dialWidth)
                    .opacity(appeared ? 1 : 0)
                    .scaleEffect(appeared ? 1 : 0.96)

                Spacer(minLength: 12)

                DialerControls(
                    hasDigits: !model.isEmpty,
                    refusals: refusals,
                    onCall: call,
                    onDelete: deleteLast,
                    onClear: clearAll
                )
                .padding(.bottom, 14)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .background { Backdrop() }
        .sensoryFeedback(.impact(weight: .light, intensity: 0.6), trigger: deletions)
        .sensoryFeedback(.impact(weight: .medium), trigger: calls)
        .sensoryFeedback(.error, trigger: refusals)
        .onAppear {
            engine.reduceMotion = reduceMotion
            engine.onEnter = { [model] digit in
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { model.append(digit) }
            }
            withAnimation(.spring(duration: 0.8, bounce: 0.15)) { appeared = true }
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

/// Black, with the faintest pool of light where the dial sits.
private struct Backdrop: View {
    var body: some View {
        ZStack {
            Color.black
            RadialGradient(
                colors: [.white.opacity(0.07), .white.opacity(0)],
                center: UnitPoint(x: 0.5, y: 0.62),
                startRadius: 0,
                endRadius: 360
            )
        }
        .ignoresSafeArea()
    }
}

#Preview {
    DialerScreen(engine: ModeDialEngine())
        .preferredColorScheme(.dark)
}
