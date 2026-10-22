import SwiftUI
import UIKit

/// The dialled number, with copy and paste on long press.
struct NumberDisplay: View {
    let model: DialerModel

    var body: some View {
        ZStack {
            Text("Pull a number round to the stop")
                .font(.system(size: 15))
                .foregroundStyle(Palette.secondary)
                .opacity(model.isEmpty ? 1 : 0)
                .accessibilityHidden(!model.isEmpty)

            Text(verbatim: model.formatted)
                .font(.system(size: 42, weight: .light))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.45)
                .contentTransition(.numericText())
                .padding(.horizontal, 24)
                .accessibilityLabel("Number")
                .accessibilityValue(model.formatted)
                .accessibilityHidden(model.isEmpty)
        }
        .frame(maxWidth: .infinity, minHeight: 56)
        .contentShape(Rectangle())
        .contextMenu { menu }
        .animation(.easeInOut(duration: 0.3), value: model.isEmpty)
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
