import SwiftUI
import UIKit

/// The black mono screen: a status line with a blinking cursor, the number in
/// 000 000 0000 slots, and a footer readout.
struct ScreenTile: View {
    let model: DialerModel
    let status: String

    private static let template = Array("000 000 0000")
    private static let slots = [0, 1, 2, 4, 5, 6, 8, 9, 10, 11]

    var body: some View {
        RoundedRectangle(cornerRadius: 7, style: .continuous)
            .fill(Color.black)
            .overlay(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("RETRO PHONE v2.0")
                    HStack(spacing: 1) {
                        Text(status)
                        Cursor(height: 13, width: 2)
                    }
                    Spacer(minLength: 8)
                    number
                    Spacer(minLength: 8)
                    Text("US +1  ·  \(String(format: "%02d", model.digits.count))/10")
                        .foregroundStyle(Palette.screenMuted)
                }
                .font(.system(size: 11.5, weight: .medium, design: .monospaced))
                .tracking(0.3)
                .foregroundStyle(Palette.screenText)
                .padding(14)
            }
            .contentShape(Rectangle())
            .contextMenu { menu }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Number")
            .accessibilityValue(model.isEmpty ? "Empty" : model.formatted)
    }

    @ViewBuilder
    private var number: some View {
        let digits = Array(model.digits)
        HStack(spacing: 0) {
            if model.isPlainDigits, digits.count <= 10 {
                let cut = digits.isEmpty ? 0 : Self.slots[digits.count - 1] + 1
                Text(String(filled(digits).prefix(cut)))
                    .foregroundStyle(Palette.screenText)
                Cursor(height: 24, width: 2.5)
                Text(String(Self.template.dropFirst(cut)))
                    .foregroundStyle(Palette.screenDim)
            } else {
                Text(model.digits)
                    .foregroundStyle(Palette.screenText)
                Cursor(height: 24, width: 2.5)
            }
        }
        .font(.system(size: 25, weight: .regular, design: .monospaced))
        .tracking(0.5)
        .lineLimit(1)
        .minimumScaleFactor(0.5)
        .contentTransition(.numericText())
    }

    private func filled(_ digits: [Character]) -> [Character] {
        var result = Self.template
        for (index, digit) in digits.enumerated() {
            result[Self.slots[index]] = digit
        }
        return result
    }

    @ViewBuilder
    private var menu: some View {
        if !model.isEmpty {
            Button("Copy", systemImage: "doc.on.doc") {
                UIPasteboard.general.string = model.formatted
            }
        }
        if UIPasteboard.general.hasStrings {
            Button("Paste", systemImage: "doc.on.clipboard") {
                guard let text = UIPasteboard.general.string else { return }
                model.paste(text)
            }
        }
    }
}

/// The red block cursor, blinking like a terminal's.
private struct Cursor: View {
    let height: CGFloat
    let width: CGFloat

    @State private var visible = true

    var body: some View {
        Rectangle()
            .fill(Palette.cursor)
            .frame(width: width, height: height)
            .opacity(visible ? 1 : 0)
            .task {
                while !Task.isCancelled {
                    try? await Task.sleep(for: .milliseconds(530))
                    visible.toggle()
                }
            }
    }
}
