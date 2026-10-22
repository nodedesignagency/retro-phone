import SwiftUI
import UIKit

/// The number as three glass boxes, 000 000 0000, filling left to right.
struct NumberBoxes: View {
    let model: DialerModel

    private let groups = [3, 3, 4]

    var body: some View {
        let digits = Array(model.digits)
        HStack(spacing: 10) {
            ForEach(groups.indices, id: \.self) { group in
                let start = groups[..<group].reduce(0, +)
                let count = groups[group]
                let isActive = digits.count >= start && digits.count < start + count
                HStack(spacing: 0) {
                    ForEach(0..<count, id: \.self) { slot in
                        let index = start + slot
                        if index < digits.count {
                            Text(verbatim: String(digits[index]))
                                .tracking(1.5)
                                .foregroundStyle(.white)
                                .transition(.scale(scale: 0.5).combined(with: .opacity))
                                .id("\(index)-\(digits[index])")
                        } else {
                            Text(verbatim: "0")
                                .tracking(1.5)
                                .foregroundStyle(.white.opacity(0.18))
                        }
                    }
                }
                .font(.system(size: 30, weight: .medium, design: .rounded).monospacedDigit())
                .frame(width: count == 4 ? 126 : 98, height: 60)
                .glass(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Palette.accent, lineWidth: 1.5)
                        .opacity(isActive ? 1 : 0)
                }
                .animation(.easeInOut(duration: 0.25), value: isActive)
            }
        }
        .contentShape(Rectangle())
        .contextMenu { menu }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Number")
        .accessibilityValue(model.isEmpty ? "Empty" : model.formatted)
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
                withAnimation(.snappy) { model.paste(text) }
            }
        }
    }
}
