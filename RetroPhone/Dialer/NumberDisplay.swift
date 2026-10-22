import SwiftUI
import UIKit

/// The dialled number in polished-metal type, with copy and paste on long press.
struct NumberDisplay: View {
    let model: DialerModel

    var body: some View {
        VStack(spacing: 14) {
            Text(verbatim: model.isEmpty ? " " : model.formatted)
                .font(.system(size: 46, weight: .light).monospacedDigit())
                .foregroundStyle(Palette.chromeText)
                .lineLimit(1)
                .minimumScaleFactor(0.4)
                .contentTransition(.numericText())
                .frame(maxWidth: .infinity, minHeight: 58)
                .padding(.horizontal, 24)
                .contentShape(Rectangle())
                .contextMenu { menu }
                .accessibilityLabel("Number")
                .accessibilityValue(model.isEmpty ? "Empty" : model.formatted)

            Text("DIAL TO THE STOP  ·  OR TAP A DIGIT")
                .font(.custom("GillSans-SemiBold", size: 11))
                .tracking(2.4)
                .foregroundStyle(.white.opacity(0.34))
                .opacity(model.isEmpty ? 1 : 0)
                .animation(.easeInOut(duration: 0.4), value: model.isEmpty)
                .accessibilityHidden(!model.isEmpty)
        }
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
