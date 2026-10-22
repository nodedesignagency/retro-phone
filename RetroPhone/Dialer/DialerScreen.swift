import SwiftUI

/// The whole screen is the device face: a grid of square tiles holding a
/// speaker grille, the mono screen, the orange call button, and the keys.
struct DialerScreen: View {
    @State private var model = DialerModel()
    @State private var message: String?
    @State private var messageID = 0
    @State private var errors = 0

    @Environment(\.openURL) private var openURL

    private let gap: CGFloat = 3
    private let keyRows: [[Character]] = [["1", "2", "3", "4"], ["5", "6", "7", "8"], ["9", "0", "*", "#"]]

    var body: some View {
        GeometryReader { proxy in
            let side = min(floor((proxy.size.width - 24 - gap * 3) / 4), 96)
            VStack(alignment: .leading, spacing: 0) {
                Spacer(minLength: 8)
                grid(side: side)
                Spacer(minLength: 12)
                Wordmark()
                    .padding(.leading, 12)
                Spacer(minLength: 8)
            }
            .frame(width: proxy.size.width)
        }
        .background(Palette.body.ignoresSafeArea())
        .sensoryFeedback(.error, trigger: errors)
    }

    private var status: String {
        message ?? (model.isEmpty ? "READY" : "DIAL")
    }

    // MARK: - Layout

    private func grid(side: CGFloat) -> some View {
        let keySize = side * 62 / 90
        return VStack(spacing: gap) {
            HStack(spacing: gap) {
                Tile { Grille() }
                    .frame(width: side, height: side * 2 + gap)
                ScreenTile(model: model, status: status)
                    .frame(width: side * 3 + gap * 2, height: side * 2 + gap)
            }

            HStack(spacing: gap) {
                Tile {
                    ZStack(alignment: .bottom) {
                        Button(action: call) { EmptyView() }
                            .buttonStyle(OrangeKeyStyle(diameter: side * 58 / 90))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .offset(y: -4)
                            .accessibilityLabel("Call")
                        MicroLabel("CALL")
                            .padding(.bottom, 6)
                    }
                }
                .frame(width: side, height: side)

                Tile {
                    Button("DELETE", action: deleteLast)
                        .buttonStyle(PillKeyStyle())
                        .simultaneousGesture(LongPressGesture(minimumDuration: 0.5).onEnded { _ in clearAll() })
                        .padding(.horizontal, 8)
                        .accessibilityHint("Touch and hold to clear the number")
                }
                .frame(width: side, height: side)

                Tile {
                    Button("CLEAR", action: clearAll)
                        .buttonStyle(PillKeyStyle())
                        .padding(.horizontal, 8)
                }
                .frame(width: side, height: side)

                Tile {
                    Button { press("+") } label: { KeyLabel(key: "+") }
                        .buttonStyle(RoundKeyStyle(diameter: keySize, showsLED: false))
                        .accessibilityLabel("Plus")
                }
                .frame(width: side, height: side)
            }

            ForEach(keyRows.indices, id: \.self) { row in
                HStack(spacing: gap) {
                    ForEach(keyRows[row], id: \.self) { key in
                        Tile {
                            ZStack(alignment: .leading) {
                                Button { press(key) } label: { KeyLabel(key: key) }
                                    .buttonStyle(RoundKeyStyle(diameter: keySize))
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .accessibilityLabel(Self.spokenName(of: key))
                                if row == 0, key == "1" {
                                    SideLabel(text: "KEYS")
                                        .frame(width: 12)
                                        .padding(.leading, 2)
                                }
                            }
                        }
                        .frame(width: side, height: side)
                    }
                }
            }

            HStack(spacing: gap) {
                ForEach(0..<DialerModel.speedDialCount, id: \.self) { slot in
                    Tile(color: Palette.gradientTiles[slot]) {
                        ZStack(alignment: .bottom) {
                            Button { recallSpeedDial(slot) } label: { EmptyView() }
                                .buttonStyle(KnobStyle(
                                    tone: Palette.gradientKnobs[slot],
                                    index: slot,
                                    isStored: model.speedDials[slot] != nil,
                                    diameter: side * 58 / 90
                                ))
                                .simultaneousGesture(LongPressGesture(minimumDuration: 0.6).onEnded { _ in saveSpeedDial(slot) })
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .offset(y: -3)
                                .accessibilityLabel("Speed dial \(slot + 1)")
                                .accessibilityHint("Touch and hold to save the current number here")
                            MicroLabel("S\(slot + 1)", color: slot > 1 ? Color(hex: 0x555555) : Color(hex: 0x6A6A6A))
                                .padding(.bottom, 5)
                        }
                    }
                    .frame(width: side, height: side)
                }
            }
        }
    }

    // MARK: - Actions

    private func press(_ key: Character) {
        model.append(key)
    }

    private func deleteLast() {
        model.deleteLast()
    }

    private func clearAll() {
        guard !model.isEmpty else { return }
        model.clear()
        show("CLEARED")
    }

    private func call() {
        guard let url = model.callURL else {
            if model.recallLastDialed() {
                show("LAST NUMBER")
            } else {
                show("NO NUMBER")
                errors += 1
            }
            return
        }
        show("CALLING")
        openURL(url) { accepted in
            if accepted {
                model.noteCallPlaced()
            } else {
                show("NO SERVICE")
                errors += 1
            }
        }
    }

    private func recallSpeedDial(_ slot: Int) {
        if model.recallSpeedDial(slot) {
            show("S\(slot + 1)")
        } else if model.speedDials[slot] == nil {
            show("S\(slot + 1) EMPTY")
        }
    }

    private func saveSpeedDial(_ slot: Int) {
        if model.saveSpeedDial(slot) {
            show("SAVED S\(slot + 1)")
        } else {
            show("NO NUMBER")
            errors += 1
        }
    }

    /// Shows a short message on the screen's status line, then reverts.
    private func show(_ text: String) {
        messageID += 1
        let id = messageID
        message = text
        Task {
            try? await Task.sleep(for: .milliseconds(1600))
            if messageID == id { message = nil }
        }
    }

    private static func spokenName(of key: Character) -> String {
        switch key {
        case "*": "Star"
        case "#": "Pound"
        default: String(key)
        }
    }
}

/// A key cap's legend.
private struct KeyLabel: View {
    let key: Character

    var body: some View {
        Group {
            if key == "*" {
                Image(systemName: "asterisk")
                    .font(.system(size: 17, weight: .medium))
            } else {
                Text(String(key))
                    .font(.system(size: key == "+" ? 23 : 21, weight: .light))
            }
        }
        .foregroundStyle(Palette.ink)
    }
}

/// The tiny caps labels printed on tiles.
private struct MicroLabel: View {
    let text: String
    var color: Color = Palette.microLabel

    init(_ text: String, color: Color = Palette.microLabel) {
        self.text = text
        self.color = color
    }

    var body: some View {
        Text(text)
            .font(.system(size: 7, weight: .semibold))
            .tracking(1.4)
            .foregroundStyle(color)
            .accessibilityHidden(true)
    }
}

/// The two-line lowercase wordmark under the device.
private struct Wordmark: View {
    var body: some View {
        VStack(alignment: .leading, spacing: -3) {
            Text("retro")
            Text("phone")
        }
        .font(.system(size: 15, weight: .bold))
        .tracking(-0.4)
        .foregroundStyle(Palette.ink)
        .accessibilityHidden(true)
    }
}

#Preview {
    DialerScreen()
        .preferredColorScheme(.dark)
}
